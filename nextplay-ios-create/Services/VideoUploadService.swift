//
//  VideoUploadService.swift
//  NextPlay
//
//  Service for uploading videos with progress tracking and retry logic
//

import Foundation
import Combine

/// Service for uploading videos to backend
class VideoUploadService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var uploadProgress: Double = 0
    @Published var uploadState: UploadState = .idle
    @Published var error: UploadError?
    
    // MARK: - Configuration
    static var apiBaseURL: String = "https://api.nextplay.com" // Configure this
    
    // MARK: - Private Properties
    private var uploadTask: URLSessionUploadTask?
    private var session: URLSession!
    private var observation: NSKeyValueObservation?
    
    // MARK: - Enums
    enum UploadState {
        case idle
        case preparing
        case uploading
        case completed
        case failed
    }
    
    enum UploadError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case serverError(String)
        case uploadFailed
        case thumbnailFailed
        case publishFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid upload URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .uploadFailed:
                return "Failed to upload video"
            case .thumbnailFailed:
                return "Failed to upload thumbnail"
            case .publishFailed:
                return "Failed to publish video"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Upload Flow
    /// Complete upload flow: init -> upload video -> upload thumbnail -> publish
    func uploadVideo(
        videoURL: URL,
        thumbnail: UIImage,
        metadata: VideoMetadata,
        userId: String
    ) async throws -> VideoPost {
        
        // Analytics: upload_started
        logAnalytics("upload_started")
        
        uploadState = .preparing
        uploadProgress = 0
        
        do {
            // Step 1: Initialize upload
            let initResponse = try await initializeUpload(
                userId: userId,
                metadata: metadata,
                videoURL: videoURL
            )
            
            // Step 2: Upload video file
            uploadState = .uploading
            try await uploadVideoFile(videoURL: videoURL, uploadURL: initResponse.uploadUrl)
            
            // Step 3: Upload thumbnail
            try await uploadThumbnail(
                thumbnail: thumbnail,
                videoId: initResponse.videoId
            )
            
            // Step 4: Publish video
            let videoPost = try await publishVideo(videoId: initResponse.videoId)
            
            uploadState = .completed
            uploadProgress = 1.0
            
            // Analytics: upload_success
            logAnalytics("upload_success")
            
            return videoPost
            
        } catch {
            uploadState = .failed
            
            // Analytics: upload_failed
            logAnalytics("upload_failed", error: error)
            
            throw error
        }
    }
    
    // MARK: - Step 1: Initialize Upload
    private func initializeUpload(
        userId: String,
        metadata: VideoMetadata,
        videoURL: URL
    ) async throws -> UploadInitResponse {
        
        let duration = try await VideoTrimmer.getDuration(AVAsset(url: videoURL))
        
        let request = CreateUploadRequest(
            userId: userId,
            caption: metadata.caption,
            hashtags: metadata.hashtags,
            category: metadata.category.rawValue,
            durationSeconds: duration,
            createdAt: Date()
        )
        
        guard let url = URL(string: "\(Self.apiBaseURL)/videos/init") else {
            throw UploadError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw UploadError.uploadFailed
        }
        
        let initResponse = try JSONDecoder().decode(UploadInitResponse.self, from: data)
        return initResponse
    }
    
    // MARK: - Step 2: Upload Video File
    private func uploadVideoFile(videoURL: URL, uploadURL: String) async throws {
        guard let url = URL(string: uploadURL) else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        
        return try await withCheckedThrowingContinuation { continuation in
            uploadTask = session.uploadTask(with: request, fromFile: videoURL) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: UploadError.networkError(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: UploadError.uploadFailed)
                    return
                }
                
                continuation.resume()
            }
            
            // Observe progress
            observation = uploadTask?.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                DispatchQueue.main.async {
                    self?.uploadProgress = progress.fractionCompleted * 0.7 // Video is 70% of total
                }
            }
            
            uploadTask?.resume()
        }
    }
    
    // MARK: - Step 3: Upload Thumbnail
    private func uploadThumbnail(thumbnail: UIImage, videoId: String) async throws {
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            throw UploadError.thumbnailFailed
        }
        
        guard let url = URL(string: "\(Self.apiBaseURL)/videos/\(videoId)/thumbnail") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = thumbnailData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw UploadError.thumbnailFailed
        }
        
        DispatchQueue.main.async {
            self.uploadProgress = 0.85 // Thumbnail is 15% of total
        }
    }
    
    // MARK: - Step 4: Publish Video
    private func publishVideo(videoId: String) async throws -> VideoPost {
        guard let url = URL(string: "\(Self.apiBaseURL)/videos/\(videoId)/publish") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw UploadError.publishFailed
        }
        
        let publishResponse = try JSONDecoder().decode(PublishResponse.self, from: data)
        
        guard publishResponse.success, let videoPost = publishResponse.feedItem else {
            throw UploadError.serverError(publishResponse.message ?? "Unknown error")
        }
        
        DispatchQueue.main.async {
            self.uploadProgress = 1.0
        }
        
        return videoPost
    }
    
    // MARK: - Retry Logic
    func retryUpload(
        videoURL: URL,
        thumbnail: UIImage,
        metadata: VideoMetadata,
        userId: String
    ) async throws -> VideoPost {
        
        // Reset state
        uploadProgress = 0
        error = nil
        
        // Retry upload
        return try await uploadVideo(
            videoURL: videoURL,
            thumbnail: thumbnail,
            metadata: metadata,
            userId: userId
        )
    }
    
    // MARK: - Cancel Upload
    func cancelUpload() {
        uploadTask?.cancel()
        uploadTask = nil
        observation?.invalidate()
        observation = nil
        
        uploadState = .idle
        uploadProgress = 0
    }
    
    // MARK: - Analytics
    private func logAnalytics(_ event: String, error: Error? = nil) {
        // Local analytics logging
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let errorMessage = error?.localizedDescription ?? "none"
        
        print("📊 Analytics: \(event) at \(timestamp) - Error: \(errorMessage)")
        
        // TODO: Send to analytics service (privacy-compliant)
    }
}

// MARK: - URLSessionTaskDelegate
extension VideoUploadService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didSendBodyData bytesSent: Int64,
                   totalBytesSent: Int64,
                   totalBytesExpectedToSend: Int64) {
        
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        DispatchQueue.main.async {
            self.uploadProgress = progress * 0.7 // Video upload is 70% of total
        }
    }
}

// MARK: - URLSessionDelegate
extension VideoUploadService: URLSessionDelegate {
    // Handle authentication challenges if needed
}
