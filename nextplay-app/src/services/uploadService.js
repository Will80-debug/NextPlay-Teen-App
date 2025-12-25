// Upload Service for NextPlay
// Handles video upload to backend with S3 presigned URLs

class UploadService {
  constructor() {
    this.apiBase = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';
  }

  // Analytics tracking (first-party only, no ad IDs)
  trackEvent(eventName, metadata = {}) {
    const event = {
      event: eventName,
      timestamp: new Date().toISOString(),
      userId: this.getUserId(),
      ...metadata
    };
    
    console.log('📊 Analytics:', event);
    
    // Store locally and send to first-party analytics
    const events = JSON.parse(localStorage.getItem('nextplay_analytics') || '[]');
    events.push(event);
    localStorage.setItem('nextplay_analytics', JSON.stringify(events.slice(-100))); // Keep last 100
    
    // Send to backend analytics endpoint (first-party)
    fetch(`${this.apiBase}/analytics/track`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(event)
    }).catch(err => console.error('Analytics send failed:', err));
  }

  getUserId() {
    // Get current user ID from session
    const user = JSON.parse(sessionStorage.getItem('nextplay_user') || '{}');
    return user.id || 'anonymous';
  }

  // Validate video duration on client side
  async validateVideoDuration(file) {
    return new Promise((resolve, reject) => {
      const video = document.createElement('video');
      video.preload = 'metadata';
      
      video.onloadedmetadata = () => {
        window.URL.revokeObjectURL(video.src);
        const duration = video.duration;
        
        if (duration > 30.0) {
          reject(new Error(`Video is ${duration.toFixed(1)}s long. Maximum allowed is 30.0s. Please trim the video.`));
        } else {
          resolve(duration);
        }
      };
      
      video.onerror = () => {
        reject(new Error('Failed to load video file'));
      };
      
      video.src = URL.createObjectURL(file);
    });
  }

  // Step 1: Create upload session
  async createUploadSession(metadata) {
    this.trackEvent('upload_started', {
      category: metadata.category,
      hasTags: metadata.tags?.length > 0
    });

    const response = await fetch(`${this.apiBase}/videos/upload-session`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.getAuthToken()}`
      },
      body: JSON.stringify({
        title: metadata.title,
        category: metadata.category,
        tags: metadata.tags || [],
        visibility: metadata.visibility || 'public',
        duration: metadata.duration
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to create upload session');
    }

    return response.json();
  }

  // Step 2: Upload video to S3 presigned URL
  async uploadToS3(presignedUrl, file, onProgress) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100;
          onProgress(percentComplete);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) {
          resolve();
        } else {
          reject(new Error(`Upload failed with status ${xhr.status}`));
        }
      });

      xhr.addEventListener('error', () => {
        reject(new Error('Network error during upload'));
      });

      xhr.open('PUT', presignedUrl);
      xhr.setRequestHeader('Content-Type', file.type);
      xhr.send(file);
    });
  }

  // Step 3: Upload thumbnail
  async uploadThumbnail(videoId, thumbnailBlob) {
    const formData = new FormData();
    formData.append('thumbnail', thumbnailBlob, 'thumbnail.jpg');

    const response = await fetch(`${this.apiBase}/videos/${videoId}/thumbnail`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.getAuthToken()}`
      },
      body: formData
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to upload thumbnail');
    }

    return response.json();
  }

  // Step 4: Complete upload and start processing
  async completeUpload(sessionId) {
    const response = await fetch(`${this.apiBase}/videos/upload-session/${sessionId}/complete`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.getAuthToken()}`
      }
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to complete upload');
    }

    this.trackEvent('upload_completed', { sessionId });
    return response.json();
  }

  // Publish video (makes it visible in feed)
  async publishVideo(videoId) {
    this.trackEvent('publish_tapped', { videoId });

    const response = await fetch(`${this.apiBase}/videos/${videoId}/publish`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.getAuthToken()}`
      }
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to publish video');
    }

    this.trackEvent('publish_completed', { videoId });
    return response.json();
  }

  // Check processing status
  async checkProcessingStatus(videoId) {
    const response = await fetch(`${this.apiBase}/videos/${videoId}/status`, {
      headers: {
        'Authorization': `Bearer ${this.getAuthToken()}`
      }
    });

    if (!response.ok) {
      throw new Error('Failed to check processing status');
    }

    return response.json();
  }

  getAuthToken() {
    return sessionStorage.getItem('nextplay_token') || '';
  }

  // Full upload flow
  async uploadVideo(file, metadata, onProgress) {
    try {
      // Client-side duration validation
      const duration = await this.validateVideoDuration(file);
      metadata.duration = duration;

      // Create session
      const session = await this.createUploadSession(metadata);

      // Upload video to S3 (progress 0-80%)
      await this.uploadToS3(session.uploadUrl, file, (progress) => {
        onProgress(progress * 0.8); // Scale to 80%
      });

      // Upload thumbnail if provided (progress 80-90%)
      if (metadata.coverFrame) {
        onProgress(85);
        await this.uploadThumbnail(session.videoId, metadata.coverFrame);
        onProgress(90);
      }

      // Complete upload (progress 90-100%)
      onProgress(95);
      const result = await this.completeUpload(session.sessionId);
      onProgress(100);

      return result;
    } catch (error) {
      this.trackEvent('upload_failed', { error: error.message });
      throw error;
    }
  }
}

export default new UploadService();
