import AVFoundation
import SwiftUI
import UIKit

@MainActor
enum ScreenshotExportService {
    static func export<V: View>(
        view: V,
        format: ExportFormat,
        fileName: String,
        scale: CGFloat = UIScreen.main.scale
    ) throws -> URL {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw ExportError.renderFailed
        }

        let safeFileName = fileName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFileName)_\(format.rawValue).png")
        try data.write(to: url, options: [.atomic])
        return url
    }
}

enum ExportError: LocalizedError {
    case renderFailed
    case videoExportUnavailable
    case videoWriterFailed
    case pixelBufferFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Could not render the chat preview."
        case .videoExportUnavailable:
            return "Video export is not implemented yet."
        case .videoWriterFailed:
            return "Could not create the video export."
        case .pixelBufferFailed:
            return "Could not prepare video frames."
        }
    }
}

@MainActor
final class VideoExportService {
    func exportVideo(
        frames: [UIImage],
        format: ExportFormat,
        fileName: String,
        secondsPerFrame: Double = 0.85,
        framesPerSecond: Int32 = 30
    ) async throws -> URL {
        guard let firstFrame = frames.first else {
            throw ExportError.renderFailed
        }

        let videoSize = CGSize(
            width: evenPixelDimension(firstFrame.size.width * firstFrame.scale),
            height: evenPixelDimension(firstFrame.size.height * firstFrame.scale)
        )
        let safeFileName = fileName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFileName)_\(format.rawValue)_story.mp4")

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(videoSize.width),
            AVVideoHeightKey: Int(videoSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(videoSize.width),
            kCVPixelBufferHeightKey as String: Int(videoSize.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )

        guard writer.canAdd(input) else {
            throw ExportError.videoWriterFailed
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? ExportError.videoWriterFailed
        }
        writer.startSession(atSourceTime: .zero)

        let holdFrameCount = max(1, Int(round(secondsPerFrame * Double(framesPerSecond))))
        var frameIndex: Int64 = 0

        for frame in frames {
            let pixelBuffer = try makePixelBuffer(from: frame, size: videoSize, pool: adaptor.pixelBufferPool)
            for _ in 0..<holdFrameCount {
                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(nanoseconds: 10_000_000)
                }

                let presentationTime = CMTime(value: frameIndex, timescale: framesPerSecond)
                guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    throw writer.error ?? ExportError.videoWriterFailed
                }
                frameIndex += 1
            }
        }

        input.markAsFinished()

        try await withCheckedThrowingContinuation { continuation in
            writer.finishWriting {
                switch writer.status {
                case .completed:
                    continuation.resume()
                case .failed, .cancelled:
                    continuation.resume(throwing: writer.error ?? ExportError.videoWriterFailed)
                default:
                    continuation.resume(throwing: ExportError.videoWriterFailed)
                }
            }
        }

        return url
    }

    private func makePixelBuffer(
        from image: UIImage,
        size: CGSize,
        pool: CVPixelBufferPool?
    ) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        if let pool {
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        } else {
            let attributes: [String: Any] = [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
            CVPixelBufferCreate(
                nil,
                Int(size.width),
                Int(size.height),
                kCVPixelFormatType_32BGRA,
                attributes as CFDictionary,
                &pixelBuffer
            )
        }

        guard let pixelBuffer else {
            throw ExportError.pixelBufferFailed
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
            let context = CGContext(
                data: baseAddress,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
            )
        else {
            throw ExportError.pixelBufferFailed
        }

        let drawRect = CGRect(origin: .zero, size: size)
        context.clear(drawRect)
        context.interpolationQuality = .high

        // CVPixelBuffer-backed Core Graphics contexts use a different vertical
        // origin than UIKit image drawing. Flip the context once so video frames
        // match the same orientation as ImageRenderer screenshots.
        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        image.draw(in: drawRect)
        UIGraphicsPopContext()
        context.restoreGState()

        return pixelBuffer
    }

    private func evenPixelDimension(_ value: CGFloat) -> Int {
        let rounded = max(2, Int(value.rounded()))
        return rounded.isMultiple(of: 2) ? rounded : rounded + 1
    }
}
