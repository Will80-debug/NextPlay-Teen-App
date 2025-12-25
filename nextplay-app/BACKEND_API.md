# NextPlay Record/Upload API Documentation

## Overview

This document describes the backend API endpoints required for the NextPlay video upload feature.

## Base URL

```
Production: https://api.nextplay.com/api
Development: http://localhost:3001/api
```

## Authentication

All requests require Bearer token authentication:

```
Authorization: Bearer {token}
```

## Endpoints

### 1. Create Upload Session

**POST** `/videos/upload-session`

Creates a new upload session and returns a pre-signed S3 URL for direct upload.

**Request Body:**

```json
{
  "title": "My awesome video",
  "category": "sports",
  "tags": ["skateboarding", "tricks"],
  "visibility": "public",
  "duration": 15.5
}
```

**Validation:**
- `title`: Required, max 80 characters
- `category`: Required, one of: sports, dance, art, comedy, stem, gaming, music, fitness
- `tags`: Optional, max 5 tags
- `visibility`: Required, one of: public, private
- `duration`: Required, must be <= 30.0 seconds

**Response (200 OK):**

```json
{
  "sessionId": "session_abc123",
  "videoId": "video_xyz789",
  "uploadUrl": "https://s3.amazonaws.com/nextplay-videos/...?signature=...",
  "expiresAt": "2025-12-24T12:00:00Z"
}
```

**Error Responses:**

```json
// 400 Bad Request - Duration too long
{
  "error": "DURATION_TOO_LONG",
  "message": "Video duration must be 30 seconds or less"
}

// 401 Unauthorized
{
  "error": "UNAUTHORIZED",
  "message": "Invalid or missing authentication token"
}
```

---

### 2. Upload Thumbnail

**POST** `/videos/{videoId}/thumbnail`

Uploads a custom cover frame/thumbnail for the video.

**Request:**
- Content-Type: `multipart/form-data`
- Body: Form data with `thumbnail` field containing JPEG/PNG image

**Example:**

```bash
curl -X POST http://localhost:3001/api/videos/{videoId}/thumbnail \
  -H "Authorization: Bearer token" \
  -F "thumbnail=@cover.jpg"
```

**Response (200 OK):**

```json
{
  "success": true,
  "thumbnailUrl": "https://cdn.nextplay.com/thumbnails/video_xyz789.jpg"
}
```

**Error Responses:**

```json
// 400 Bad Request - Invalid file
{
  "error": "INVALID_FILE",
  "message": "Thumbnail must be JPEG or PNG"
}

// 413 Payload Too Large
{
  "error": "FILE_TOO_LARGE",
  "message": "Thumbnail file size must be under 5MB"
}
```

---

### 3. Complete Upload

**POST** `/videos/upload-session/{sessionId}/complete`

Marks the upload as complete and starts video processing (transcoding, thumbnail generation).

**Response (200 OK):**

```json
{
  "videoId": "video_xyz789",
  "state": "processing",
  "message": "Video is being processed"
}
```

**Error Responses:**

```json
// 404 Not Found
{
  "error": "SESSION_NOT_FOUND",
  "message": "Upload session not found"
}

// 400 Bad Request
{
  "error": "NO_FILE_UPLOADED",
  "message": "No video file was uploaded to S3"
}
```

---

### 4. Check Processing Status

**GET** `/videos/{videoId}/status`

Checks the current processing state of an uploaded video.

**Response (200 OK):**

```json
{
  "videoId": "video_xyz789",
  "state": "processing",
  "progress": 65,
  "message": "Transcoding video"
}
```

**Possible States:**
- `processing`: Video is being transcoded
- `completed`: Video is ready
- `failed`: Processing failed

**When Completed:**

```json
{
  "videoId": "video_xyz789",
  "state": "completed",
  "videoUrl": "https://cdn.nextplay.com/videos/video_xyz789.mp4",
  "thumbnailUrl": "https://cdn.nextplay.com/thumbnails/video_xyz789.jpg",
  "variants": {
    "720p": "https://cdn.nextplay.com/videos/video_xyz789_720p.mp4",
    "480p": "https://cdn.nextplay.com/videos/video_xyz789_480p.mp4",
    "360p": "https://cdn.nextplay.com/videos/video_xyz789_360p.mp4"
  }
}
```

---

### 5. Publish Video

**POST** `/videos/{videoId}/publish`

Publishes the video to the user's feed (makes it visible to others based on visibility setting).

**Response (200 OK):**

```json
{
  "success": true,
  "video": {
    "id": "video_xyz789",
    "title": "My awesome video",
    "category": "sports",
    "tags": ["skateboarding", "tricks"],
    "visibility": "public",
    "videoUrl": "https://cdn.nextplay.com/videos/video_xyz789.mp4",
    "thumbnailUrl": "https://cdn.nextplay.com/thumbnails/video_xyz789.jpg",
    "duration": 15.5,
    "views": 0,
    "likes": 0,
    "createdAt": "2025-12-24T12:00:00Z"
  }
}
```

---

### 6. Analytics Tracking

**POST** `/analytics/track`

Receives first-party analytics events (no ad IDs, no third-party tracking).

**Request Body:**

```json
{
  "event": "record_started",
  "timestamp": "2025-12-24T12:00:00Z",
  "userId": "user_123",
  "metadata": {
    "category": "sports",
    "hasTags": true
  }
}
```

**Events Tracked:**
- `record_started`: User started camera recording
- `upload_started`: User started uploading video
- `upload_completed`: Upload finished successfully
- `upload_failed`: Upload failed
- `publish_tapped`: User clicked publish button
- `publish_completed`: Video published successfully

**Response (200 OK):**

```json
{
  "success": true
}
```

---

## Server-Side Duration Validation

**CRITICAL:** The backend MUST validate video duration after upload:

```python
# Pseudo-code for backend validation
def validate_uploaded_video(file_path):
    duration = get_video_duration(file_path)
    
    if duration > 30.0:
        delete_file(file_path)
        raise ValidationError(
            f"Video duration ({duration}s) exceeds 30 second limit"
        )
    
    return duration
```

If a video exceeds 30 seconds, the backend should:
1. Delete the uploaded file
2. Mark the upload session as failed
3. Return an error response
4. NOT process or publish the video

---

## S3 Pre-Signed URL Generation

The backend should generate pre-signed URLs with:

- **Expiration**: 15 minutes
- **Permissions**: PUT only
- **Max File Size**: 100MB
- **Content-Type**: video/webm, video/mp4, video/quicktime

Example (Node.js with AWS SDK):

```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

function generatePresignedUrl(videoId) {
  const key = `uploads/${videoId}/original.webm`;
  
  return s3.getSignedUrl('putObject', {
    Bucket: 'nextplay-videos',
    Key: key,
    Expires: 900, // 15 minutes
    ContentType: 'video/webm'
  });
}
```

---

## Video Processing Pipeline

After upload completion, the backend should:

1. **Validate Duration**: Reject if > 30 seconds
2. **Generate Thumbnail**: Extract frame at 1 second
3. **Transcode**: Create multiple resolutions (720p, 480p, 360p)
4. **Content Moderation**: Run automated checks (optional AI moderation)
5. **Update Status**: Mark as completed or failed
6. **Notify Client**: If using webhooks or polling

---

## Safety & Privacy Requirements

### No Location Collection
- Do NOT collect GPS coordinates
- Do NOT store device location
- Do NOT request location permissions

### No DOB Display
- Store only age band (13-15, 16-17, 18+)
- Never display exact birth date
- Use age verification from gate flow

### No Direct Messages from Upload
- Upload flow is one-way (user → platform)
- No DM features on this screen
- No user-to-user communication

### Content Moderation
- All videos go through processing/review
- Flag inappropriate content before publishing
- Apply age-appropriate filters

---

## Error Handling

### Network Failures

```json
{
  "error": "NETWORK_ERROR",
  "message": "Failed to upload video. Please check your connection.",
  "retryable": true
}
```

### Processing Failures

```json
{
  "error": "PROCESSING_FAILED",
  "message": "Failed to process video. Please try again.",
  "retryable": true
}
```

### Duration Exceeded (Server-Side)

```json
{
  "error": "DURATION_EXCEEDED",
  "message": "Video duration exceeds 30 second limit",
  "actualDuration": 35.5,
  "maxDuration": 30.0
}
```

---

## Rate Limiting

Recommended rate limits:
- Upload sessions: 10 per hour per user
- Processing check: 60 per minute per user
- Analytics: 100 per minute per user

---

## Database Schema (Reference)

```sql
CREATE TABLE videos (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  title VARCHAR(80) NOT NULL,
  category VARCHAR(50) NOT NULL,
  tags JSON,
  visibility VARCHAR(20) NOT NULL,
  duration DECIMAL(5,2) NOT NULL,
  video_url TEXT,
  thumbnail_url TEXT,
  state VARCHAR(20) NOT NULL,
  views INT DEFAULT 0,
  likes INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP,
  published_at TIMESTAMP,
  
  CONSTRAINT duration_limit CHECK (duration <= 30.0),
  CONSTRAINT valid_category CHECK (category IN ('sports', 'dance', 'art', 'comedy', 'stem', 'gaming', 'music', 'fitness')),
  CONSTRAINT valid_visibility CHECK (visibility IN ('public', 'private'))
);

CREATE TABLE upload_sessions (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  video_id VARCHAR(255) NOT NULL,
  upload_url TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE analytics_events (
  id SERIAL PRIMARY KEY,
  event VARCHAR(100) NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  metadata JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Testing

### Test Upload Flow

```bash
# 1. Create session
curl -X POST http://localhost:3001/api/videos/upload-session \
  -H "Authorization: Bearer test_token" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Video",
    "category": "sports",
    "tags": ["test"],
    "visibility": "public",
    "duration": 10.5
  }'

# 2. Upload video to presigned URL
curl -X PUT "$PRESIGNED_URL" \
  -H "Content-Type: video/webm" \
  --data-binary "@test-video.webm"

# 3. Upload thumbnail
curl -X POST http://localhost:3001/api/videos/{videoId}/thumbnail \
  -H "Authorization: Bearer test_token" \
  -F "thumbnail=@cover.jpg"

# 4. Complete upload
curl -X POST http://localhost:3001/api/videos/upload-session/{sessionId}/complete \
  -H "Authorization: Bearer test_token"

# 5. Check status
curl http://localhost:3001/api/videos/{videoId}/status \
  -H "Authorization: Bearer test_token"

# 6. Publish
curl -X POST http://localhost:3001/api/videos/{videoId}/publish \
  -H "Authorization: Bearer test_token"
```

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Maintained By:** NextPlay Backend Team
