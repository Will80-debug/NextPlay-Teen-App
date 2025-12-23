//
//  CameraManager.swift
//  NextPlay
//
//  Camera capture and recording manager
//

import AVFoundation
import UIKit

enum CameraError: Error, LocalizedError {
    case setupFailed
    case recordingFailed
    case deviceNotAvailable
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .setupFailed: return "Failed to setup camera"
        case .recordingFailed: return "Failed to start recording"
        case .deviceNotAvailable: return "Camera device not available"
        case .permissionDenied: return "Camera permission denied"
        }
    }
}

enum CameraPosition {
    case front
    case back
}

enum FlashMode {
    case on
    case off
    case auto
}

class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRecording = false
    @Published var recordedDuration: Double = 0
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: FlashMode = .off
    @Published var isSessionRunning = false
    
    private let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentCamera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    
    private var recordingURL: URL?
    private var recordingStartTime: Date?
    private var durationTimer: Timer?
    
    private let maxRecordingDuration: Double = APIConfig.maxVideoDuration
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    
    // MARK: - Setup
    
    func setupCamera(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Configure session
                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .high
                
                // Setup video input
                try self.setupVideoInput(position: self.cameraPosition)
                
                // Setup audio input
                try self.setupAudioInput()
                
                // Setup video output
                self.setupVideoOutput()
                
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func setupVideoInput(position: CameraPosition) throws {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position == .back ? .back : .front
        )
        
        guard let camera = discoverySession.devices.first else {
            throw CameraError.deviceNotAvailable
        }
        
        let input = try AVCaptureDeviceInput(device: camera)
        
        if let currentInput = videoInput {
            captureSession.removeInput(currentInput)
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            videoInput = input
            currentCamera = camera
        } else {
            throw CameraError.setupFailed
        }
    }
    
    private func setupAudioInput() throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw CameraError.deviceNotAvailable
        }
        
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
    }
    
    private func setupVideoOutput() {
        let output = AVCaptureMovieFileOutput()
        output.movieFragmentInterval = .invalid
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
        }
    }
    
    // MARK: - Session Control
    
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self?.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let videoOutput = videoOutput else {
            completion(.failure(CameraError.recordingFailed))
            return
        }
        
        guard !videoOutput.isRecording else {
            completion(.failure(CameraError.recordingFailed))
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        recordingURL = outputURL
        recordingStartTime = Date()
        
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        // Start duration timer
        startDurationTimer()
        
        isRecording = true
        completion(.success(()))
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard let videoOutput = videoOutput, videoOutput.isRecording else {
            completion(nil)
            return
        }
        
        stopDurationTimer()
        videoOutput.stopRecording()
        isRecording = false
        
        // Completion will be called in delegate method
    }
    
    // MARK: - Duration Timer
    
    private func startDurationTimer() {
        recordedDuration = 0
        
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            self.recordedDuration = elapsed
            
            // Auto-stop at max duration
            if elapsed >= self.maxRecordingDuration {
                self.stopRecording { _ in }
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    // MARK: - Camera Controls
    
    func flipCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        
        captureSession.beginConfiguration()
        
        do {
            try setupVideoInput(position: cameraPosition)
        } catch {
            print("Error flipping camera: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
    
    func toggleFlash() {
        guard let device = currentCamera, device.hasFlash else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            switch flashMode {
            case .off:
                flashMode = .on
                device.torchMode = .on
            case .on:
                flashMode = .off
                device.torchMode = .off
            case .auto:
                flashMode = .off
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
    
    func setFlashMode(_ mode: FlashMode) {
        flashMode = mode
        
        guard let device = currentCamera, device.hasFlash else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            switch mode {
            case .on:
                device.torchMode = .on
            case .off:
                device.torchMode = .off
            case .auto:
                device.torchMode = .auto
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting flash mode: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopSession()
        stopDurationTimer()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("Recording error: \(error)")
            return
        }
        
        print("Recording finished: \(outputFileURL)")
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("Recording started: \(fileURL)")
    }
}
