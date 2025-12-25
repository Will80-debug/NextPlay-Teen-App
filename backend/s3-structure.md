# NextPlay S3 Object Storage Structure

## S3 Bucket Organization

```
nextplay-videos-{env}/
├── uploads/                          # Temporary upload storage
│   └── {user_id}/
│       └── {video_id}/
│           └── original.{ext}       # Original uploaded file
│
├── videos/                           # Processed videos
│   └── {user_id}/
│       └── {video_id}/
│           ├── renditions/
│           │   ├── 720p/
│           │   │   ├── video.mp4
│           │   │   └── manifest.m3u8
│           │   ├── 480p/
│           │   │   ├── video.mp4
│           │   │   └── manifest.m3u8
│           │   ├── 240p/
│           │   │   ├── video.mp4
│           │   │   └── manifest.m3u8
│           │   └── hls/
│           │       ├── master.m3u8
│           │       ├── 720p.m3u8
│           │       ├── 480p.m3u8
│           │       ├── 240p.m3u8
│           │       └── segments/
│           │           ├── 720p_00001.ts
│           │           ├── 720p_00002.ts
│           │           └── ...
│           ├── thumbs/
│           │   ├── thumbnail_1s.jpg
│           │   ├── thumbnail_1s.webp
│           │   └── poster.jpg
│           └── preview/
│               └── preview_3s.mp4    # 3-5 second preview clip
│
└── temp/                             # Temporary processing files
    └── {job_id}/
        └── ...
```

## Key Format Examples

### 1. Original Upload
```
s3://nextplay-videos-prod/uploads/{user_id}/{video_id}/original.mp4
```
**Example**:
```
s3://nextplay-videos-prod/uploads/550e8400-e29b-41d4-a716-446655440000/a1b2c3d4-e5f6-7890-1234-567890abcdef/original.mp4
```

### 2. Transcoded Renditions
```
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/{quality}/video.mp4
```
**Examples**:
```
s3://nextplay-videos-prod/videos/550e8400-e29b-41d4-a716-446655440000/a1b2c3d4-e5f6-7890-1234-567890abcdef/renditions/720p/video.mp4
s3://nextplay-videos-prod/videos/550e8400-e29b-41d4-a716-446655440000/a1b2c3d4-e5f6-7890-1234-567890abcdef/renditions/480p/video.mp4
s3://nextplay-videos-prod/videos/550e8400-e29b-41d4-a716-446655440000/a1b2c3d4-e5f6-7890-1234-567890abcdef/renditions/240p/video.mp4
```

### 3. HLS Streaming
```
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/hls/master.m3u8
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/hls/segments/720p_00001.ts
```

### 4. Thumbnails
```
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/thumbs/thumbnail_1s.jpg
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/thumbs/thumbnail_1s.webp
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/thumbs/poster.jpg
```

### 5. Preview Clip
```
s3://nextplay-videos-prod/videos/{user_id}/{video_id}/preview/preview_3s.mp4
```

## CDN URL Mapping

All S3 keys are served via CloudFront CDN with the following mapping:

```
S3 Key:  s3://nextplay-videos-prod/videos/{user_id}/{video_id}/...
CDN URL: https://cdn.nextplay.com/videos/{user_id}/{video_id}/...
```

**Example**:
```
S3:  s3://nextplay-videos-prod/videos/550e8400/a1b2c3d4/renditions/720p/video.mp4
CDN: https://cdn.nextplay.com/videos/550e8400/a1b2c3d4/renditions/720p/video.mp4
```

## Naming Conventions

### File Extensions
- **Video**: `.mp4`, `.mov` (input), `.m3u8` (HLS manifest), `.ts` (HLS segments)
- **Images**: `.jpg`, `.webp`, `.png`
- **Metadata**: `.json`

### Quality Presets
- **240p**: 426x240, ~400kbps, H.264 baseline
- **480p**: 854x480, ~1000kbps, H.264 main
- **720p**: 1280x720, ~2500kbps, H.264 high

### Thumbnail Generation
- Extract frame at 1 second mark
- Generate both JPEG (compatibility) and WebP (efficiency)
- Poster image: First frame or user-selected frame

## S3 Bucket Configuration

### Lifecycle Policies

```json
{
  "Rules": [
    {
      "Id": "delete-temp-uploads",
      "Status": "Enabled",
      "Prefix": "uploads/",
      "Expiration": {
        "Days": 7
      }
    },
    {
      "Id": "delete-temp-processing",
      "Status": "Enabled",
      "Prefix": "temp/",
      "Expiration": {
        "Days": 1
      }
    },
    {
      "Id": "transition-old-videos-to-glacier",
      "Status": "Enabled",
      "Prefix": "videos/",
      "Transitions": [
        {
          "Days": 365,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

### CORS Configuration

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": [
        "https://nextplay.com",
        "https://*.nextplay.com",
        "https://cdn.nextplay.com"
      ],
      "AllowedMethods": ["GET", "PUT", "POST", "HEAD"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["ETag", "Content-Length", "Content-Type"],
      "MaxAgeSeconds": 3600
    }
  ]
}
```

### Bucket Policy (CDN Access Only)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nextplay-videos-prod/videos/*"
    },
    {
      "Sid": "DenyDirectAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nextplay-videos-prod/videos/*",
      "Condition": {
        "StringNotEquals": {
          "aws:UserAgent": "Amazon CloudFront"
        }
      }
    }
  ]
}
```

## Key Generation Logic

### TypeScript Helper Functions

```typescript
interface S3KeyConfig {
  userId: string;
  videoId: string;
  bucket: string;
}

// Generate original upload key
export function getOriginalUploadKey(
  config: S3KeyConfig,
  extension: string
): string {
  return `uploads/${config.userId}/${config.videoId}/original.${extension}`;
}

// Generate rendition key
export function getRenditionKey(
  config: S3KeyConfig,
  quality: '240p' | '480p' | '720p'
): string {
  return `videos/${config.userId}/${config.videoId}/renditions/${quality}/video.mp4`;
}

// Generate HLS master manifest key
export function getHLSMasterKey(config: S3KeyConfig): string {
  return `videos/${config.userId}/${config.videoId}/renditions/hls/master.m3u8`;
}

// Generate thumbnail key
export function getThumbnailKey(
  config: S3KeyConfig,
  format: 'jpg' | 'webp',
  timeSeconds: number = 1
): string {
  return `videos/${config.userId}/${config.videoId}/thumbs/thumbnail_${timeSeconds}s.${format}`;
}

// Generate preview clip key
export function getPreviewKey(
  config: S3KeyConfig,
  durationSeconds: number = 3
): string {
  return `videos/${config.userId}/${config.videoId}/preview/preview_${durationSeconds}s.mp4`;
}

// Convert S3 key to CDN URL
export function s3KeyToCDNUrl(
  key: string,
  cdnDomain: string = 'cdn.nextplay.com'
): string {
  // Remove 'uploads/' or other non-public prefixes
  const publicKey = key.replace(/^(uploads|temp)\//, '');
  return `https://${cdnDomain}/${publicKey}`;
}
```

## Storage Estimates

### Per Video Storage
- **Original (720p, 30s)**: ~30-50 MB
- **720p rendition**: ~25 MB
- **480p rendition**: ~10 MB
- **240p rendition**: ~4 MB
- **HLS segments**: ~40 MB (all qualities)
- **Thumbnails**: ~500 KB (2-3 images)
- **Preview clip**: ~2 MB
- **Total per video**: ~111-131 MB

### Monthly Storage Projection
- **1,000 videos/day** = 30,000 videos/month
- **Storage needed**: ~3.3-3.9 TB/month
- **With lifecycle**: ~2-2.5 TB/month (after original cleanup)

## Security Considerations

### Presigned URL Security
- **Expiration**: 10 minutes for uploads, 1 hour for downloads
- **IP restriction**: Optional whitelist for uploads
- **Content-Type enforcement**: Validate on upload
- **Max size enforcement**: 150 MB limit

### Access Control
- **Uploads**: Only creator can upload to their video ID
- **Downloads**: Public access via CDN (for published videos)
- **Private videos**: Signed URLs with user verification
- **Admin**: Full access for moderation

### Encryption
- **At rest**: AES-256 (S3 default encryption)
- **In transit**: HTTPS/TLS only
- **Client-side**: Optional for sensitive uploads

## Monitoring & Logging

### S3 Access Logs
Enable S3 access logging to track:
- Upload patterns
- Download bandwidth
- Unauthorized access attempts

### CloudWatch Metrics
Monitor:
- Bucket size growth
- Request count per prefix
- 4xx/5xx error rates
- Upload success/failure rates

## Backup & Disaster Recovery

### Backup Strategy
- **Cross-region replication**: Critical for production
- **Versioning**: Enabled on production bucket
- **Retention**: Keep originals for 90 days, renditions indefinitely

### Recovery Time Objectives (RTO)
- **Published videos**: < 1 hour (CDN cache)
- **Processing videos**: < 4 hours (reprocess from original)
- **Complete bucket restore**: < 24 hours
