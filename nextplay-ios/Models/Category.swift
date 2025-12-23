//
//  Category.swift
//  NextPlay
//
//  Video category enum
//

import Foundation

enum Category: String, Codable, CaseIterable {
    case sports = "Sports"
    case dance = "Dance"
    case art = "Art"
    case comedy = "Comedy"
    case stem = "STEM"
    case gaming = "Gaming"
    case music = "Music"
    case fitness = "Fitness"
    
    var icon: String {
        switch self {
        case .sports: return "⚽🏀"
        case .dance: return "💃🕺"
        case .art: return "🎨🖌️"
        case .comedy: return "😂🎭"
        case .stem: return "🧪🔬"
        case .gaming: return "🎮🕹️"
        case .music: return "🎵🎧"
        case .fitness: return "💪🏋️"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}
