# NextPlay Video Upload API - Endpoint Specifications

**Base URL**: `https://api.nextplay.com`  
**API Version**: `v1`  
**Authentication**: JWT Bearer token (required for all endpoints)

---

## Authentication

All API requests must include a valid JWT token:

```http
Authorization: Bearer <jwt_token>
```

### JWT Payload Structure
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "handle": "user123",
  "age_band": "16-17",
  "iat": 1735084800,
  "exp": 1735171200
}
```

---

## Endpoint 1: Initiate Multipart Upload

### `POST /v1/uploads/initiate`

Creates a video record and multipart upload session.

#### Request Headers
```http
POST /v1/uploads/initiate HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "title": "My First Skateboard Trick",
  "caption": "Learning kickflips! 🛹 #skateboarding #tricks",
  "category": "sports",
  "visibility": "public",
  "tags": ["skateboarding", "tricks", "beginner"],
  "filename": "skateboard_video.mp4",
  "content_type": "video/mp4",
  "file_size_bytes": 45678901,
  "expected_duration_ms": 15000
}
```

#### Request Body Schema
| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `title` | string | Yes | 1-80 characters |
| `caption` | string | No | Max 500 characters |
| `category` | enum | Yes | sports, dance, art, comedy, stem, gaming, music, fitness |
| `visibility` | enum | Yes | public, private, unlisted |
| `tags` | string[] | No | Max 5 tags, each 1-50 chars |
| `filename` | string | Yes | Original filename |
| `content_type` | string | Yes | video/mp4, video/quicktime |
| `file_size_bytes` | integer | Yes | 1 - 157,286,400 (150MB) |
| `expected_duration_ms` | integer | No | Estimated duration in milliseconds |

#### Response (201 Created)
```json
{
  "upload_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "s3_upload_id": "Rm1hMUU5NmM1N2NkNGFiY2E5YmY0ZjM5ZGVhZjU5YmRk",
  "expires_at": "2025-12-25T12:00:00Z",
  "part_size_bytes": 10485760,
  "total_parts": 5,
  "instructions": {
    "method": "multipart",
    "max_parts": 10000,
    "min_part_size": 5242880,
    "max_part_size": 104857600
  },
  "metadata": {
    "s3_bucket": "nextplay-videos-prod",
    "s3_key": "uploads/550e8400-e29b-41d4-a716-446655440000/f9e8d7c6-b5a4-3210-9876-543210fedcba/original.mp4"
  }
}
```

#### Response Schema
| Field | Type | Description |
|-------|------|-------------|
| `upload_id` | UUID | Upload session ID |
| `video_id` | UUID | Video record ID |
| `s3_upload_id` | string | AWS S3 multipart upload ID |
| `expires_at` | ISO 8601 | Upload session expiration (1 hour) |
| `part_size_bytes` | integer | Recommended part size (10MB) |
| `total_parts` | integer | Total number of parts |
| `instructions` | object | Upload instructions |
| `metadata` | object | S3 bucket and key information |

#### Error Responses

**400 Bad Request - Invalid Input**
```json
{
  "error": "VALIDATION_ERROR",
  "message": "File size exceeds maximum allowed size of 150MB",
  "details": {
    "field": "file_size_bytes",
    "provided": 200000000,
    "max": 157286400
  }
}
```

**400 Bad Request - Duration Too Long**
```json
{
  "error": "DURATION_TOO_LONG",
  "message": "Expected duration exceeds 30 second limit",
  "details": {
    "expected_duration_ms": 35000,
    "max_duration_ms": 30000
  }
}
```

**401 Unauthorized**
```json
{
  "error": "UNAUTHORIZED",
  "message": "Invalid or missing authentication token"
}
```

**429 Too Many Requests**
```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Upload initiation limit exceeded",
  "details": {
    "limit": 10,
    "window": "1 hour",
    "retry_after": "2025-12-25T12:30:00Z"
  }
}
```

---

## Endpoint 2: Get Presigned URL for Part Upload

### `POST /v1/uploads/{upload_id}/parts/presign`

Generates a presigned URL for uploading a specific part.

#### Request Headers
```http
POST /v1/uploads/a1b2c3d4-e5f6-7890-1234-567890abcdef/parts/presign HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "part_number": 1,
  "content_length": 10485760
}
```

#### Request Body Schema
| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `part_number` | integer | Yes | 1 - 10,000 |
| `content_length` | integer | Yes | 5MB - 100MB |

#### Response (200 OK)
```json
{
  "part_number": 1,
  "presigned_url": "https://nextplay-videos-prod.s3.amazonaws.com/uploads/550e8400/.../original.mp4?partNumber=1&uploadId=Rm1h...&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=...&X-Amz-Date=20251225T120000Z&X-Amz-Expires=600&X-Amz-Signature=...",
  "expires_at": "2025-12-25T12:10:00Z",
  "required_headers": {
    "Content-Type": "video/mp4",
    "Content-Length": "10485760"
  }
}
```

#### Response Schema
| Field | Type | Description |
|-------|------|-------------|
| `part_number` | integer | Part number |
| `presigned_url` | string | S3 presigned PUT URL (10 min expiry) |
| `expires_at` | ISO 8601 | URL expiration timestamp |
| `required_headers` | object | Headers that must be included in PUT request |

#### Client Upload Request (to S3)
```http
PUT <presigned_url> HTTP/1.1
Content-Type: video/mp4
Content-Length: 10485760

[binary data]
```

#### Client Upload Response (from S3)
```http
HTTP/1.1 200 OK
ETag: "3858f62230ac3c915f300c664312c63f"
```

**Client must save the ETag for each part!**

#### Error Responses

**404 Not Found**
```json
{
  "error": "UPLOAD_NOT_FOUND",
  "message": "Upload session not found or expired"
}
```

**400 Bad Request**
```json
{
  "error": "INVALID_PART_NUMBER",
  "message": "Part number exceeds total parts",
  "details": {
    "part_number": 100,
    "total_parts": 5
  }
}
```

---

## Endpoint 3: Complete Multipart Upload

### `POST /v1/uploads/{upload_id}/complete`

Completes the multipart upload and triggers video processing.

#### Request Headers
```http
POST /v1/uploads/a1b2c3d4-e5f6-7890-1234-567890abcdef/complete HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "parts": [
    {
      "part_number": 1,
      "etag": "3858f62230ac3c915f300c664312c63f"
    },
    {
      "part_number": 2,
      "etag": "622f2e0f6c8c24f8e8c3f9a2b7e4d5c1"
    },
    {
      "part_number": 3,
      "etag": "1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
    },
    {
      "part_number": 4,
      "etag": "9z8y7x6w5v4u3t2s1r0q9p8o7n6m5l4k"
    },
    {
      "part_number": 5,
      "etag": "abcdef1234567890abcdef1234567890"
    }
  ]
}
```

#### Request Body Schema
| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `parts` | array | Yes | Array of part objects |
| `parts[].part_number` | integer | Yes | Sequential part number |
| `parts[].etag` | string | Yes | ETag from S3 PUT response |

#### Response (200 OK)
```json
{
  "upload_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "UPLOADED",
  "message": "Upload completed successfully. Video is being processed.",
  "processing": {
    "job_id": "1234567890abcdef",
    "status": "QUEUED",
    "estimated_time_seconds": 120
  },
  "completed_at": "2025-12-25T12:05:00Z"
}
```

#### Response Schema
| Field | Type | Description |
|-------|------|-------------|
| `upload_id` | UUID | Upload session ID |
| `video_id` | UUID | Video record ID |
| `status` | string | Upload status (UPLOADED) |
| `message` | string | Human-readable status |
| `processing` | object | Transcoding job details |
| `completed_at` | ISO 8601 | Upload completion timestamp |

#### Error Responses

**400 Bad Request - Missing Parts**
```json
{
  "error": "INCOMPLETE_UPLOAD",
  "message": "Not all parts were uploaded",
  "details": {
    "expected_parts": 5,
    "provided_parts": 3,
    "missing_parts": [4, 5]
  }
}
```

**400 Bad Request - Invalid ETags**
```json
{
  "error": "INVALID_ETAG",
  "message": "One or more ETags are invalid",
  "details": {
    "invalid_parts": [2, 4]
  }
}
```

**500 Internal Server Error**
```json
{
  "error": "UPLOAD_COMPLETION_FAILED",
  "message": "Failed to complete multipart upload on S3",
  "details": {
    "s3_error": "NoSuchUpload"
  }
}
```

---

## Endpoint 4: Check Video Status

### `GET /v1/videos/{video_id}/status`

Polls the processing status of a video.

#### Request Headers
```http
GET /v1/videos/f9e8d7c6-b5a4-3210-9876-543210fedcba/status HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
```

#### Response (200 OK) - Processing
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "PROCESSING",
  "progress": 65,
  "message": "Transcoding video to multiple formats",
  "processing_started_at": "2025-12-25T12:05:30Z",
  "estimated_completion": "2025-12-25T12:07:30Z"
}
```

#### Response (200 OK) - Ready
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "READY",
  "progress": 100,
  "message": "Video processing completed successfully",
  "duration_ms": 15234,
  "width": 1280,
  "height": 720,
  "fps": 30.0,
  "assets": [
    {
      "kind": "ORIGINAL",
      "url": "https://cdn.nextplay.com/videos/.../original.mp4",
      "size_bytes": 45678901
    },
    {
      "kind": "MP4_720",
      "url": "https://cdn.nextplay.com/videos/.../renditions/720p/video.mp4",
      "width": 1280,
      "height": 720,
      "bitrate_kbps": 2500,
      "size_bytes": 5234567
    },
    {
      "kind": "MP4_480",
      "url": "https://cdn.nextplay.com/videos/.../renditions/480p/video.mp4",
      "width": 854,
      "height": 480,
      "bitrate_kbps": 1000,
      "size_bytes": 2123456
    },
    {
      "kind": "MP4_240",
      "url": "https://cdn.nextplay.com/videos/.../renditions/240p/video.mp4",
      "width": 426,
      "height": 240,
      "bitrate_kbps": 400,
      "size_bytes": 876543
    },
    {
      "kind": "THUMB",
      "url": "https://cdn.nextplay.com/videos/.../thumbs/thumbnail_1s.jpg",
      "width": 1280,
      "height": 720
    }
  ],
  "processing_completed_at": "2025-12-25T12:07:15Z"
}
```

#### Response (200 OK) - Failed
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "PROCESSING_FAILED",
  "progress": 0,
  "message": "Video processing failed",
  "error": {
    "code": "TRANSCODE_ERROR",
    "message": "Invalid video codec",
    "details": "Video codec must be H.264 or H.265"
  },
  "failed_at": "2025-12-25T12:06:00Z"
}
```

#### Response (200 OK) - Rejected (Duration)
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "REJECTED_TOO_LONG",
  "progress": 0,
  "message": "Video duration exceeds 30 second limit",
  "duration_ms": 35678,
  "max_duration_ms": 30000,
  "rejected_at": "2025-12-25T12:05:45Z"
}
```

#### Error Responses

**404 Not Found**
```json
{
  "error": "VIDEO_NOT_FOUND",
  "message": "Video not found or you don't have access"
}
```

---

## Endpoint 5: Publish Video

### `POST /v1/videos/{video_id}/publish`

Publishes a video to make it visible in feeds.

#### Request Headers
```http
POST /v1/videos/f9e8d7c6-b5a4-3210-9876-543210fedcba/publish HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

#### Request Body
```json
{
  "visibility": "public",
  "category": "sports",
  "notify_followers": true
}
```

#### Request Body Schema
| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `visibility` | enum | No | public, private, unlisted (default from initiate) |
| `category` | enum | No | Update category if needed |
| `notify_followers` | boolean | No | Send push notifications (default: true) |

#### Response (200 OK)
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "status": "PUBLISHED",
  "message": "Video published successfully",
  "published_at": "2025-12-25T12:10:00Z",
  "video": {
    "id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "handle": "user123",
      "avatar_url": "https://cdn.nextplay.com/avatars/user123.jpg"
    },
    "title": "My First Skateboard Trick",
    "caption": "Learning kickflips! 🛹 #skateboarding #tricks",
    "category": "sports",
    "visibility": "public",
    "tags": ["skateboarding", "tricks", "beginner"],
    "duration_ms": 15234,
    "width": 1280,
    "height": 720,
    "thumbnail_url": "https://cdn.nextplay.com/videos/.../thumbs/thumbnail_1s.jpg",
    "video_url": "https://cdn.nextplay.com/videos/.../renditions/720p/video.mp4",
    "hls_url": "https://cdn.nextplay.com/videos/.../renditions/hls/master.m3u8",
    "like_count": 0,
    "comment_count": 0,
    "view_count": 0,
    "created_at": "2025-12-25T12:00:00Z",
    "published_at": "2025-12-25T12:10:00Z"
  }
}
```

#### Error Responses

**400 Bad Request - Not Ready**
```json
{
  "error": "VIDEO_NOT_READY",
  "message": "Video is still processing. Current status: PROCESSING",
  "details": {
    "current_status": "PROCESSING",
    "progress": 65
  }
}
```

**400 Bad Request - Duration Exceeded**
```json
{
  "error": "DURATION_EXCEEDED",
  "message": "Video duration exceeds 30 second limit",
  "details": {
    "duration_ms": 32456,
    "max_duration_ms": 30000
  }
}
```

**400 Bad Request - Missing Assets**
```json
{
  "error": "MISSING_ASSETS",
  "message": "Required transcoded assets are not available",
  "details": {
    "missing_assets": ["MP4_720", "THUMB"]
  }
}
```

---

## Endpoint 6: Get Video Details

### `GET /v1/videos/{video_id}`

Retrieves full video details and playback URLs.

#### Request Headers
```http
GET /v1/videos/f9e8d7c6-b5a4-3210-9876-543210fedcba HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
```

#### Response (200 OK)
```json
{
  "id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "handle": "user123",
    "avatar_url": "https://cdn.nextplay.com/avatars/user123.jpg",
    "is_verified": true,
    "is_following": false
  },
  "title": "My First Skateboard Trick",
  "caption": "Learning kickflips! 🛹 #skateboarding #tricks",
  "category": "sports",
  "visibility": "public",
  "tags": ["skateboarding", "tricks", "beginner"],
  "duration_ms": 15234,
  "width": 1280,
  "height": 720,
  "fps": 30.0,
  "status": "PUBLISHED",
  "thumbnail_url": "https://cdn.nextplay.com/videos/.../thumbs/thumbnail_1s.jpg",
  "playback": {
    "hls": "https://cdn.nextplay.com/videos/.../renditions/hls/master.m3u8",
    "mp4_720": "https://cdn.nextplay.com/videos/.../renditions/720p/video.mp4",
    "mp4_480": "https://cdn.nextplay.com/videos/.../renditions/480p/video.mp4",
    "mp4_240": "https://cdn.nextplay.com/videos/.../renditions/240p/video.mp4"
  },
  "like_count": 127,
  "comment_count": 23,
  "view_count": 1542,
  "share_count": 8,
  "is_liked": false,
  "is_bookmarked": false,
  "created_at": "2025-12-25T12:00:00Z",
  "published_at": "2025-12-25T12:10:00Z"
}
```

#### Error Responses

**404 Not Found**
```json
{
  "error": "VIDEO_NOT_FOUND",
  "message": "Video not found or you don't have access"
}
```

**403 Forbidden**
```json
{
  "error": "PRIVATE_VIDEO",
  "message": "This video is private and you don't have access"
}
```

---

## Rate Limiting

All endpoints are rate-limited per user:

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /v1/uploads/initiate` | 10 requests | 1 hour |
| `POST /v1/uploads/{id}/parts/presign` | 1000 requests | 1 hour |
| `POST /v1/uploads/{id}/complete` | 20 requests | 1 hour |
| `GET /v1/videos/{id}/status` | 60 requests | 1 minute |
| `POST /v1/videos/{id}/publish` | 20 requests | 1 hour |
| `GET /v1/videos/{id}` | 100 requests | 1 minute |

### Rate Limit Response Headers
```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1735171200
```

### Rate Limit Exceeded Response
```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests. Please try again later.",
  "retry_after": "2025-12-25T13:00:00Z"
}
```

---

## Error Codes Summary

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `DURATION_TOO_LONG` | 400 | Video exceeds 30 seconds |
| `FILE_TOO_LARGE` | 400 | File exceeds 150MB |
| `INVALID_FORMAT` | 400 | Unsupported file format |
| `UNAUTHORIZED` | 401 | Invalid/missing auth token |
| `FORBIDDEN` | 403 | Access denied |
| `VIDEO_NOT_FOUND` | 404 | Video doesn't exist |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
