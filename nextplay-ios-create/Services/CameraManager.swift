//
//  CameraManager.swift
//  NextPlay
//
//  Manages camera capture and video recording using AVFoundation
//

import AVFoundation
import UIKit
import Combine

/// Manages camera capture session and video recording
class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: CameraError?
    @Published var recordedVideoURL: URL?
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var recordingSpeed: RecordingSpeed = .normal
    
    // MARK: - Constants
    static let maxRecordingDuration: TimeInterval = 30.0
    private let sessionQueue = DispatchQueue(label: "com.nextplay.camera.session")
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordingTimer: Timer?
    private var currentCamera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    
    // MARK: - Enums
    enum RecordingSpeed: Double, CaseIterable {
        case slow = 0.5
        case normal = 1.0
        case fast = 1.5
        
        var displayName: String {
            switch self {
            case .slow: return "0.5x"
            case .normal: return "1x"
            case .fast: return "1.5x"
            }
        }
    }
    
    enum CameraError: LocalizedError {
        case cameraUnavailable
        case microphoneUnavailable
        case setupFailed
        case recordingFailed
        case permissionDenied(String)
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is not available"
            case .microphoneUnavailable:
                return "Microphone is not available"
            case .setupFailed:
                return "Failed to setup camera"
            case .recordingFailed:
                return "Failed to record video"
            case .permissionDenied(let permission):
                return "\(permission) permission is required"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Setup
    func setupCamera() async throws {
        // Check permissions first
        let cameraStatus = await checkCameraPermission()
        guard cameraStatus else {
            throw CameraError.permissionDenied("Camera")
        }
        
        let micStatus = await checkMicrophonePermission()
        guard micStatus else {
            throw CameraError.permissionDenied("Microphone")
        }
        
        // Setup capture session
        try await sessionQueue.sync {
            try self.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Set session preset
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        // Setup video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: cameraPosition) else {
            throw CameraError.cameraUnavailable
        }
        
        currentCamera = camera
        let videoInput = try AVCaptureDeviceInput(device: camera)
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            self.videoInput = videoInput
        } else {
            throw CameraError.setupFailed
        }
        
        // Setup audio input
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            throw CameraError.microphoneUnavailable
        }
        
        let audioInput = try AVCaptureDeviceInput(device: microphone)
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
            self.audioInput = audioInput
        }
        
        // Setup video output
        let videoOutput = AVCaptureMovieFileOutput()
        
        // Set max recording duration
        videoOutput.maxRecordedDuration = CMTime(seconds: Self.maxRecordingDuration,
                                                 preferredTimescale: 600)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        } else {
            throw CameraError.setupFailed
        }
        
        session.commitConfiguration()
        self.captureSession = session
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Preview Layer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        return previewLayer
    }
    
    // MARK: - Recording
    func startRecording() {
        guard let videoOutput = videoOutput, !videoOutput.isRecording else { return }
        
        // Create temporary file URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        // Start recording
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        // Start timer
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            
            // Auto-stop at max duration
            if self.recordingDuration >= Self.maxRecordingDuration {
                self.stopRecording()
            }
        }
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        guard let videoOutput = videoOutput, videoOutput.isRecording else { return }
        
        videoOutput.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    // MARK: - Camera Controls
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let session = self.captureSession,
                  let currentInput = self.videoInput else { return }
            
            session.beginConfiguration()
            session.removeInput(currentInput)
            
            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .front : .back
            
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                         for: .video,
                                                         position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                session.addInput(currentInput)
                session.commitConfiguration()
                return
            }
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                self.videoInput = newInput
                self.currentCamera = newCamera
                
                DispatchQueue.main.async {
                    self.cameraPosition = newPosition
                }
            } else {
                session.addInput(currentInput)
            }
            
            session.commitConfiguration()
        }
    }
    
    func toggleFlash() {
        guard let camera = currentCamera, camera.hasFlash else { return }
        
        do {
            try camera.lockForConfiguration()
            
            switch flashMode {
            case .off:
                camera.flashMode = .on
                flashMode = .on
            case .on:
                camera.flashMode = .auto
                flashMode = .auto
            case .auto:
                camera.flashMode = .off
                flashMode = .off
            @unknown default:
                camera.flashMode = .off
                flashMode = .off
            }
            
            camera.unlockForConfiguration()
        } catch {
            print("Failed to toggle flash: \(error)")
        }
    }
    
    func cycleRecordingSpeed() {
        let allSpeeds = RecordingSpeed.allCases
        if let currentIndex = allSpeeds.firstIndex(of: recordingSpeed) {
            let nextIndex = (currentIndex + 1) % allSpeeds.count
            recordingSpeed = allSpeeds[nextIndex]
        }
    }
    
    // MARK: - Permissions
    private func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    private func checkMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopRecording()
        stopSession()
        captureSession = nil
        videoOutput = nil
        previewLayer = nil
        currentCamera = nil
        videoInput = nil
        audioInput = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                   didFinishRecordingTo outputFileURL: URL,
                   from connections: [AVCaptureConnection],
                   error: Error?) {
        
        if let error = error {
            print("Recording error: \(error)")
            DispatchQueue.main.async {
                self.error = .recordingFailed
            }
            return
        }
        
        DispatchQueue.main.async {
            self.recordedVideoURL = outputFileURL
        }
    }
}
