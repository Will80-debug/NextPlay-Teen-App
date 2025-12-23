//
//  UploadService.swift
//  NextPlay
//
//  Video upload service with progress tracking
//

import Foundation

enum UploadError: Error {
    case initializationFailed
    case uploadFailed
    case thumbnailUploadFailed
    case publishFailed
    case networkError(Error)
}

class UploadService: NSObject, ObservableObject {
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    
    private var uploadTask: URLSessionUploadTask?
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Upload Flow
    
    func upload(
        videoURL: URL,
        thumbnail: Data,
        userId: String,
        caption: String,
        hashtags: [String],
        category: String,
        completion: @escaping (Result<VideoPost, Error>) -> Void
    ) {
        isUploading = true
        uploadProgress = 0
        
        // Step 1: Initialize upload
        initializeUpload(userId: userId, videoURL: videoURL) { [weak self] result in
            switch result {
            case .success(let response):
                // Step 2: Upload video
                self?.uploadVideo(videoURL: videoURL, to: response.uploadUrl) { uploadResult in
                    switch uploadResult {
                    case .success:
                        // Step 3: Upload thumbnail
                        self?.uploadThumbnail(thumbnail, videoId: response.videoId) { thumbResult in
                            switch thumbResult {
                            case .success:
                                // Step 4: Publish
                                self?.publish(
                                    videoId: response.videoId,
                                    caption: caption,
                                    hashtags: hashtags,
                                    category: category,
                                    completion: completion
                                )
                            case .failure(let error):
                                self?.isUploading = false
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        self?.isUploading = false
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                self?.isUploading = false
                completion(.failure(error))
            }
        }
    }
    
    private func initializeUpload(
        userId: String,
        videoURL: URL,
        completion: @escaping (Result<UploadInitResponse, Error>) -> Void
    ) {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        let request = CreateUploadRequest(
            userId: userId,
            durationSeconds: duration,
            createdAt: Date()
        )
        
        guard let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.videosInit)") else {
            completion(.failure(UploadError.initializationFailed))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(UploadError.initializationFailed))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(UploadInitResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func uploadVideo(
        videoURL: URL,
        to uploadURL: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: uploadURL) else {
            completion(.failure(UploadError.uploadFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        
        uploadTask = session.uploadTask(with: request, fromFile: videoURL) { data, response, error in
            DispatchQueue.main.async {
                self.isUploading = false
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
        
        uploadTask?.resume()
    }
    
    private func uploadThumbnail(
        _ thumbnailData: Data,
        videoId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let endpoint = APIConfig.videosThumbnail(videoId: videoId)
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            completion(.failure(UploadError.thumbnailUploadFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"thumbnail\"; filename=\"thumb.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(thumbnailData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }.resume()
    }
    
    private func publish(
        videoId: String,
        caption: String,
        hashtags: [String],
        category: String,
        completion: @escaping (Result<VideoPost, Error>) -> Void
    ) {
        let endpoint = APIConfig.videosPublish(videoId: videoId)
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            completion(.failure(UploadError.publishFailed))
            return
        }
        
        let request = PublishRequest(caption: caption, hashtags: hashtags, category: category)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(UploadError.publishFailed))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(PublishResponse.self, from: data)
                if let feedItem = response.feedItem {
                    completion(.success(feedItem))
                } else {
                    completion(.failure(UploadError.publishFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func cancelUpload() {
        uploadTask?.cancel()
        isUploading = false
    }
}

extension UploadService: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.uploadProgress = progress
        }
    }
}
