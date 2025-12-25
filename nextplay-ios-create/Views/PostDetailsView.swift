//
//  PostDetailsView.swift
//  NextPlay
//
//  Screen for adding caption, hashtags, and category before posting
//

import SwiftUI

struct PostDetailsView: View {
    let videoURL: URL
    let coverImage: UIImage?
    let videoDuration: Double
    
    @StateObject private var viewModel: PostDetailsViewModel
    @StateObject private var uploadService = VideoUploadService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var caption = ""
    @State private var selectedCategory: VideoCategory = .comedy
    @State private var hashtagInput = ""
    @State private var showSuccess = false
    
    init(videoURL: URL, coverImage: UIImage?, videoDuration: Double) {
        self.videoURL = videoURL
        self.coverImage = coverImage
        self.videoDuration = videoDuration
        _viewModel = StateObject(wrappedValue: PostDetailsViewModel(
            videoURL: videoURL,
            coverImage: coverImage
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Cover Image Preview
                    coverPreview
                    
                    // Caption Field
                    captionField
                    
                    // Hashtag Suggestions
                    hashtagSection
                    
                    // Category Selection
                    categorySection
                    
                    // Post Button
                    postButton
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            
            // Upload Progress Overlay
            if uploadService.uploadState == .uploading || uploadService.uploadState == .preparing {
                uploadProgressOverlay
            }
            
            // Success Overlay
            if showSuccess {
                successOverlay
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Post Details")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Cover Preview
    private var coverPreview: some View {
        VStack(spacing: 12) {
            if let cover = coverImage {
                Image(uiImage: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "D4A574")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }
            
            Text("\(String(format: "%.1f", videoDuration))s video")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Caption Field
    private var captionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "D4A574"))
            
            TextEditor(text: $caption)
                .frame(height: 100)
                .padding(12)
                .background(Color(hex: "1A0A00"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "D4A574").opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Text("\(caption.count)/150 characters")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: - Hashtag Section
    private var hashtagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hashtags")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "D4A574"))
            
            // Suggested Hashtags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.suggestedHashtags, id: \.self) { tag in
                        Button(action: { addHashtag(tag) }) {
                            Text("#\(tag)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(
                                    viewModel.selectedHashtags.contains(tag)
                                        ? Color(hex: "1A0A00")
                                        : Color(hex: "FFD700")
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedHashtags.contains(tag)
                                        ? Color(hex: "FFD700")
                                        : Color(hex: "1A0A00")
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "FFD700"), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Selected Hashtags
            if !viewModel.selectedHashtags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.selectedHashtags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text("#\(tag)")
                                .font(.system(size: 14, weight: .medium))
                            
                            Button(action: { removeHashtag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "D4A574").opacity(0.3))
                        .cornerRadius(15)
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "D4A574"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VideoCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Post Button
    private var postButton: some View {
        Button(action: { postVideo() }) {
            HStack {
                if uploadService.uploadState == .preparing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                }
                
                Text("Post")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(hex: "B91C1C"), Color(hex: "7F1D1D")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(27)
            .shadow(color: Color(hex: "B91C1C").opacity(0.4), radius: 15, y: 5)
        }
        .disabled(caption.isEmpty || uploadService.uploadState != .idle)
        .opacity(caption.isEmpty ? 0.5 : 1)
    }
    
    // MARK: - Upload Progress Overlay
    private var uploadProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: uploadService.uploadProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "D4A574")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: uploadService.uploadProgress)
                    
                    Text("\(Int(uploadService.uploadProgress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(uploadStateMessage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Please don't close the app")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "FFD700"))
                
                Text("Posted Successfully!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your video is now live")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color(hex: "FFD700"))
                        .cornerRadius(25)
                }
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Helper Functions
    private var uploadStateMessage: String {
        switch uploadService.uploadState {
        case .preparing:
            return "Preparing..."
        case .uploading:
            return "Uploading..."
        default:
            return "Processing..."
        }
    }
    
    private func addHashtag(_ tag: String) {
        if viewModel.selectedHashtags.contains(tag) {
            viewModel.selectedHashtags.removeAll { $0 == tag }
        } else if viewModel.selectedHashtags.count < 5 {
            viewModel.selectedHashtags.append(tag)
        }
    }
    
    private func removeHashtag(_ tag: String) {
        viewModel.selectedHashtags.removeAll { $0 == tag }
    }
    
    private func postVideo() {
        guard let coverImage = coverImage else { return }
        
        let metadata = VideoMetadata(
            caption: caption,
            hashtags: viewModel.selectedHashtags,
            category: selectedCategory
        )
        
        Task {
            do {
                let _ = try await uploadService.uploadVideo(
                    videoURL: videoURL,
                    thumbnail: coverImage,
                    metadata: metadata,
                    userId: "current_user_id" // TODO: Get from auth
                )
                
                showSuccess = true
                
                // Dismiss after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
                
            } catch {
                print("Upload failed: \(error)")
            }
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: VideoCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.system(size: 32))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: "1A0A00") : .white)
            }
            .frame(width: 100, height: 100)
            .background(
                isSelected
                    ? Color(hex: "FFD700")
                    : Color(hex: "1A0A00")
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected
                            ? Color(hex: "FFD700")
                            : Color(hex: "D4A574").opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - ViewModel
class PostDetailsViewModel: ObservableObject {
    @Published var selectedHashtags: [String] = []
    @Published var suggestedHashtags: [String] = [
        "fyp", "viral", "trending", "nextplay", "creative",
        "talent", "fun", "challenge", "amazing", "awesome"
    ]
    
    let videoURL: URL
    let coverImage: UIImage?
    
    init(videoURL: URL, coverImage: UIImage?) {
        self.videoURL = videoURL
        self.coverImage = coverImage
    }
}

#Preview {
    PostDetailsView(
        videoURL: URL(fileURLWithPath: "/tmp/test.mp4"),
        coverImage: nil,
        videoDuration: 15.5
    )
}
