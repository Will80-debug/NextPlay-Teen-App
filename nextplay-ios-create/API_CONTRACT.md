# NextPlay Video Upload API Contract

## Overview

This document defines the API contract between the NextPlay iOS app and backend for video creation and upload.

## Base URL

```
Production: https://api.nextplay.com
Staging: https://api-staging.nextplay.com
Development: http://localhost:3000
```

## Authentication

All requests must include authentication:

```http
Authorization: Bearer {access_token}
```

## Endpoints

### 1. Initialize Video Upload

Creates an upload session and returns pre-signed URLs for video and thumbnail upload.

**Endpoint:** `POST /videos/init`

**Request:**

```json
{
  "userId": "string (required)",
  "caption": "string (required, max 150 chars)",
  "hashtags": ["string"] (required, max 5 items),
  "category": "string (required, one of: Sports|Dance|Art|Comedy|STEM|Gaming|Music|Fitness)",
  "durationSeconds": "number (required, max 30.0)",
  "createdAt": "string (ISO 8601 timestamp)"
}
```

**Response:** `200 OK`

```json
{
  "uploadUrl": "string (pre-signed S3 URL for video)",
  "videoId": "string (unique video identifier)",
  "thumbnailUploadUrl": "string (optional pre-signed S3 URL for thumbnail)",
  "expiresAt": "string (ISO 8601 timestamp, URL expiration)"
}
```

**Error Responses:**

```json
// 400 Bad Request
{
  "error": "INVALID_REQUEST",
  "message": "Caption exceeds 150 characters"
}

// 401 Unauthorized
{
  "error": "UNAUTHORIZED",
  "message": "Invalid or expired token"
}

// 413 Payload Too Large
{
  "error": "DURATION_TOO_LONG",
  "message": "Video duration exceeds 30 seconds"
}
```

---

### 2. Upload Video File

Uploads the actual video file to the pre-signed URL.

**Endpoint:** `PUT {uploadUrl}` (from init response)

**Request:**

```http
PUT {uploadUrl}
Content-Type: video/mp4
Content-Length: {file_size}

[Binary MP4 data]
```

**Requirements:**
- **Format:** MP4 (H.264 video, AAC audio)
- **Max Duration:** 30 seconds
- **Max File Size:** 100 MB
- **Recommended Resolution:** 1080p (1920x1080)
- **Frame Rate:** 30 or 60 fps

**Response:** `200 OK`

No body required.

**Error Responses:**

```http
403 Forbidden - URL expired or invalid
413 Payload Too Large - File exceeds size limit
```

---

### 3. Upload Thumbnail

Uploads the thumbnail/cover image for the video.

**Endpoint:** `POST /videos/{videoId}/thumbnail`

**Request:**

```http
POST /videos/{videoId}/thumbnail
Content-Type: image/jpeg
Content-Length: {file_size}
Authorization: Bearer {access_token}

[Binary JPEG data]
```

**Requirements:**
- **Format:** JPEG
- **Max File Size:** 2 MB
- **Recommended Size:** 1080x1920 (9:16 aspect ratio)
- **Quality:** 0.8 compression

**Response:** `200 OK`

```json
{
  "thumbnailUrl": "string (CDN URL for thumbnail)",
  "width": "number (image width in pixels)",
  "height": "number (image height in pixels)"
}
```

**Error Responses:**

```json
// 404 Not Found
{
  "error": "VIDEO_NOT_FOUND",
  "message": "Video with ID {videoId} not found"
}

// 415 Unsupported Media Type
{
  "error": "INVALID_FORMAT",
  "message": "Only JPEG images are supported"
}
```

---

### 4. Publish Video

Finalizes the upload and publishes the video to the feed.

**Endpoint:** `POST /videos/{videoId}/publish`

**Request:**

```http
POST /videos/{videoId}/publish
Content-Type: application/json
Authorization: Bearer {access_token}

{}
```

No body required (metadata already provided in init).

**Response:** `200 OK`

```json
{
  "success": true,
  "feedItem": {
    "id": "string (video ID)",
    "userId": "string",
    "videoUrl": "string (CDN URL)",
    "thumbnailUrl": "string (CDN URL)",
    "caption": "string",
    "hashtags": ["string"],
    "category": "string",
    "durationSeconds": "number",
    "createdAt": "string (ISO 8601)",
    "likeCount": 0,
    "commentCount": 0,
    "viewCount": 0
  },
  "message": "Video published successfully"
}
```

**Error Responses:**

```json
// 404 Not Found
{
  "error": "VIDEO_NOT_FOUND",
  "message": "Video with ID {videoId} not found"
}

// 409 Conflict
{
  "error": "ALREADY_PUBLISHED",
  "message": "Video has already been published"
}

// 422 Unprocessable Entity
{
  "error": "VIDEO_NOT_UPLOADED",
  "message": "Video file has not been uploaded yet"
}
```

---

### 5. Delete Draft Video (Optional)

Cancels an upload and deletes draft video.

**Endpoint:** `DELETE /videos/{videoId}`

**Request:**

```http
DELETE /videos/{videoId}
Authorization: Bearer {access_token}
```

**Response:** `204 No Content`

---

## Complete Upload Flow

```
1. App: POST /videos/init
   ← Server: {uploadUrl, videoId, thumbnailUploadUrl}

2. App: PUT {uploadUrl} [video file]
   ← Server: 200 OK

3. App: POST /videos/{videoId}/thumbnail [thumbnail]
   ← Server: {thumbnailUrl}

4. App: POST /videos/{videoId}/publish
   ← Server: {success: true, feedItem: {...}}

5. App: Display success, navigate to feed
```

## Upload Progress

The iOS app uses `URLSessionTaskDelegate` to track upload progress:

```swift
func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
) {
    let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    // Update UI with progress (0.0 to 1.0)
}
```

## Retry Strategy

### Video Upload Retry

- Retry up to 3 times with exponential backoff
- Backoff: 2s, 4s, 8s
- Resume from last uploaded byte if supported

### Thumbnail Upload Retry

- Retry up to 2 times
- Backoff: 1s, 2s

### Network Error Handling

```json
// Network timeout or connection error
{
  "error": "NETWORK_ERROR",
  "message": "Failed to connect to server",
  "retryable": true
}
```

## Content Validation

### Server-Side Validation

The backend MUST validate:

1. **Video duration:** ≤ 30.0 seconds
2. **File format:** Valid MP4 (H.264/AAC)
3. **File size:** ≤ 100 MB
4. **Caption length:** ≤ 150 characters
5. **Hashtag count:** ≤ 5
6. **Category:** Valid enum value
7. **User permissions:** User is authorized and age-eligible

### Validation Errors

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Video duration exceeds limit",
  "fields": {
    "durationSeconds": "Must be 30 seconds or less"
  }
}
```

## Rate Limiting

**Limits:**
- **Upload init:** 10 requests per minute per user
- **Video upload:** 5 uploads per hour per user (to prevent spam)
- **Publish:** 10 requests per minute per user

**Rate Limit Headers:**

```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1640995200
```

**Rate Limit Error:**

```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests. Try again later.",
  "retryAfter": 60
}
```

## Storage & CDN

### Video Storage

- **Storage:** AWS S3 or equivalent
- **CDN:** CloudFront or equivalent for global delivery
- **Expiration:** None (permanent unless deleted)

### URL Format

```
Video: https://cdn.nextplay.com/videos/{user_id}/{video_id}.mp4
Thumbnail: https://cdn.nextplay.com/thumbnails/{user_id}/{video_id}.jpg
```

## Security

### Pre-Signed URLs

- **Expiration:** 15 minutes from generation
- **Single-use:** Cannot be reused after upload completes
- **Scoped:** Tied to specific user and video ID

### Video Processing

After upload, the backend should:

1. **Verify duration** using FFmpeg or similar
2. **Scan for malware**
3. **Generate multiple resolutions** (240p, 360p, 480p, 720p, 1080p)
4. **Extract audio waveform** for visualization
5. **Run content moderation** (AI/human review)

### Content Moderation

Videos go through:

1. **Automated screening** (AI for inappropriate content)
2. **Age-appropriate filtering**
3. **Copyright detection**
4. **Human review** (if flagged)

Status updates:

```json
{
  "videoId": "video_123",
  "moderationStatus": "pending|approved|rejected",
  "reason": "string (if rejected)"
}
```

## Webhooks (Optional)

Backend can send webhooks for processing events:

```http
POST {client_webhook_url}
Content-Type: application/json

{
  "event": "video.processing.complete",
  "videoId": "video_123",
  "status": "ready",
  "variants": {
    "1080p": "https://cdn.nextplay.com/...",
    "720p": "https://cdn.nextplay.com/...",
    "480p": "https://cdn.nextplay.com/..."
  }
}
```

## Analytics Events

The app logs these events (can be forwarded to backend):

```json
{
  "event": "video_upload_started",
  "userId": "user_123",
  "videoId": "video_456",
  "duration": 15.5,
  "category": "Sports",
  "timestamp": "2025-01-01T12:00:00Z"
}

{
  "event": "video_upload_completed",
  "userId": "user_123",
  "videoId": "video_456",
  "uploadDuration": 8.3,
  "timestamp": "2025-01-01T12:00:08Z"
}

{
  "event": "video_published",
  "userId": "user_123",
  "videoId": "video_456",
  "timestamp": "2025-01-01T12:00:10Z"
}
```

## Testing

### Mock Responses

For development/testing, the backend can provide mock mode:

```http
POST /videos/init?mock=true
```

Returns instant success with fake URLs.

### Test Accounts

- Test users should have special `test_user` flag
- Test videos auto-deleted after 24 hours
- No rate limits for test accounts

## Error Codes Reference

| Code | Description | Retryable |
|------|-------------|-----------|
| `INVALID_REQUEST` | Malformed request | No |
| `UNAUTHORIZED` | Auth token invalid/expired | No |
| `VIDEO_NOT_FOUND` | Video ID doesn't exist | No |
| `DURATION_TOO_LONG` | Video > 30 seconds | No |
| `FILE_TOO_LARGE` | File exceeds size limit | No |
| `INVALID_FORMAT` | Wrong file format | No |
| `ALREADY_PUBLISHED` | Video already live | No |
| `VIDEO_NOT_UPLOADED` | Missing video file | No |
| `RATE_LIMIT_EXCEEDED` | Too many requests | Yes |
| `SERVER_ERROR` | Internal server error | Yes |
| `NETWORK_ERROR` | Connection failed | Yes |

## Performance SLAs

**Expected Response Times:**
- `/videos/init`: < 500ms (p95)
- `/videos/{id}/thumbnail`: < 1s (p95)
- `/videos/{id}/publish`: < 2s (p95)

**Upload Speed:**
- Video upload: ~5-10 MB/s (depends on network)
- Thumbnail upload: < 1s (small file)

## Monitoring

Backend should track:
- Upload success rate
- Average upload duration
- Error rates by type
- Video processing time
- CDN delivery metrics

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Maintained By:** NextPlay Backend Team
