//
//  PermissionsManager.swift
//  NextPlay
//
//  Permission request and management
//

import AVFoundation
import Photos
import UIKit

enum PermissionType {
    case camera
    case microphone
    case photoLibrary
}

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

class PermissionsManager {
    static let shared = PermissionsManager()
    
    private init() {}
    
    // MARK: - Camera Permission
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func cameraPermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return convertAVStatus(status)
    }
    
    // MARK: - Microphone Permission
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func microphonePermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return convertAVStatus(status)
    }
    
    // MARK: - Photo Library Permission
    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func photoLibraryPermissionStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        return convertPhotoStatus(status)
    }
    
    // MARK: - Check All Required Permissions
    
    func checkAllPermissions() -> [PermissionType: PermissionStatus] {
        return [
            .camera: cameraPermissionStatus(),
            .microphone: microphonePermissionStatus(),
            .photoLibrary: photoLibraryPermissionStatus()
        ]
    }
    
    func hasAllRequiredPermissions() -> Bool {
        return cameraPermissionStatus() == .authorized &&
               microphonePermissionStatus() == .authorized
    }
    
    // MARK: - Open Settings
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Helper Methods
    
    private func convertAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    private func convertPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
}
