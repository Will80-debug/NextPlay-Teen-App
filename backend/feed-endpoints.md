# NextPlay Feed API - Endpoint Specifications

## Base URL
```
https://api.nextplay.com/v1
```

---

## Endpoint 1: Get For You Feed

### `GET /v1/feed`

Returns a paginated list of videos optimized for vertical scrolling.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `cursor` | string | No | null | Pagination cursor (base64 encoded) |
| `limit` | integer | No | 10 | Number of items (min: 1, max: 50) |
| `category` | string | No | null | Filter by category (sports, dance, art, etc.) |
| `quality` | string | No | auto | Video quality preference (240p, 480p, 720p, auto) |

#### Request Headers
```http
GET /v1/feed?limit=10&quality=auto HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
X-Device-ID: <device_uuid>
X-Network-Type: wifi
Accept-Encoding: gzip
```

#### Response (200 OK)

```json
{
  "items": [
    {
      "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
      "creator": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "handle": "kickflip_kid",
        "avatar_url": "https://cdn.nextplay.com/avatars/550e8400/avatar.jpg",
        "is_verified": true,
        "follower_count": 15234
      },
      "title": "My First Skateboard Trick",
      "caption": "Learning kickflips! 🛹 #skateboarding #tricks",
      "category": "sports",
      "tags": ["skateboarding", "tricks", "beginner"],
      "playback": {
        "hls_url": "https://cdn.nextplay.com/videos/550e8400/f9e8d7c6/renditions/hls/master.m3u8",
        "mp4_urls": {
          "720p": "https://cdn.nextplay.com/videos/550e8400/f9e8d7c6/renditions/720p/video.mp4",
          "480p": "https://cdn.nextplay.com/videos/550e8400/f9e8d7c6/renditions/480p/video.mp4",
          "240p": "https://cdn.nextplay.com/videos/550e8400/f9e8d7c6/renditions/240p/video.mp4"
        },
        "thumbnail_url": "https://cdn.nextplay.com/videos/550e8400/f9e8d7c6/thumbs/thumbnail_1s.jpg",
        "duration_ms": 15234,
        "width": 1280,
        "height": 720,
        "aspect_ratio": "16:9"
      },
      "counts": {
        "likes": 1287,
        "comments": 234,
        "views": 15432,
        "shares": 45
      },
      "user_state": {
        "liked": false,
        "bookmarked": false,
        "following": false
      },
      "published_at": "2025-12-25T12:00:00Z",
      "score": 8.34
    },
    {
      "video_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "creator": {
        "id": "440e7300-d18a-31f3-b605-335544330000",
        "handle": "dance_queen",
        "avatar_url": "https://cdn.nextplay.com/avatars/440e7300/avatar.jpg",
        "is_verified": false,
        "follower_count": 8456
      },
      "title": "New Dance Challenge",
      "caption": "Try this move! 💃✨ #dance #challenge",
      "category": "dance",
      "tags": ["dance", "challenge", "trending"],
      "playback": {
        "hls_url": "https://cdn.nextplay.com/videos/440e7300/a1b2c3d4/renditions/hls/master.m3u8",
        "mp4_urls": {
          "720p": "https://cdn.nextplay.com/videos/440e7300/a1b2c3d4/renditions/720p/video.mp4",
          "480p": "https://cdn.nextplay.com/videos/440e7300/a1b2c3d4/renditions/480p/video.mp4",
          "240p": "https://cdn.nextplay.com/videos/440e7300/a1b2c3d4/renditions/240p/video.mp4"
        },
        "thumbnail_url": "https://cdn.nextplay.com/videos/440e7300/a1b2c3d4/thumbs/thumbnail_1s.jpg",
        "duration_ms": 18567,
        "width": 1080,
        "height": 1920,
        "aspect_ratio": "9:16"
      },
      "counts": {
        "likes": 2345,
        "comments": 456,
        "views": 23456,
        "shares": 123
      },
      "user_state": {
        "liked": true,
        "bookmarked": false,
        "following": true
      },
      "published_at": "2025-12-25T11:45:00Z",
      "score": 9.12
    }
  ],
  "pagination": {
    "next_cursor": "MjAyNS0xMi0yNVQxMTo0NTowMFp8YTFiMmMzZDQtZTVmNi03ODkwLTEyMzQtNTY3ODkwYWJjZGVm",
    "has_more": true,
    "total_count": null
  },
  "metadata": {
    "request_id": "req_1234567890abcdef",
    "cache_hit": true,
    "cache_key": "feed:global:cursor0",
    "generated_at": "2025-12-25T12:05:00Z",
    "ttl_seconds": 60
  }
}
```

#### Response Schema

**Root Object**:
| Field | Type | Description |
|-------|------|-------------|
| `items` | array | Array of feed items (videos) |
| `pagination` | object | Pagination metadata |
| `metadata` | object | Request metadata (debugging) |

**Feed Item Object**:
| Field | Type | Description |
|-------|------|-------------|
| `video_id` | UUID | Video unique identifier |
| `creator` | object | Creator information |
| `title` | string | Video title (max 80 chars) |
| `caption` | string | Video caption/description |
| `category` | enum | Video category |
| `tags` | array | Hashtags (max 5) |
| `playback` | object | Playback URLs and metadata |
| `counts` | object | Engagement metrics |
| `user_state` | object | Current user's interaction state |
| `published_at` | ISO 8601 | Publication timestamp |
| `score` | float | Ranking score (for debugging) |

**Creator Object**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Creator user ID |
| `handle` | string | Username/handle |
| `avatar_url` | string | Profile picture URL |
| `is_verified` | boolean | Verified badge status |
| `follower_count` | integer | Number of followers |

**Playback Object**:
| Field | Type | Description |
|-------|------|-------------|
| `hls_url` | string | HLS master playlist URL |
| `mp4_urls` | object | MP4 URLs by quality |
| `thumbnail_url` | string | Video thumbnail image |
| `duration_ms` | integer | Duration in milliseconds |
| `width` | integer | Video width in pixels |
| `height` | integer | Video height in pixels |
| `aspect_ratio` | string | Display aspect ratio |

**Counts Object**:
| Field | Type | Description |
|-------|------|-------------|
| `likes` | integer | Total likes |
| `comments` | integer | Total comments |
| `views` | integer | Total views |
| `shares` | integer | Total shares |

**User State Object**:
| Field | Type | Description |
|-------|------|-------------|
| `liked` | boolean | Current user liked this video |
| `bookmarked` | boolean | Current user bookmarked |
| `following` | boolean | Current user follows creator |

**Pagination Object**:
| Field | Type | Description |
|-------|------|-------------|
| `next_cursor` | string | Cursor for next page (base64 encoded) |
| `has_more` | boolean | More items available |
| `total_count` | integer | Total items (null for privacy) |

#### Error Responses

**400 Bad Request - Invalid Cursor**
```json
{
  "error": "INVALID_CURSOR",
  "message": "Cursor is malformed or expired",
  "details": {
    "cursor": "invalid_base64_string"
  }
}
```

**400 Bad Request - Invalid Limit**
```json
{
  "error": "INVALID_LIMIT",
  "message": "Limit must be between 1 and 50",
  "details": {
    "provided": 100,
    "min": 1,
    "max": 50
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
  "message": "Feed request limit exceeded",
  "details": {
    "limit": 60,
    "window": "1 minute",
    "retry_after": "2025-12-25T12:06:00Z"
  }
}
```

---

## Endpoint 2: Get Category Feed

### `GET /v1/feed/category/{category}`

Returns a feed filtered to a specific category.

#### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `category` | enum | Yes | sports, dance, art, comedy, stem, gaming, music, fitness |

#### Query Parameters
Same as main feed endpoint.

#### Request Example
```http
GET /v1/feed/category/sports?limit=10 HTTP/1.1
Host: api.nextplay.com
Authorization: Bearer <jwt_token>
```

#### Response
Same structure as main feed, but all items filtered to category.

---

## Endpoint 3: Prefetch Next Batch

### `POST /v1/feed/prefetch`

Requests prefetch of next batch for background loading.

#### Request Body
```json
{
  "cursor": "MjAyNS0xMi0yNVQxMTo0NTowMFp8YTFiMmMzZDQtZTVmNi03ODkwLTEyMzQtNTY3ODkwYWJjZGVm",
  "limit": 10,
  "prefetch_assets": true
}
```

#### Response (202 Accepted)
```json
{
  "status": "queued",
  "prefetch_id": "pf_1234567890abcdef",
  "estimated_ready_at": "2025-12-25T12:05:05Z"
}
```

**Purpose**: Signals backend to warm CDN cache for next batch before user scrolls there.

---

## Endpoint 4: Update User Interaction

### `POST /v1/feed/interaction`

Records user interaction with feed item (like, view, etc.).

#### Request Body
```json
{
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "action": "view",
  "metadata": {
    "watch_time_ms": 5000,
    "completed": false,
    "source": "feed"
  }
}
```

#### Actions
- `view` - Video viewed (>2 seconds)
- `like` - User liked video
- `unlike` - User unliked video
- `comment` - User commented
- `share` - User shared
- `skip` - User skipped (<2 seconds)

#### Response (200 OK)
```json
{
  "success": true,
  "updated_counts": {
    "likes": 1288,
    "views": 15433
  }
}
```

**Purpose**: Updates engagement metrics, used for feed ranking refinement.

---

## Response Headers

All feed responses include:

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Encoding: gzip
Cache-Control: private, max-age=30
X-Request-ID: req_1234567890abcdef
X-Cache-Hit: true
X-Cache-Key: feed:global:cursor0
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 55
X-RateLimit-Reset: 1735171260
Access-Control-Allow-Origin: https://nextplay.com
```

---

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `GET /v1/feed` | 60 requests | 1 minute |
| `GET /v1/feed/category/{cat}` | 60 requests | 1 minute |
| `POST /v1/feed/prefetch` | 20 requests | 1 minute |
| `POST /v1/feed/interaction` | 120 requests | 1 minute |

---

## CDN Behavior

### Asset URLs
All `playback` URLs are CloudFront URLs with:
- **Cache-Control**: `public, max-age=31536000, immutable`
- **Vary**: `Accept-Encoding`
- **Signed Cookies**: Optional for private videos

### Cache Warming
Backend pre-warms CDN edge locations:
1. Top 100 videos per region cached at all edges
2. New videos cached after first request
3. Thumbnails cached aggressively (1 year TTL)

---

## Latency Targets

| Metric | Target | Actual (p95) |
|--------|--------|--------------|
| Feed API response time | <250ms | ~180ms |
| First video playback | <800ms | ~650ms |
| Scroll to next video | <200ms | ~150ms |
| Thumbnail load | <100ms | ~80ms |

---

## Client Behavior Expectations

### Initial Load
1. Request first page: `GET /v1/feed?limit=10`
2. Immediately prefetch thumbnails for first 3 videos
3. Start buffering first video (adaptive quality)
4. Request second page in background

### During Scroll
1. When user reaches item N-2, request next page
2. Prebuffer video at item N+1
3. Evict video at item N-5 from memory

### Network Conditions
- **WiFi**: Load 720p by default
- **4G**: Load 480p, upgrade to 720p if bandwidth permits
- **3G/slow**: Load 240p, aggressive prefetch throttling

---

## Example cURL Requests

### Get Initial Feed
```bash
curl -X GET "https://api.nextplay.com/v1/feed?limit=10" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "X-Device-ID: device_abc123" \
  -H "X-Network-Type: wifi" \
  -H "Accept-Encoding: gzip"
```

### Get Next Page
```bash
curl -X GET "https://api.nextplay.com/v1/feed?cursor=MjAyNS0xMi0yNVQxMTo0NTowMFp8YTFiMmMzZDQtZTVmNi03ODkwLTEyMzQtNTY3ODkwYWJjZGVm&limit=10" \
  -H "Authorization: Bearer <token>"
```

### Get Category Feed
```bash
curl -X GET "https://api.nextplay.com/v1/feed/category/sports?limit=10" \
  -H "Authorization: Bearer <token>"
```

### Record View
```bash
curl -X POST "https://api.nextplay.com/v1/feed/interaction" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
    "action": "view",
    "metadata": {
      "watch_time_ms": 5000,
      "completed": false,
      "source": "feed"
    }
  }'
```

---

## Performance Optimizations

### Backend
- **Connection pooling**: Reuse DB connections
- **Query optimization**: Single query with JOINs
- **Redis caching**: Hot cache for first 5 pages
- **Gzip compression**: Reduce response size by 70%

### CDN
- **Edge caching**: Cache at 200+ locations
- **Brotli compression**: Better than gzip for JSON
- **HTTP/2**: Multiplexing for parallel requests

### Client
- **Prefetching**: Always 2 pages ahead
- **Lazy loading**: Thumbnails only when in viewport
- **Memory management**: Max 7 videos in memory
- **Disk caching**: Store last 50 video files

---

## Security Considerations

### Authentication
- JWT token required for all requests
- Token expires after 24 hours
- Refresh token for seamless re-authentication

### Rate Limiting
- Per-user limits prevent abuse
- Exponential backoff on 429 responses

### Content Filtering
- Only show `status = PUBLISHED` videos
- Only show `moderation_status = APPROVED` videos
- Filter private videos (unless creator)

### Privacy
- No tracking pixels in responses
- First-party analytics only
- No cross-site requests

---

**Version**: 1.0.0  
**Last Updated**: December 25, 2025
