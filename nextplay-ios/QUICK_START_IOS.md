# NextPlay iOS - Quick Start Guide

## 🚀 What's Included

### ✅ Complete Backend Services
All core functionality is **100% complete** and ready to use:

1. **CameraManager** - Record 30-second videos
2. **VideoTrimmer** - Enforce 30s limit with validation
3. **UploadService** - Full upload flow with progress
4. **ThumbnailGenerator** - Extract cover frames
5. **PermissionsManager** - Handle all permissions
6. **VideoValidator** - Validate duration/size/format

### ⏳ UI Views Needed
You need to create SwiftUI views to use these services:

1. **CreateCameraView** - Camera recording UI
2. **TrimPreviewView** - Video editing UI
3. **PostDetailsView** - Caption/category UI

## 🎯 Integration in 5 Steps

### Step 1: Copy Files to Xcode
```bash
# Add these folders to your Xcode project:
- Models/
- Services/
- Utilities/
- Config/
```

### Step 2: Configure Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>NextPlay needs camera access to record creative videos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>NextPlay needs microphone access to record audio.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>NextPlay needs photo library access to select videos.</string>
```

### Step 3: Set API URL
```swift
// Config/APIConfig.swift
static let baseURL = "https://your-api.com/v1"
```

### Step 4: Use Camera Service
```swift
import SwiftUI

struct CreateCameraView: View {
    @StateObject private var camera = CameraManager()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: camera.captureSession)
            
            VStack {
                // Timer
                Text(formatTime(camera.recordedDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Record button
                Button(action: {
                    if camera.isRecording {
                        camera.stopRecording { url in
                            // Video recorded at url
                        }
                    } else {
                        camera.startRecording { _ in }
                    }
                }) {
                    Circle()
                        .fill(camera.isRecording ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.gold, lineWidth: 4)
                        )
                }
            }
        }
        .onAppear {
            camera.setupCamera { _ in }
            camera.startSession()
        }
    }
    
    func formatTime(_ time: Double) -> String {
        let remaining = 30 - Int(time)
        return String(format: "%02d:%02d", 0, remaining)
    }
}
```

### Step 5: Upload Video
```swift
let uploader = UploadService()

uploader.upload(
    videoURL: recordedURL,
    thumbnail: thumbnailData,
    userId: currentUserId,
    caption: "My awesome video!",
    hashtags: ["cool", "nextplay"],
    category: "Sports"
) { result in
    switch result {
    case .success(let post):
        print("Published: \(post.id)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## 📝 Key Code Examples

### Record Video with 30s Limit
```swift
let camera = CameraManager()
camera.setupCamera { result in
    camera.startSession()
    camera.startRecording { result in
        // Automatically stops at 30 seconds
        // OR manually stop with camera.stopRecording()
    }
}
```

### Trim Video
```swift
let trimmer = VideoTrimmer()
trimmer.trim(
    videoURL: originalURL,
    startTime: 5.0,
    endTime: 25.0  // 20-second clip
) { result in
    switch result {
    case .success(let trimmedURL):
        print("Trimmed: \(trimmedURL)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Generate Thumbnail
```swift
let generator = ThumbnailGenerator()
let thumbnail = try generator.generate(
    from: videoURL,
    at: 2.0,  // 2 seconds into video
    size: CGSize(width: 1080, height: 1920)
)
let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
```

### Check Permissions
```swift
let permissions = PermissionsManager.shared

permissions.requestCameraPermission { granted in
    if granted {
        // Start camera
    } else {
        // Show settings alert
        permissions.openAppSettings()
    }
}
```

### Validate Video
```swift
do {
    try VideoValidator.validate(url: videoURL, maxDuration: 30.0)
    print("Video is valid!")
} catch let error as VideoValidationError {
    print(error.localizedDescription)
    // "Video duration (45.0s) exceeds maximum (30.0s)"
}
```

## 🎨 NextPlay Design System

### Colors
```swift
extension Color {
    static let nextPlayDark = Color(hex: "#0A0505")
    static let nextPlayGold = Color(hex: "#D4A574")
    static let nextPlayRed = Color(hex: "#8B1A1A")
    static let nextPlayBorder = Color(hex: "#FFD700").opacity(0.4)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```

### Typography
```swift
extension Font {
    static let nextPlayTitle = Font.system(size: 28, weight: .bold)
    static let nextPlayBody = Font.system(size: 16, weight: .regular)
    static let nextPlayCaption = Font.system(size: 14, weight: .medium)
    static let nextPlayTimer = Font.system(size: 48, weight: .bold, design: .monospaced)
}
```

### Button Styles
```swift
struct GoldButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.nextPlayRed)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.nextPlayGold, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
```

## 🧪 Testing Checklist

### Manual Tests
- [ ] Record 30-second video
- [ ] Timer counts down from 30 to 0
- [ ] Recording auto-stops at 30s
- [ ] Flip camera works
- [ ] Flash toggle works (back camera)
- [ ] Select video from library
- [ ] Videos >30s open trimmer
- [ ] Trim enforcement works
- [ ] Upload shows progress
- [ ] Video appears in feed

### Edge Cases
- [ ] Recording with low battery
- [ ] Recording with low storage
- [ ] Network interruption during upload
- [ ] Background during recording
- [ ] Background during upload
- [ ] Permission denial handling
- [ ] Very large video file
- [ ] Corrupted video file

## 📊 API Backend Requirements

Your backend must implement these endpoints:

### 1. Initialize Upload
```
POST /videos/init
Request: { userId, durationSeconds, createdAt }
Response: { uploadUrl, videoId, expiresAt }
```

### 2. Upload Video
```
PUT {uploadUrl}
Body: video file (binary)
Response: 200 OK
```

### 3. Upload Thumbnail
```
POST /videos/{videoId}/thumbnail
Body: multipart/form-data with image
Response: { thumbnailUrl }
```

### 4. Publish Video
```
POST /videos/{videoId}/publish
Request: { caption, hashtags, category }
Response: { success, feedItem }
```

## 🎯 Priority Order

### Week 1: Core Recording
1. Implement CreateCameraView
2. Add RecordButton component
3. Add TimerView component
4. Test recording flow

### Week 2: Editing
1. Implement TrimPreviewView
2. Add TrimSlider component
3. Add CoverFramePicker
4. Test trimming flow

### Week 3: Publishing
1. Implement PostDetailsView
2. Add caption input
3. Add category picker
4. Test upload flow

### Week 4: Polish
1. Add animations
2. Add error handling
3. Add loading states
4. Test edge cases

## 💡 Pro Tips

### Performance
- Release camera session when not needed
- Use background queue for heavy operations
- Cancel ongoing operations when leaving screen
- Clean up temporary files

### UX
- Show clear progress indicators
- Provide cancel buttons
- Auto-save drafts
- Haptic feedback on interactions

### Error Handling
- Show user-friendly error messages
- Provide retry buttons
- Log errors for debugging
- Gracefully degrade features

## 📚 Next Steps

1. **Read IMPLEMENTATION_SUMMARY.md** - Full technical details
2. **Read README.md** - Complete documentation
3. **Implement views** - Create SwiftUI interfaces
4. **Test thoroughly** - Verify all flows work
5. **Deploy** - Ship to production!

## 🎉 Summary

You have **everything you need** for the backend:
- ✅ Camera recording (30s enforcement)
- ✅ Video trimming (validation)
- ✅ File upload (progress tracking)
- ✅ Thumbnail generation
- ✅ Permission management
- ✅ Error handling

**Just add UI and you're done!** 🚀

---

**Questions?** Check the README.md or IMPLEMENTATION_SUMMARY.md
