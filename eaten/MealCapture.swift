//
//  MealCapture.swift
//  eaten
//
//  Shared capture flow: pick a source (camera or library), get the image, resolve
//  its location, and hand both back. Used by the feed's glass selector and the
//  detail screen's "edit photo".
//

import SwiftUI
import PhotosUI

enum CaptureSource: Int, Identifiable {
    case camera, library
    var id: Int { rawValue }
}

extension View {
    /// Presents the right picker for `source`, then calls `onCapture` with the
    /// image, its resolved place, and its date (EXIF capture time for library
    /// photos, now for camera). Background removal happens later, in the store.
    func mealCapture(
        source: Binding<CaptureSource?>,
        onCapture: @escaping (UIImage, PlaceInfo, Date) -> Void
    ) -> some View {
        modifier(MealCaptureModifier(source: source, onCapture: onCapture))
    }
}

private struct MealCaptureModifier: ViewModifier {
    @Binding var source: CaptureSource?
    let onCapture: (UIImage, PlaceInfo, Date) -> Void

    @State private var pickerItem: PhotosPickerItem?
    private let location = LocationProvider()

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: cameraBinding) {
                CameraPicker { image in
                    Task {
                        let place = await location.currentPlace()
                        onCapture(image, place, .now)
                    }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: libraryBinding, selection: $pickerItem, matching: .images)
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    let place = await LocationProvider.place(fromImageData: data)
                    let date = LocationProvider.captureDate(fromImageData: data) ?? .now
                    pickerItem = nil
                    onCapture(image, place, date)
                }
            }
    }

    private var cameraBinding: Binding<Bool> {
        Binding(get: { source == .camera }, set: { if !$0 { source = nil } })
    }
    private var libraryBinding: Binding<Bool> {
        Binding(get: { source == .library }, set: { if !$0 { source = nil } })
    }
}
