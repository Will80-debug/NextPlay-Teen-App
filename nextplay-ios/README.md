# NextPlay iOS - Create Feature Implementation

## Overview
Complete 30-second video creation flow for NextPlay app, including recording, trimming, editing, and uploading.

## Features
- ✅ In-app camera recording (max 30 seconds)
- ✅ Photo library selection with auto-trim
- ✅ Video preview and editing
- ✅ Trim timeline (max 30s enforcement)
- ✅ Cover frame selection
- ✅ Caption and hashtags
- ✅ Category tagging
- ✅ Background upload with progress
- ✅ Retry and resume support
- ✅ FTC COPPA compliant (no DOB storage)

## Project Structure

```
NextPlay/
├── Views/
│   ├── Create/
│   │   ├── CreateCameraView.swift          # Main camera recording screen
│   │   ├── TrimPreviewView.swift           # Video trim and preview
│   │   ├── PostDetailsView.swift           # Caption, hashtags, category
│   │   └── Components/
│   │       ├── RecordButton.swift          # Circular record button
│   │       ├── TimerView.swift             # Countdown timer
│   │       ├── TrimSlider.swift            # Timeline trim control
│   │       └── CoverFramePicker.swift      # Thumbnail selector
│   ├── MainTabView.swift                    # Bottom tab navigation
│   └── PermissionsView.swift                # Permission request UI
├── ViewModels/
│   ├── CameraViewModel.swift                # Camera capture logic
│   ├── VideoEditorViewModel.swift           # Trim and export logic
│   └── UploadViewModel.swift                # Upload management
├── Services/
│   ├── CameraManager.swift                  # AVFoundation camera setup
│   ├── VideoTrimmer.swift                   # Video trim and export
│   ├── UploadService.swift                  # Network upload
│   └── AnalyticsService.swift               # Event tracking
├── Models/
│   ├── VideoPost.swift                      # Video data model
│   ├── CreateUploadRequest.swift            # Upload request model
│   └── Category.swift                       # Category enum
├── Utilities/
│   ├── PermissionsManager.swift             # Permission handling
│   ├── ThumbnailGenerator.swift             # Cover frame extraction
│   └── VideoValidator.swift                 # Duration validation
└── Config/
    └── APIConfig.swift                      # API base URL config
```

## Installation

### 1. Add to Xcode Project
1. Copy all Swift files to your Xcode project
2. Add AVFoundation framework: Target → Frameworks → Add AVFoundation
3. Add PhotosUI framework: Target → Frameworks → Add PhotosUI

### 2. Configure Info.plist
Add the following privacy descriptions:

```xml
<key>NSCameraUsageDescription</key>
<string>NextPlay needs camera access to record your creative videos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>NextPlay needs microphone access to record audio with your videos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>NextPlay needs photo library access to select videos to share.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>NextPlay needs permission to save your created videos.</string>
```

### 3. Configure API Base URL
Edit `Config/APIConfig.swift`:

```swift
struct APIConfig {
    static let baseURL = "https://your-api-domain.com/api/v1"
    // For development:
    // static let baseURL = "http://localhost:3000/api/v1"
}
```

## Usage

### Integrate into Main App

```swift
import SwiftUI

@main
struct NextPlayApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
```

### Tab Bar Integration

The `MainTabView` includes:
- Home tab
- Explore tab
- **Create tab** (center, elevated button)
- Notifications tab
- Profile tab

Tapping Create opens `CreateCameraView`.

## Technical Details

### Camera Recording
- Uses `AVCaptureSession` for camera input
- Records to temporary file using `AVAssetWriter`
- Real-time duration monitoring (max 30s)
- Supports front/back camera flip
- Flash toggle (back camera only)
- Speed control (0.5x, 1x)
- Timer (3 second countdown)

### Video Trimming
- Uses `AVAssetExportSession` for export
- Enforces 30-second maximum duration
- Generates H.264/AAC MP4 output
- Quality: AVAssetExportPresetHighQuality
- Timeline scrubbing with visual feedback

### Upload Process
1. Initialize upload: `POST /videos/init`
2. Upload video: `PUT {uploadUrl}`
3. Upload thumbnail: `POST /videos/{videoId}/thumbnail`
4. Publish: `POST /videos/{videoId}/publish`

Supports:
- Background uploads
- Progress tracking
- Retry on failure
- Resume interrupted uploads

### Permission Handling
- Requests permissions on first use
- Shows friendly in-app explanation
- Provides Settings deep-link if denied
- Graceful degradation without permissions

## API Contract

### 1. Initialize Upload
```
POST /videos/init
Content-Type: application/json

{
  "userId": "user123",
  "durationSeconds": 28.5,
  "createdAt": "2025-12-23T12:00:00Z"
}

Response 200:
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "videoId": "video_abc123",
  "expiresAt": "2025-12-23T13:00:00Z"
}
```

### 2. Upload Video File
```
PUT {uploadUrl}
Content-Type: video/mp4
Body: <binary video data>

Response 200: OK
```

### 3. Upload Thumbnail
```
POST /videos/{videoId}/thumbnail
Content-Type: multipart/form-data

thumbnail: <image file>

Response 200:
{
  "thumbnailUrl": "https://cdn.example.com/thumb_abc123.jpg"
}
```

### 4. Publish Video
```
POST /videos/{videoId}/publish
Content-Type: application/json

{
  "caption": "Amazing skate tricks! 🛹",
  "hashtags": ["skateboarding", "tricks", "sports"],
  "category": "Sports"
}

Response 200:
{
  "success": true,
  "feedItem": {
    "id": "video_abc123",
    "videoUrl": "https://cdn.example.com/video_abc123.mp4",
    "thumbnailUrl": "https://cdn.example.com/thumb_abc123.jpg",
    "caption": "Amazing skate tricks! 🛹",
    "hashtags": ["skateboarding", "tricks", "sports"],
    "category": "Sports",
    "durationSeconds": 28.5,
    "createdAt": "2025-12-23T12:00:00Z",
    "userId": "user123",
    "likeCount": 0,
    "commentCount": 0
  }
}
```

## Testing

### Unit Tests
```swift
// Test duration enforcement
func testVideoTrimmerEnforces30SecondLimit() {
    let trimmer = VideoTrimmer()
    let url = // 60 second video
    let result = try? trimmer.trim(url, startTime: 0, endTime: 35)
    XCTAssertNil(result) // Should fail for >30s
}

// Test thumbnail generation
func testThumbnailGeneratorCreatesImage() {
    let generator = ThumbnailGenerator()
    let url = // test video
    let thumbnail = try? generator.generate(from: url, at: 5.0)
    XCTAssertNotNil(thumbnail)
}
```

### Manual Testing Checklist
- [ ] Record 30-second video successfully
- [ ] Timer shows countdown from 30 to 0
- [ ] Recording stops automatically at 30s
- [ ] Can flip camera during recording
- [ ] Can toggle flash (back camera)
- [ ] Can select video from library
- [ ] Videos >30s automatically open trimmer
- [ ] Trim slider enforces 30s max range
- [ ] Can select cover frame
- [ ] Can add caption and hashtags
- [ ] Upload shows progress bar
- [ ] Retry works after network failure
- [ ] Video appears in feed after publish

## Design System

### Colors
```swift
Color.nextPlayBackground = Color(hex: "#0A0505") // Dark background
Color.nextPlayGold = Color(hex: "#D4A574")       // Gold accent
Color.nextPlayRed = Color(hex: "#8B1A1A")        // Red accent
Color.nextPlayBorder = Color(hex: "#FFD700").opacity(0.4)
```

### Typography
```swift
Font.nextPlayTitle = .system(size: 28, weight: .bold)
Font.nextPlayBody = .system(size: 16, weight: .regular)
Font.nextPlayCaption = .system(size: 14, weight: .medium)
```

### Components
- Record button: 80pt diameter, gold ring, red center
- Timer: 48pt font, white, monospaced
- Buttons: Rounded rect, gold border, dark fill
- Sliders: Gold track, white thumb

## Analytics Events

Track these events locally:

```swift
AnalyticsService.track(.createStarted)
AnalyticsService.track(.recordCompleted(duration: 28.5))
AnalyticsService.track(.uploadStarted(videoId: "abc123"))
AnalyticsService.track(.uploadProgress(percent: 0.5))
AnalyticsService.track(.uploadSuccess(videoId: "abc123"))
AnalyticsService.track(.uploadFailed(error: "Network timeout"))
AnalyticsService.track(.videoPublished(videoId: "abc123"))
```

## Safety & Compliance

### Age-Appropriate Defaults
- Enforces user must be signed in
- Checks age band before allowing creation
- No DOB storage (age band only: 13-15, 16-17, 18+)
- No sensitive data sent to ad SDKs

### Content Safety
- Videos limited to 30 seconds
- No personal identifiable information in metadata
- User-controlled visibility (from safety settings)

## Performance Optimization

### Video Export
- Uses hardware-accelerated encoding
- Async export with completion handlers
- Temp file cleanup after upload
- Cancel support for long operations

### Memory Management
- Release camera session when not in use
- Dispose of large video assets properly
- Use weak references in closures
- Monitor memory warnings

### Battery Optimization
- Stop camera when backgrounded
- Pause uploads on low battery
- Resume uploads when battery recovers

## Error Handling

### Camera Errors
- Device not available → Show alert
- Permission denied → Show settings CTA
- Recording failed → Retry or dismiss

### Upload Errors
- Network timeout → Auto retry (3 attempts)
- Server error → Show error message + retry
- Invalid video → Show validation error
- Storage full → Show storage warning

## Future Enhancements

### Phase 2 Features
1. **Filters** - Beauty, vintage, B&W filters
2. **Text overlays** - Add animated text
3. **Stickers** - Emoji and sticker library
4. **Music** - Add background music tracks
5. **Speed ramping** - Variable speed segments
6. **Multi-clip** - Combine multiple clips
7. **Transitions** - Fade, wipe effects
8. **AR Effects** - Face filters and effects
9. **Green screen** - Background replacement
10. **Duets** - Record with existing video

### Phase 3 Features
1. **Live streaming** - Go live functionality
2. **Collaborative videos** - Multi-user creation
3. **Templates** - Pre-made video templates
4. **Advanced editing** - Cut, splice, merge
5. **Audio editing** - Voiceover, sound effects

## Troubleshooting

### Camera Not Starting
1. Check Info.plist permissions
2. Verify physical device (simulator has limitations)
3. Check camera not in use by another app
4. Reset device if persistent

### Upload Failing
1. Verify API base URL in APIConfig
2. Check network connectivity
3. Verify backend endpoints are running
4. Check video file size limits
5. Review server logs for errors

### Video Not Playing
1. Check video codec (should be H.264)
2. Verify video file exists at URL
3. Check file permissions
4. Try re-encoding video

## Support

For issues or questions:
1. Check this README first
2. Review code comments
3. Check inline documentation
4. File GitHub issue (if applicable)

## License

Copyright © 2025 Player 1 Academy. All rights reserved.

---

**NextPlay iOS - Create Feature**
Version 1.0.0 | Built with SwiftUI & AVFoundation
