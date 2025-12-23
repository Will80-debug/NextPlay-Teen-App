//
//  APIConfig.swift
//  NextPlay
//
//  API configuration
//

import Foundation

struct APIConfig {
    // MARK: - Base URL
    
    /// Configure your API base URL here
    /// Production: "https://api.nextplay.com/v1"
    /// Development: "http://localhost:3000/api/v1"
    static let baseURL = "https://api.nextplay.com/v1"
    
    // MARK: - Endpoints
    
    static let videosInit = "/videos/init"
    static func videosThumbnail(videoId: String) -> String {
        return "/videos/\(videoId)/thumbnail"
    }
    static func videosPublish(videoId: String) -> String {
        return "/videos/\(videoId)/publish"
    }
    
    // MARK: - Timeouts
    
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 300.0 // 5 minutes for video upload
    
    // MARK: - Retry Configuration
    
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 2.0
    
    // MARK: - Video Constraints
    
    static let maxVideoDuration: Double = 30.0 // seconds
    static let maxVideoFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
}
