# NextPlay Video Creation Feature

A complete 30-second video creation flow for the NextPlay iOS app with camera recording, video trimming, and upload functionality.

## 📋 Overview

This feature provides a full video creation pipeline:
1. **Record** videos with in-app camera (max 30 seconds)
2. **Pick** videos from device library (auto-trim if > 30s)
3. **Preview & Edit** with trim controls, sound toggle, and cover selection
4. **Add Metadata** including caption, hashtags, and category
5. **Upload** to backend with progress tracking and retry logic

## 🎨 UI Design

The UI matches NextPlay's signature styling:
- **Dark background** with cosmic theme
- **Gold/Bronze accents** (#FFD700, #D4A574)
- **Red gradient buttons** (#B91C1C, #7F1D1D)
- **Smooth animations** and transitions
- **Bottom tab bar** with centered Create button

## 🏗️ Architecture

### MVVM Structure

```
nextplay-ios-create/
├── Models/
│   └── VideoPost.swift          # Data models for video posts
├── Views/
│   ├── CreateCameraView.swift   # Camera recording interface
│   ├── TrimPreviewView.swift    # Video preview and trimming
│   ├── PostDetailsView.swift    # Metadata and upload
│   └── PhotoLibraryPicker.swift # PHPicker wrapper
├── ViewModels/
│   └── (ViewModels embedded in Views for simplicity)
├── Services/
│   ├── CameraManager.swift      # AVFoundation camera control
│   └── VideoUploadService.swift # Upload with progress
├── Utilities/
│   └── VideoTrimmer.swift       # Video processing utilities
└── Tests/
    └── VideoTrimmerTests.swift  # Unit tests
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- AVFoundation framework
- PhotosUI framework

### Installation

1. **Add files to your Xcode project**:
   - Drag the `nextplay-ios-create` folder into your Xcode project
   - Ensure "Copy items if needed" is checked
   - Add to your app target

2. **Configure Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>NextPlay needs camera access to record videos</string>

<key>NSMicrophoneUsageDescription</key>
<string>NextPlay needs microphone access to record audio with videos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>NextPlay needs photo library access to select videos</string>
```

3. **Configure API Base URL**:

In `VideoUploadService.swift`, update the API URL:

```swift
static var apiBaseURL: String = "https://your-api-domain.com"
```

Or configure dynamically:
```swift
VideoUploadService.apiBaseURL = AppConfig.shared.apiURL
```

### Integration with Tab Bar

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateCamera = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                ExploreView()
                    .tag(1)
                
                Color.clear // Placeholder for center button
                    .tag(2)
                
                NotificationsView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            // Custom Tab Bar
            customTabBar
        }
        .fullScreenCover(isPresented: $showCreateCamera) {
            CreateCameraView()
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "house.fill", tag: 0)
            tabButton(icon: "magnifyingglass", tag: 1)
            
            // Center Create Button
            Button(action: { showCreateCamera = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B91C1C"), Color(hex: "7F1D1D")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -15)
            }
            
            tabButton(icon: "bell.fill", tag: 3)
            tabButton(icon: "person.fill", tag: 4)
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.95))
    }
    
    private func tabButton(icon: String, tag: Int) -> some View {
        Button(action: { selectedTab = tag }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(selectedTab == tag ? Color(hex: "FFD700") : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}
```

## 📱 Usage

### Basic Flow

```swift
// 1. User taps Create button
// 2. CreateCameraView opens with camera
// 3. User records or selects video
// 4. TrimPreviewView opens for editing
// 5. PostDetailsView opens for metadata
// 6. Video uploads automatically
// 7. Success confirmation shown
```

### Programmatic Usage

```swift
// Record a video
let cameraView = CreateCameraView()

// Trim a video
let trimView = TrimPreviewView(videoURL: videoURL)

// Upload a video
let uploadService = VideoUploadService()
let metadata = VideoMetadata(
    caption: "Amazing skateboarding!",
    hashtags: ["skateboard", "extreme", "sports"],
    category: .sports
)

Task {
    do {
        let videoPost = try await uploadService.uploadVideo(
            videoURL: videoURL,
            thumbnail: thumbnailImage,
            metadata: metadata,
            userId: currentUserId
        )
        print("Uploaded: \(videoPost.id)")
    } catch {
        print("Upload failed: \(error)")
    }
}
```

## 🎥 Camera Features

### Recording Controls

- **Record Button**: Large gold ring with red center
- **Timer**: Countdown from 30:00 to 00:00
- **Flip Camera**: Switch between front/back
- **Flash**: Off/On/Auto toggle
- **Speed**: 0.5x/1x/1.5x recording speed
- **Library**: Pick from photo library
- **Close**: Exit camera

### Auto-Stop

Recording automatically stops at 30 seconds to enforce the limit.

## ✂️ Video Trimming

### Features

- **Timeline Scrubber**: Visual thumbnails
- **Dual Sliders**: Adjust start and end times
- **Duration Display**: Real-time duration counter
- **30s Enforcement**: Cannot exceed 30 seconds
- **Sound Toggle**: Mute/unmute audio
- **Cover Selection**: Choose cover frame

### Trimming API

```swift
// Trim a video
let trimmedURL = try await VideoTrimmer.trimVideo(
    asset: AVAsset(url: sourceURL),
    startTime: 5.0,
    endTime: 25.0
)

// Generate thumbnail
let thumbnail = try await VideoTrimmer.generateThumbnail(
    from: asset,
    at: 10.0 // time in seconds
)

// Check duration
let duration = try await VideoTrimmer.getDuration(asset)
let needsTrim = await VideoTrimmer.needsTrimming(asset)
```

## 📝 Metadata & Categories

### Caption

- Max 150 characters
- Character count displayed
- Supports emojis

### Hashtags

- Suggested tags provided
- Max 5 hashtags
- Tap to add/remove
- Custom tags supported

### Categories

- Sports ⚽
- Dance 💃
- Art 🎨
- Comedy 🎭
- STEM 🧪
- Gaming 🎮
- Music 🎵
- Fitness 💪

## 🌐 Backend Integration

### API Endpoints

#### 1. Initialize Upload

```http
POST /videos/init
Content-Type: application/json

{
  "userId": "user_123",
  "caption": "Amazing video!",
  "hashtags": ["awesome", "nextplay"],
  "category": "Sports",
  "durationSeconds": 15.5,
  "createdAt": "2025-01-01T12:00:00Z"
}

Response:
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "videoId": "video_456",
  "thumbnailUploadUrl": "https://s3.amazonaws.com/..."
}
```

#### 2. Upload Video

```http
PUT {uploadUrl}
Content-Type: video/mp4

[Binary MP4 data]

Response: 200 OK
```

#### 3. Upload Thumbnail

```http
POST /videos/{videoId}/thumbnail
Content-Type: image/jpeg

[Binary JPEG data]

Response: 200 OK
```

#### 4. Publish Video

```http
POST /videos/{videoId}/publish
Content-Type: application/json

Response:
{
  "success": true,
  "feedItem": {
    "id": "video_456",
    "userId": "user_123",
    "videoUrl": "https://cdn.nextplay.com/videos/...",
    "thumbnailUrl": "https://cdn.nextplay.com/thumbs/...",
    "caption": "Amazing video!",
    "hashtags": ["awesome", "nextplay"],
    "category": "Sports",
    "durationSeconds": 15.5,
    "createdAt": "2025-01-01T12:00:00Z",
    "likeCount": 0,
    "commentCount": 0,
    "viewCount": 0
  }
}
```

### Upload Progress

```swift
// Observe upload progress
uploadService.$uploadProgress
    .sink { progress in
        print("Progress: \(progress * 100)%")
    }

// Monitor upload state
uploadService.$uploadState
    .sink { state in
        switch state {
        case .idle: print("Ready")
        case .preparing: print("Preparing...")
        case .uploading: print("Uploading...")
        case .completed: print("Done!")
        case .failed: print("Failed")
        }
    }
```

### Retry Logic

```swift
// Retry failed upload
let videoPost = try await uploadService.retryUpload(
    videoURL: videoURL,
    thumbnail: thumbnail,
    metadata: metadata,
    userId: userId
)
```

## 🧪 Testing

### Run Unit Tests

```bash
# In Xcode
⌘ + U

# Or via command line
xcodebuild test -scheme NextPlay -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage

- ✅ Duration enforcement (≤30s)
- ✅ Video trimming accuracy
- ✅ Invalid time range handling
- ✅ Thumbnail generation
- ✅ File size calculation
- ✅ Preview clip generation
- ✅ Performance benchmarks

### Manual Testing Checklist

- [ ] Record 30s video - auto stops
- [ ] Record 10s video - stops manually
- [ ] Pick 45s video from library - trim UI appears
- [ ] Trim video to 30s - export succeeds
- [ ] Toggle sound on/off
- [ ] Select cover frame
- [ ] Add caption with 150 chars
- [ ] Select 5 hashtags
- [ ] Choose category
- [ ] Upload with progress
- [ ] Handle network failure
- [ ] Retry upload
- [ ] Success confirmation

## 📊 Analytics Events

The app logs the following analytics events (local only):

```swift
// Analytics events tracked
- create_started       // User opens camera
- record_completed     // Recording finishes
- video_selected       // Video picked from library
- trim_completed       // Trimming finishes
- upload_started       // Upload begins
- upload_progress_50   // 50% uploaded
- upload_success       // Upload completes
- upload_failed        // Upload fails
- post_published       // Video goes live
```

Configure analytics in `VideoUploadService.swift`:

```swift
private func logAnalytics(_ event: String, error: Error? = nil) {
    // Send to your analytics service
    Analytics.shared.track(event, properties: [
        "timestamp": Date(),
        "error": error?.localizedDescription
    ])
}
```

## 🔒 Privacy & Safety

### Permissions

- Camera and microphone requested on first use
- Photo library access requested when needed
- Clear usage descriptions in Info.plist
- Settings CTA if permission denied

### Data Privacy

- No full DOB stored (age band only)
- User must be signed in to create
- Videos stored securely
- Metadata not shared with ads

### Content Safety

- Report button on all videos
- Age-appropriate defaults
- Moderation hooks ready
- COPPA compliant

## ⚡ Performance

### Optimizations

- **Background upload** with URLSession
- **Progressive thumbnails** during scrubbing
- **Efficient video export** with AVAssetExportSession
- **Memory management** for large videos
- **Cancellable operations**

### File Sizes

- Videos: H.264 MP4, optimized for network
- Thumbnails: JPEG, 0.8 quality, ~100KB
- Preview clips: 3-5s, ~500KB

## 🐛 Error Handling

### Common Errors

```swift
// Camera errors
- cameraUnavailable
- microphoneUnavailable
- setupFailed
- recordingFailed
- permissionDenied

// Trimming errors
- invalidAsset
- exportFailed
- durationExceedsLimit
- invalidTimeRange

// Upload errors
- invalidURL
- networkError
- serverError
- uploadFailed
- thumbnailFailed
- publishFailed
```

### User-Facing Messages

All errors have localized descriptions suitable for display to users.

## 🎯 Future Enhancements

### Optional Features

1. **Filters** - Apply color/style filters
2. **Text Overlays** - Add text captions
3. **AR Effects** - Face filters and effects
4. **Music Library** - Add background music
5. **Duet/Stitch** - Collaborate with other videos
6. **Speed Ramps** - Dynamic speed changes
7. **Transitions** - Between multiple clips
8. **Green Screen** - Background replacement
9. **Voice Effects** - Audio filters
10. **Templates** - Pre-made editing templates

### Implementation Suggestions

```swift
// Filter system
class VideoFilterManager {
    func applyFilter(_ filter: FilterType, to asset: AVAsset) async -> AVAsset
}

// Text overlay
class TextOverlayComposer {
    func addText(_ text: String, at time: Double, with style: TextStyle) async
}

// AR effects (using ARKit)
class AREffectManager {
    func applyEffect(_ effect: AREffect, to video: URL) async -> URL
}
```

## 📚 Resources

### Apple Documentation

- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [PHPicker](https://developer.apple.com/documentation/photokit/phpicker)
- [AVAssetExportSession](https://developer.apple.com/documentation/avfoundation/avassetexportsession)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)

### Related

- NextPlay Design System
- Backend API Documentation
- Content Moderation Guidelines
- App Store Review Guidelines

## 🤝 Contributing

When adding features:

1. Follow MVVM architecture
2. Add unit tests for utilities
3. Update this README
4. Match NextPlay UI styling
5. Test on real devices
6. Consider accessibility

## 📄 License

Copyright © 2025 NextPlay. All rights reserved.

## 💬 Support

For questions or issues:
- Check existing documentation
- Review test cases
- Contact iOS development team

---

**Built with ❤️ for NextPlay**
*Empowering teen creators*
