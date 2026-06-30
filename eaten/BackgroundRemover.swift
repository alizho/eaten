//
//  BackgroundRemover.swift
//  eaten
//
//  Apple's on-device foreground extraction (Vision). Lifts the food subject out
//  of the photo so it floats on the cream feed.
//
//  NOTE: VNGenerateForegroundInstanceMaskRequest requires the Neural Engine and
//  does NOT run on the iOS Simulator — there it throws and we return nil, so the
//  caller keeps the original photo. Real cutouts happen on device.
//

import UIKit
import Vision
import CoreImage

enum BackgroundRemover {

    /// Returns a transparent-background cutout of the salient subject, or nil if
    /// no subject is found / the request is unsupported (e.g. Simulator).
    static func cutout(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgOrientation)

        do {
            try handler.perform([request])
            guard let result = request.results?.first,
                  !result.allInstances.isEmpty
            else { return nil }

            let masked = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            return makeUIImage(from: masked, scale: image.scale)
        } catch {
            // Simulator / unsupported hardware / no subject — fall back to original.
            print("eaten: background removal unavailable — \(error.localizedDescription)")
            return nil
        }
    }

    private static let ciContext = CIContext()

    private static func makeUIImage(from pixelBuffer: CVPixelBuffer, scale: CGFloat) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cg = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }
}

private extension UIImage {
    /// Map UIImage orientation to the CGImagePropertyOrientation Vision expects.
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
