//
//  TrimPreviewView.swift
//  NextPlay
//
//  Video trim and preview screen with timeline slider
//

import SwiftUI
import AVFoundation
import AVKit

struct TrimPreviewView: View {
    let videoURL: URL
    
    @StateObject private var viewModel: TrimPreviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPostDetails = false
    @State private var isSoundOn = true
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        _viewModel = StateObject(wrappedValue: TrimPreviewViewModel(videoURL: videoURL))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Video Player
                videoPlayer
                    .frame(maxHeight: .infinity)
                
                // Controls
                controlsSection
            }
            
            // Loading Overlay
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadVideo()
        }
        .fullScreenCover(isPresented: $showPostDetails) {
            if let trimmedURL = viewModel.trimmedVideoURL {
                PostDetailsView(
                    videoURL: trimmedURL,
                    coverImage: viewModel.selectedCoverFrame,
                    videoDuration: viewModel.trimEnd - viewModel.trimStart
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Edit Video")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: proceedToPostDetails) {
                Text("Next")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            .disabled(viewModel.isProcessing)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Video Player
    private var videoPlayer: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .aspectRatio(contentMode: .fit)
                        .disabled(true) // Disable default controls
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                // Play/Pause Overlay
                if !viewModel.isPlaying {
                    Button(action: { viewModel.togglePlayback() }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black)
            .onTapGesture {
                viewModel.togglePlayback()
            }
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Timeline Slider
            timelineSection
            
            // Control Buttons
            HStack(spacing: 30) {
                // Sound Toggle
                Button(action: { toggleSound() }) {
                    VStack(spacing: 8) {
                        Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 24))
                        Text(isSoundOn ? "Sound On" : "Sound Off")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(isSoundOn ? Color(hex: "FFD700") : .gray)
                }
                
                // Cover Frame
                Button(action: { /* Open cover picker */ }) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                        Text("Cover")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                }
                
                // Duration Info
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                    Text(formatDuration(viewModel.trimEnd - viewModel.trimStart))
                        .font(.system(size: 12))
                }
                .foregroundColor(viewModel.trimEnd - viewModel.trimStart <= 30 ? .white : .red)
            }
            .padding(.vertical)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A0A00").opacity(0.95),
                    Color.black.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(spacing: 12) {
            // Thumbnail Timeline
            thumbnailTimeline
            
            // Trim Controls
            HStack {
                Text(formatTime(viewModel.trimStart))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "D4A574"))
                
                Spacer()
                
                Text("Trim to 30s max")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formatTime(viewModel.trimEnd))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "D4A574"))
            }
            
            // Trim Sliders
            VStack(spacing: 8) {
                // Start Time
                HStack {
                    Text("Start")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .leading)
                    
                    Slider(
                        value: $viewModel.trimStart,
                        in: 0...min(viewModel.videoDuration, viewModel.trimEnd - 0.1)
                    )
                    .accentColor(Color(hex: "FFD700"))
                }
                
                // End Time
                HStack {
                    Text("End")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .leading)
                    
                    Slider(
                        value: $viewModel.trimEnd,
                        in: max(0, viewModel.trimStart + 0.1)...min(viewModel.videoDuration, viewModel.trimStart + 30)
                    )
                    .accentColor(Color(hex: "FFD700"))
                }
            }
        }
    }
    
    // MARK: - Thumbnail Timeline
    private var thumbnailTimeline: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(viewModel.thumbnails.enumerated()), id: \.offset) { index, thumbnail in
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 70)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .stroke(Color(hex: "FFD700"), lineWidth: 2)
                                .opacity(isInTrimRange(index: index) ? 1 : 0)
                        )
                }
            }
        }
        .frame(height: 70)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "FFD700"))
                
                Text("Processing video...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        return String(format: "%.1fs", seconds)
    }
    
    private func isInTrimRange(index: Int) -> Bool {
        let thumbnailCount = Double(viewModel.thumbnails.count)
        let timePerThumbnail = viewModel.videoDuration / thumbnailCount
        let thumbnailTime = Double(index) * timePerThumbnail
        
        return thumbnailTime >= viewModel.trimStart && thumbnailTime <= viewModel.trimEnd
    }
    
    private func toggleSound() {
        isSoundOn.toggle()
        viewModel.player?.isMuted = !isSoundOn
    }
    
    private func proceedToPostDetails() {
        Task {
            await viewModel.exportTrimmedVideo()
            if viewModel.trimmedVideoURL != nil {
                showPostDetails = true
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class TrimPreviewViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var videoDuration: Double = 0
    @Published var trimStart: Double = 0
    @Published var trimEnd: Double = 30
    @Published var thumbnails: [UIImage] = []
    @Published var selectedCoverFrame: UIImage?
    @Published var isProcessing = false
    @Published var error: Error?
    @Published var trimmedVideoURL: URL?
    
    private let videoURL: URL
    private var timeObserver: Any?
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    func loadVideo() async {
        let asset = AVAsset(url: videoURL)
        
        do {
            // Get duration
            let duration = try await VideoTrimmer.getDuration(asset)
            videoDuration = duration
            trimEnd = min(duration, 30.0)
            
            // Setup player
            let playerItem = AVPlayerItem(url: videoURL)
            player = AVPlayer(playerItem: playerItem)
            
            // Generate thumbnails
            let thumbs = try await VideoTrimmer.generateThumbnails(from: asset, count: 10)
            thumbnails = thumbs
            
            // Set initial cover frame
            if let firstThumb = thumbs.first {
                selectedCoverFrame = firstThumb
            }
            
            // Add time observer
            addTimeObserver()
            
        } catch {
            self.error = error
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func exportTrimmedVideo() async {
        isProcessing = true
        
        do {
            let asset = AVAsset(url: videoURL)
            
            let outputURL = try await VideoTrimmer.trimVideo(
                asset: asset,
                startTime: trimStart,
                endTime: trimEnd
            )
            
            trimmedVideoURL = outputURL
            
            // Generate cover frame at selected time
            let coverTime = (trimStart + trimEnd) / 2
            selectedCoverFrame = try await VideoTrimmer.generateThumbnail(
                from: asset,
                at: coverTime
            )
            
        } catch {
            self.error = error
        }
        
        isProcessing = false
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = CMTimeGetSeconds(time)
            
            // Loop within trim range
            if currentTime >= self.trimEnd {
                self.player?.seek(to: CMTime(seconds: self.trimStart, preferredTimescale: 600))
            }
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

#Preview {
    TrimPreviewView(videoURL: URL(fileURLWithPath: "/tmp/test.mov"))
}
