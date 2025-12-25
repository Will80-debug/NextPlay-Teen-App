//
//  CreateCameraView.swift
//  NextPlay
//
//  Camera view for recording videos with NextPlay styling
//

import SwiftUI
import AVFoundation

struct CreateCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel = CreateCameraViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var showLibraryPicker = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Overlay Controls
            VStack {
                // Top Controls
                topControls
                
                Spacer()
                
                // Recording Timer
                if cameraManager.isRecording {
                    recordingTimer
                }
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .task {
            await setupCamera()
        }
        .onDisappear {
            cameraManager.cleanup()
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionMessage)
        }
        .fullScreenCover(isPresented: $showLibraryPicker) {
            PhotoLibraryPicker { url in
                viewModel.handleSelectedVideo(url: url)
            }
        }
        .fullScreenCover(item: $viewModel.recordedVideoURL) { url in
            TrimPreviewView(videoURL: url)
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        HStack {
            // Close Button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                    )
            }
            
            Spacer()
            
            // Flash Button
            if cameraManager.currentCamera?.hasFlash == true {
                Button(action: { cameraManager.toggleFlash() }) {
                    Image(systemName: flashIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(cameraManager.flashMode == .off ? .white : .yellow)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                        )
                }
            }
            
            // Speed Control
            Button(action: { cameraManager.cycleRecordingSpeed() }) {
                Text(cameraManager.recordingSpeed.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 44)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
            }
        }
    }
    
    // MARK: - Recording Timer
    private var recordingTimer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(cameraManager.isRecording ? 1 : 0)
            
            Text(formatTime(cameraManager.recordingDuration))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Library Button
            Button(action: { showLibraryPicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }
            .disabled(cameraManager.isRecording)
            .opacity(cameraManager.isRecording ? 0.5 : 1)
            
            // Record Button
            recordButton
            
            // Flip Camera Button
            Button(action: { cameraManager.flipCamera() }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }
            .disabled(cameraManager.isRecording)
            .opacity(cameraManager.isRecording ? 0.5 : 1)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Record Button
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Outer gold ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "D4A574")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 80, height: 80)
                
                // Inner red circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: cameraManager.isRecording
                                ? [Color.red.opacity(0.8), Color.red]
                                : [Color(hex: "B91C1C"), Color(hex: "7F1D1D")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: cameraManager.isRecording ? 40 : 65,
                        height: cameraManager.isRecording ? 40 : 65
                    )
                    .cornerRadius(cameraManager.isRecording ? 8 : 40)
                
                // Recording pulse
                if cameraManager.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 15)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cameraManager.isRecording)
    }
    
    // MARK: - Helpers
    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let remaining = max(0, CameraManager.maxRecordingDuration - seconds)
        let minutes = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func toggleRecording() {
        if cameraManager.isRecording {
            cameraManager.stopRecording()
        } else {
            cameraManager.startRecording()
        }
    }
    
    private func setupCamera() async {
        do {
            try await cameraManager.setupCamera()
            cameraManager.startSession()
        } catch let error as CameraManager.CameraError {
            permissionMessage = error.localizedDescription
            showPermissionAlert = true
        } catch {
            permissionMessage = "Failed to setup camera"
            showPermissionAlert = true
        }
    }
}

// MARK: - Camera Preview View (UIKit Bridge)
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        if let previewLayer = cameraManager.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - ViewModel
class CreateCameraViewModel: ObservableObject {
    @Published var recordedVideoURL: URL?
    
    func handleSelectedVideo(url: URL) {
        // Check if video needs trimming
        Task {
            let asset = AVAsset(url: url)
            let needsTrim = await VideoTrimmer.needsTrimming(asset)
            
            DispatchQueue.main.async {
                self.recordedVideoURL = url
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    CreateCameraView()
}
