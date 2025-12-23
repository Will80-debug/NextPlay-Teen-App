//
//  ThumbnailGenerator.swift
//  NextPlay
//
//  Generate thumbnails from video
//

import AVFoundation
import UIKit

enum ThumbnailError: Error, LocalizedError {
    case cannotGenerateImage
    case invalidTime
    case assetLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .cannotGenerateImage:
            return "Failed to generate thumbnail image"
        case .invalidTime:
            return "Invalid time for thumbnail extraction"
        case .assetLoadFailed:
            return "Failed to load video asset"
        }
    }
}

class ThumbnailGenerator {
    
    // MARK: - Generate Single Thumbnail
    
    /// Generate thumbnail at specific time
    func generate(
        from videoURL: URL,
        at time: Double,
        size: CGSize = CGSize(width: 1080, height: 1920)
    ) throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = size
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: cmTime, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            throw ThumbnailError.cannotGenerateImage
        }
    }
    
    // MARK: - Generate Multiple Thumbnails
    
    /// Generate multiple thumbnails at specified intervals
    func generateThumbnails(
        from videoURL: URL,
        count: Int = 10,
        size: CGSize = CGSize(width: 200, height: 360),
        completion: @escaping ([UIImage]) -> Void
    ) {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = size
        
        var images: [UIImage] = []
        let interval = duration / Double(count)
        
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<count {
                let time = Double(i) * interval
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                
                if let cgImage = try? imageGenerator.copyCGImage(at: cmTime, actualTime: nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            }
            
            DispatchQueue.main.async {
                completion(images)
            }
        }
    }
    
    // MARK: - Generate Frame Strip
    
    /// Generate evenly-spaced frames for timeline preview
    func generateFrameStrip(
        from videoURL: URL,
        frameCount: Int = 15,
        size: CGSize = CGSize(width: 120, height: 180)
    ) async throws -> [UIImage] {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = size
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        var images: [UIImage] = []
        let interval = duration / Double(frameCount)
        
        for i in 0..<frameCount {
            let time = Double(i) * interval
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            
            if let cgImage = try? imageGenerator.copyCGImage(at: cmTime, actualTime: nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        return images
    }
    
    // MARK: - Convert to JPEG Data
    
    /// Convert UIImage to JPEG data for upload
    func jpegData(
        from image: UIImage,
        compressionQuality: CGFloat = 0.8
    ) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    
    // MARK: - Generate Cover Frame Options
    
    /// Generate suggested cover frames (beginning, middle, end)
    func generateCoverOptions(
        from videoURL: URL,
        completion: @escaping ([UIImage]) -> Void
    ) {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        let times = [
            0.5,                    // Beginning
            duration / 2.0,         // Middle
            duration - 0.5          // End
        ]
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1080, height: 1920)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []
            
            for time in times {
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                if let cgImage = try? imageGenerator.copyCGImage(at: cmTime, actualTime: nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            }
            
            DispatchQueue.main.async {
                completion(images)
            }
        }
    }
    
    // MARK: - Optimized Thumbnail for Feed
    
    /// Generate optimized thumbnail for feed display
    func generateFeedThumbnail(
        from videoURL: URL,
        at time: Double = 0.5
    ) throws -> Data {
        let image = try generate(
            from: videoURL,
            at: time,
            size: CGSize(width: 720, height: 1280)
        )
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw ThumbnailError.cannotGenerateImage
        }
        
        return data
    }
}
