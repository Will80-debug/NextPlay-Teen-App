//
//  VideoValidator.swift
//  NextPlay
//
//  Video validation utilities
//

import AVFoundation
import Foundation

enum VideoValidationError: Error, LocalizedError {
    case durationExceedsLimit(actualDuration: Double, maxDuration: Double)
    case fileSizeExceedsLimit(actualSize: Int64, maxSize: Int64)
    case invalidFormat
    case cannotReadFile
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .durationExceedsLimit(let actual, let max):
            return "Video duration (\(String(format: "%.1f", actual))s) exceeds maximum (\(String(format: "%.1f", max))s)"
        case .fileSizeExceedsLimit(let actual, let max):
            return "Video file size (\(ByteCountFormatter.string(fromByteCount: actual, countStyle: .file))) exceeds maximum (\(ByteCountFormatter.string(fromByteCount: max, countStyle: .file)))"
        case .invalidFormat:
            return "Invalid video format. Please use MP4 or MOV format."
        case .cannotReadFile:
            return "Cannot read video file"
        case .unknown:
            return "Unknown validation error"
        }
    }
}

class VideoValidator {
    
    // MARK: - Validate Duration
    
    static func validateDuration(of asset: AVAsset, maxDuration: Double = APIConfig.maxVideoDuration) throws {
        let duration = CMTimeGetSeconds(asset.duration)
        
        guard duration <= maxDuration else {
            throw VideoValidationError.durationExceedsLimit(actualDuration: duration, maxDuration: maxDuration)
        }
    }
    
    // MARK: - Validate File Size
    
    static func validateFileSize(at url: URL, maxSize: Int64 = APIConfig.maxVideoFileSize) throws {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            throw VideoValidationError.cannotReadFile
        }
        
        guard fileSize <= maxSize else {
            throw VideoValidationError.fileSizeExceedsLimit(actualSize: fileSize, maxSize: maxSize)
        }
    }
    
    // MARK: - Validate Format
    
    static func validateFormat(of asset: AVAsset) throws {
        let videoTracks = asset.tracks(withMediaType: .video)
        
        guard !videoTracks.isEmpty else {
            throw VideoValidationError.invalidFormat
        }
        
        // Check if video is in a supported format
        guard let formatDescription = videoTracks.first?.formatDescriptions.first as? CMFormatDescription else {
            throw VideoValidationError.invalidFormat
        }
        
        let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
        guard mediaType == kCMMediaType_Video else {
            throw VideoValidationError.invalidFormat
        }
    }
    
    // MARK: - Full Validation
    
    static func validate(url: URL, maxDuration: Double = APIConfig.maxVideoDuration) throws {
        let asset = AVAsset(url: url)
        
        try validateFormat(of: asset)
        try validateDuration(of: asset, maxDuration: maxDuration)
        try validateFileSize(at: url)
    }
    
    // MARK: - Get Video Info
    
    static func getVideoInfo(from url: URL) -> (duration: Double, fileSize: Int64)? {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        
        return (duration, fileSize)
    }
    
    // MARK: - Check if Trimming Required
    
    static func needsTrimming(url: URL, maxDuration: Double = APIConfig.maxVideoDuration) -> Bool {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        return duration > maxDuration
    }
}
