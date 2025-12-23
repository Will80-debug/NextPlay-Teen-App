//
//  VideoTrimmer.swift
//  NextPlay
//
//  Video trimming and export service
//

import AVFoundation
import UIKit

enum VideoTrimmerError: Error, LocalizedError {
    case invalidTimeRange
    case durationExceedsMaximum
    case exportFailed(underlyingError: Error?)
    case assetLoadFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidTimeRange:
            return "Invalid time range selected"
        case .durationExceedsMaximum:
            return "Selected duration exceeds 30 seconds"
        case .exportFailed(let error):
            return "Export failed: \(error?.localizedDescription ?? "Unknown error")"
        case .assetLoadFailed:
            return "Failed to load video asset"
        case .cancelled:
            return "Export was cancelled"
        }
    }
}

class VideoTrimmer {
    
    // MARK: - Trim Video
    
    /// Trim video to specified time range with 30-second enforcement
    func trim(
        videoURL: URL,
        startTime: Double,
        endTime: Double,
        outputQuality: String = AVAssetExportPresetHighQuality,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Validate time range
        guard startTime >= 0, endTime > startTime else {
            completion(.failure(VideoTrimmerError.invalidTimeRange))
            return
        }
        
        let duration = endTime - startTime
        
        // Enforce 30-second maximum
        guard duration <= APIConfig.maxVideoDuration else {
            completion(.failure(VideoTrimmerError.durationExceedsMaximum))
            return
        }
        
        let asset = AVAsset(url: videoURL)
        
        // Create time range
        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: start, end: end)
        
        // Generate output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        // Export
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: outputQuality
        ) else {
            completion(.failure(VideoTrimmerError.assetLoadFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(.success(outputURL))
                case .failed:
                    completion(.failure(VideoTrimmerError.exportFailed(underlyingError: exportSession.error)))
                case .cancelled:
                    completion(.failure(VideoTrimmerError.cancelled))
                default:
                    completion(.failure(VideoTrimmerError.exportFailed(underlyingError: nil)))
                }
            }
        }
    }
    
    // MARK: - Auto-trim to 30 Seconds
    
    /// Automatically trim video to first 30 seconds if longer
    func autoTrimTo30Seconds(
        videoURL: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration <= APIConfig.maxVideoDuration {
            // No trimming needed
            completion(.success(videoURL))
        } else {
            // Trim to first 30 seconds
            trim(
                videoURL: videoURL,
                startTime: 0,
                endTime: APIConfig.maxVideoDuration,
                completion: completion
            )
        }
    }
    
    // MARK: - Get Export Progress
    
    /// Get current export session for progress monitoring
    func exportWithProgress(
        videoURL: URL,
        startTime: Double,
        endTime: Double,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Validate time range
        guard startTime >= 0, endTime > startTime else {
            completion(.failure(VideoTrimmerError.invalidTimeRange))
            return
        }
        
        let duration = endTime - startTime
        guard duration <= APIConfig.maxVideoDuration else {
            completion(.failure(VideoTrimmerError.durationExceedsMaximum))
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: start, end: end)
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighQuality
        ) else {
            completion(.failure(VideoTrimmerError.assetLoadFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Monitor progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                progressHandler(exportSession.progress)
            }
        }
        
        exportSession.exportAsynchronously {
            timer.invalidate()
            
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    progressHandler(1.0)
                    completion(.success(outputURL))
                case .failed:
                    completion(.failure(VideoTrimmerError.exportFailed(underlyingError: exportSession.error)))
                case .cancelled:
                    completion(.failure(VideoTrimmerError.cancelled))
                default:
                    completion(.failure(VideoTrimmerError.exportFailed(underlyingError: nil)))
                }
            }
        }
    }
    
    // MARK: - Cancel Export
    
    func cancelExport(_ exportSession: AVAssetExportSession?) {
        exportSession?.cancelExport()
    }
}
