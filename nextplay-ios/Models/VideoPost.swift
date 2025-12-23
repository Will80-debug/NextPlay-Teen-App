//
//  VideoPost.swift
//  NextPlay
//
//  Video post data model
//

import Foundation

struct VideoPost: Identifiable, Codable {
    let id: String
    let userId: String
    let videoUrl: String
    let thumbnailUrl: String
    let caption: String
    let hashtags: [String]
    let category: Category
    let durationSeconds: Double
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, userId, videoUrl, thumbnailUrl, caption, hashtags, category
        case durationSeconds, createdAt, likeCount, commentCount
    }
}

// MARK: - Create Upload Request

struct CreateUploadRequest: Codable {
    let userId: String
    let durationSeconds: Double
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId, durationSeconds, createdAt
    }
}

// MARK: - Upload Response

struct UploadInitResponse: Codable {
    let uploadUrl: String
    let videoId: String
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case uploadUrl, videoId, expiresAt
    }
}

struct PublishRequest: Codable {
    let caption: String
    let hashtags: [String]
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case caption, hashtags, category
    }
}

struct PublishResponse: Codable {
    let success: Bool
    let feedItem: VideoPost?
    
    enum CodingKeys: String, CodingKey {
        case success, feedItem
    }
}

struct ThumbnailUploadResponse: Codable {
    let thumbnailUrl: String
    
    enum CodingKeys: String, CodingKey {
        case thumbnailUrl
    }
}
