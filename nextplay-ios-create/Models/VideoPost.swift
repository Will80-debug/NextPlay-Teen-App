//
//  VideoPost.swift
//  NextPlay
//
//  Data model for video posts in the feed
//

import Foundation

/// Represents a video post in the NextPlay feed
struct VideoPost: Codable, Identifiable {
    let id: String
    let userId: String
    let videoUrl: String
    let thumbnailUrl: String
    let caption: String
    let hashtags: [String]
    let category: VideoCategory
    let durationSeconds: Double
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var viewCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case videoUrl
        case thumbnailUrl
        case caption
        case hashtags
        case category
        case durationSeconds
        case createdAt
        case likeCount
        case commentCount
        case viewCount
    }
}

/// Video categories matching the challenge types
enum VideoCategory: String, Codable, CaseIterable {
    case sports = "Sports"
    case dance = "Dance"
    case art = "Art"
    case comedy = "Comedy"
    case stem = "STEM"
    case gaming = "Gaming"
    case music = "Music"
    case fitness = "Fitness"
    
    var emoji: String {
        switch self {
        case .sports: return "⚽"
        case .dance: return "💃"
        case .art: return "🎨"
        case .comedy: return "🎭"
        case .stem: return "🧪"
        case .gaming: return "🎮"
        case .music: return "🎵"
        case .fitness: return "💪"
        }
    }
}

/// Request model for creating an upload
struct CreateUploadRequest: Codable {
    let userId: String
    let caption: String
    let hashtags: [String]
    let category: String
    let durationSeconds: Double
    let createdAt: Date
}

/// Response from upload initialization
struct UploadInitResponse: Codable {
    let uploadUrl: String
    let videoId: String
    let thumbnailUploadUrl: String?
}

/// Response from publish endpoint
struct PublishResponse: Codable {
    let success: Bool
    let feedItem: VideoPost?
    let message: String?
}

/// Local video metadata before upload
struct VideoMetadata {
    var caption: String = ""
    var hashtags: [String] = []
    var category: VideoCategory = .comedy
    var coverFrameTime: Double = 0.0
}
