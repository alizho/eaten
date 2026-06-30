//
//  LocationProvider.swift
//  eaten
//
//  Resolves a short place name for a meal — from the live location when you take
//  a photo, or from a picked photo's embedded GPS (EXIF) when you choose one.
//

import Foundation
import CoreLocation
import ImageIO

struct PlaceInfo {
    var name: String?
    var coordinate: CLLocationCoordinate2D?
}

final class LocationProvider: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var fixContinuation: CheckedContinuation<CLLocation?, Never>?

    // MARK: - Live location (in-app camera)

    /// Best-effort current place. Returns empty info if permission is denied or
    /// no fix arrives — capture never blocks on location.
    func currentPlace() async -> PlaceInfo {
        manager.delegate = self
        let status = await ensureAuthorized()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return PlaceInfo()
        }
        guard let location = await requestFix() else { return PlaceInfo() }
        let name = await Self.reverseGeocode(location)
        return PlaceInfo(name: name, coordinate: location.coordinate)
    }

    private func ensureAuthorized() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestFix() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            fixContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authContinuation?.resume(returning: manager.authorizationStatus)
        authContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        fixContinuation?.resume(returning: locations.last)
        fixContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fixContinuation?.resume(returning: nil)
        fixContinuation = nil
    }

    // MARK: - Photo EXIF (library pick)

    /// Pulls a place from a picked photo's embedded GPS, if present.
    static func place(fromImageData data: Data) async -> PlaceInfo {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double
        else { return PlaceInfo() }

        let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        let coordinate = CLLocationCoordinate2D(
            latitude: latRef == "S" ? -lat : lat,
            longitude: lonRef == "W" ? -lon : lon
        )
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let name = await reverseGeocode(location)
        return PlaceInfo(name: name, coordinate: coordinate)
    }

    /// The date a picked photo was actually taken, from EXIF (falls back to nil).
    static func captureDate(fromImageData data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        guard let raw = (exif?[kCGImagePropertyExifDateTimeOriginal] as? String)
                ?? (tiff?[kCGImagePropertyTIFFDateTime] as? String)
        else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy:MM:dd HH:mm:ss"   // EXIF's fixed format
        fmt.timeZone = .current
        return fmt.date(from: raw)
    }

    // MARK: - Geocoding

    private static func reverseGeocode(_ location: CLLocation) async -> String? {
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        else { return nil }
        // e.g. "Fort Mason, San Francisco, CA"
        let parts = [
            placemark.areasOfInterest?.first ?? placemark.subLocality ?? placemark.name,
            placemark.locality,
            placemark.administrativeArea
        ]
        var seen = Set<String>()
        let unique = parts
            .compactMap { $0 }
            .filter { seen.insert($0).inserted }
        return unique.isEmpty ? nil : unique.joined(separator: ", ")
    }
}
