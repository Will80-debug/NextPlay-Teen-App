//
//  VideoTrimmer.swift
//  NextPlay
//
//  Utility for trimming videos to 30 seconds max and exporting optimized MP4
//

import AVFoundation
import UIKit

/// Handles video trimming, export, and thumbnail generation
class VideoTrimmer {
    
    // MARK: - Constants
    static let maxDuration: Double = 30.0
    static let preferredTimescale: Int32 = 600
    
    // MARK: - Errors
    enum TrimError: LocalizedError {
        case invalidAsset
        case exportFailed
        case durationExceedsLimit
        case invalidTimeRange
        
        var errorDescription: String? {
            switch self {
            case .invalidAsset:
                return "Invalid video asset"
            case .exportFailed:
                return "Failed to export video"
            case .durationExceedsLimit:
                return "Video exceeds 30 second limit"
            case .invalidTimeRange:
                return "Invalid time range for trimming"
            }
        }
    }
    
    // MARK: - Video Duration Check
    /// Checks if a video needs trimming
    static func needsTrimming(_ asset: AVAsset) async -> Bool {
        let duration = try? await asset.load(.duration)
        guard let duration = duration else { return false }
        return CMTimeGetSeconds(duration) > maxDuration
    }
    
    /// Gets the duration of a video asset
    static func getDuration(_ asset: AVAsset) async throws -> Double {
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
    
    // MARK: - Trimming
    /// Trims a video to specified start and end times
    /// - Parameters:
    ///   - asset: Source video asset
    ///   - startTime: Start time in seconds
    ///   - endTime: End time in seconds
    ///   - outputURL: Destination URL for trimmed video
    /// - Returns: URL of the trimmed video
    static func trimVideo(
        asset: AVAsset,
        startTime: Double,
        endTime: Double,
        outputURL: URL? = nil
    ) async throws -> URL {
        
        // Validate time range
        let duration = try await getDuration(asset)
        guard startTime >= 0,
              endTime > startTime,
              endTime <= duration else {
            throw TrimError.invalidTimeRange
        }
        
        // Ensure trim doesn't exceed max duration
        let trimDuration = endTime - startTime
        guard trimDuration <= maxDuration else {
            throw TrimError.durationExceedsLimit
        }
        
        // Create time range
        let start = CMTime(seconds: startTime, preferredTimescale: preferredTimescale)
        let end = CMTime(seconds: endTime, preferredTimescale: preferredTimescale)
        let timeRange = CMTimeRange(start: start, end: end)
        
        // Create output URL
        let output = outputURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: output)
        
        // Export video
        return try await exportVideo(asset: asset, timeRange: timeRange, outputURL: output)
    }
    
    /// Exports video with optimized settings for upload
    private static func exportVideo(
        asset: AVAsset,
        timeRange: CMTimeRange,
        outputURL: URL
    ) async throws -> URL {
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw TrimError.exportFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            print("Export failed: \(String(describing: exportSession.error))")
            throw TrimError.exportFailed
        case .cancelled:
            throw TrimError.exportFailed
        default:
            throw TrimError.exportFailed
        }
    }
    
    // MARK: - Thumbnail Generation
    /// Generates a thumbnail image from video at specified time
    /// - Parameters:
    ///   - asset: Source video asset
    ///   - time: Time in seconds to capture thumbnail
    /// - Returns: UIImage thumbnail
    static func generateThumbnail(
        from asset: AVAsset,
        at time: Double
    ) async throws -> UIImage {
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let cmTime = CMTime(seconds: time, preferredTimescale: preferredTimescale)
        
        let cgImage = try await imageGenerator.image(at: cmTime).image
        return UIImage(cgImage: cgImage)
    }
    
    /// Generates multiple thumbnail images for timeline scrubbing
    /// - Parameters:
    ///   - asset: Source video asset
    ///   - count: Number of thumbnails to generate
    /// - Returns: Array of UIImage thumbnails
    static func generateThumbnails(
        from asset: AVAsset,
        count: Int = 10
    ) async throws -> [UIImage] {
        
        let duration = try await getDuration(asset)
        let interval = duration / Double(count)
        
        var thumbnails: [UIImage] = []
        
        for i in 0..<count {
            let time = interval * Double(i)
            let thumbnail = try await generateThumbnail(from: asset, at: time)
            thumbnails.append(thumbnail)
        }
        
        return thumbnails
    }
    
    // MARK: - Video Information
    /// Gets video resolution
    static func getResolution(_ asset: AVAsset) async throws -> CGSize {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw TrimError.invalidAsset
        }
        
        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        
        // Adjust for orientation
        if transform.tx == size.width && transform.ty == size.height {
            return CGSize(width: size.height, height: size.width)
        }
        
        return size
    }
    
    /// Gets video file size in MB
    static func getFileSize(_ url: URL) -> Double {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        
        return Double(fileSize) / (1024 * 1024) // Convert to MB
    }
    
    // MARK: - Preview Generation
    /// Generates a short preview clip (3-5 seconds) for fast loading
    /// - Parameters:
    ///   - asset: Source video asset
    ///   - duration: Preview duration (default 3 seconds)
    /// - Returns: URL of the preview video
    static func generatePreview(
        from asset: AVAsset,
        duration: Double = 3.0
    ) async throws -> URL {
        
        let videoDuration = try await getDuration(asset)
        let startTime = max(0, (videoDuration - duration) / 2) // Start from middle
        let endTime = min(videoDuration, startTime + duration)
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "_preview")
            .appendingPathExtension("mp4")
        
        return try await trimVideo(
            asset: asset,
            startTime: startTime,
            endTime: endTime,
            outputURL: outputURL
        )
    }
}
