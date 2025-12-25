# NextPlay Video Upload & Processing Flow

## Overview

This document describes the complete flow from upload initiation to video publication, including all status transitions, worker processes, and error handling.

---

## 1. Upload Flow Diagram

```
┌─────────────┐
│   CLIENT    │
└──────┬──────┘
       │
       │ 1. POST /v1/uploads/initiate
       │    { title, file_size, category, ... }
       ▼
┌─────────────────────────────────────────────────────────┐
│                     API SERVER                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. Validate request (auth, rate limit, size)    │   │
│  │ 2. Create video record (status=DRAFT)           │   │
│  │ 3. Create upload record (status=INITIATED)      │   │
│  │ 4. Create S3 multipart upload                   │   │
│  │ 5. Return upload_id + s3_upload_id              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
       │
       │ Response: { upload_id, video_id, s3_upload_id }
       ▼
┌──────────────┐
│    CLIENT    │
│              │
│  ┌────────────────────────────────────────┐
│  │ 2. Split file into parts (10MB each)  │
│  │ 3. For each part:                      │
│  │    - POST /v1/uploads/{id}/parts/presign
│  │    - Receive presigned URL             │
│  │    - PUT to S3 with binary data        │
│  │    - Save ETag from response           │
│  └────────────────────────────────────────┘
└──────────────┘
       │
       │ 4. After all parts uploaded
       │ POST /v1/uploads/{id}/complete
       │ { parts: [{part_number, etag}, ...] }
       ▼
┌─────────────────────────────────────────────────────────┐
│                     API SERVER                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. Validate all parts uploaded                   │   │
│  │ 2. Complete S3 multipart upload                  │   │
│  │ 3. Update upload status = COMPLETED              │   │
│  │ 4. Update video status = UPLOADED                │   │
│  │ 5. Enqueue transcode job                         │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ 5. Enqueue job to SQS/Redis
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  TRANSCODING WORKER                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. Dequeue job from queue                        │   │
│  │ 2. Download original video from S3               │   │
│  │ 3. Validate duration (≤30s)                      │   │
│  │ 4. Validate codec (H.264/H.265)                  │   │
│  │ 5. Extract metadata (width, height, fps)        │   │
│  │ 6. Submit AWS MediaConvert job                   │   │
│  │ 7. Update video status = PROCESSING              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 6. AWS MediaConvert processes video
                        ▼
┌─────────────────────────────────────────────────────────┐
│                 AWS MediaConvert                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • Transcode to 720p MP4 (H.264, 2500kbps)       │   │
│  │ • Transcode to 480p MP4 (H.264, 1000kbps)       │   │
│  │ • Transcode to 240p MP4 (H.264, 400kbps)        │   │
│  │ • Generate HLS playlist + segments               │   │
│  │ • Extract thumbnail at 1 second                  │   │
│  │ • Generate preview clip (first 3 seconds)        │   │
│  │ • Output to S3: videos/{user_id}/{video_id}/... │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ 7. MediaConvert completion event
                        ▼
┌─────────────────────────────────────────────────────────┐
│            COMPLETION HANDLER (Lambda/Worker)            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. Receive MediaConvert completion event         │   │
│  │ 2. Create video_assets records for each output   │   │
│  │ 3. Update video status = READY                   │   │
│  │ 4. Send notification to client (optional)        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                        │
                        │ 8. Client polls status
                        │ GET /v1/videos/{id}/status
                        ▼
┌──────────────┐
│    CLIENT    │
│              │
│  ┌────────────────────────────────────────┐
│  │ 9. Status = READY                      │
│  │ 10. POST /v1/videos/{id}/publish       │
│  │ 11. Video is now PUBLIC                │
│  └────────────────────────────────────────┘
└──────────────┘
```

---

## 2. Status Transitions

### Video Status States

```
DRAFT
  ↓
UPLOADING  ────────→  [Upload failed] ────→ DRAFT (retry)
  ↓
UPLOADED
  ↓
PROCESSING ────────→  [Processing failed] ─→ PROCESSING_FAILED
  ↓                   [Duration > 30s]    ──→ REJECTED_TOO_LONG
  ↓                   [Invalid format]    ──→ REJECTED_FORMAT
  ↓
READY
  ↓
PUBLISHED  ────────→  [User deletes]     ──→ DELETED
```

### Status Definitions

| Status | Description | Next State | Trigger |
|--------|-------------|------------|---------|
| `DRAFT` | Video record created, no upload yet | UPLOADING | Multipart upload initiated |
| `UPLOADING` | Multipart upload in progress | UPLOADED | All parts uploaded and completed |
| `UPLOADED` | Upload complete, pending processing | PROCESSING | Transcode job enqueued |
| `PROCESSING` | Video being transcoded | READY / FAILED | MediaConvert completion |
| `READY` | Transcoding complete, ready to publish | PUBLISHED | User publishes video |
| `PUBLISHED` | Video visible in feeds | DELETED | User deletes video |
| `PROCESSING_FAILED` | Transcoding error | DRAFT (retry) | Manual retry by user |
| `REJECTED_TOO_LONG` | Duration > 30 seconds | DRAFT (trim) | User trims and re-uploads |
| `REJECTED_FORMAT` | Invalid codec/format | DRAFT (convert) | User converts and re-uploads |
| `DELETED` | Soft deleted | - | N/A |

---

## 3. Detailed Processing Steps

### Step 1: Upload Initiation (Client → API)

**Client Action:**
```javascript
const response = await fetch('https://api.nextplay.com/v1/uploads/initiate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    title: 'My Video',
    category: 'sports',
    visibility: 'public',
    filename: 'video.mp4',
    content_type: 'video/mp4',
    file_size_bytes: 45678901
  })
});

const { upload_id, video_id, s3_upload_id } = await response.json();
```

**API Server Actions:**
1. Verify JWT token and extract `user_id`
2. Check rate limit: `check_rate_limit(user_id, 'upload_initiate', 10, '1 hour')`
3. Validate request:
   - File size ≤ 150MB
   - Content type in ['video/mp4', 'video/quicktime']
   - Title length 1-80 chars
   - Category valid
4. Create `videos` record (status=DRAFT)
5. Create `uploads` record (status=INITIATED)
6. Call AWS S3 CreateMultipartUpload API
7. Store S3 `upload_id` in database
8. Increment rate limit counter
9. Return `upload_id`, `video_id`, `s3_upload_id`

---

### Step 2: Part Upload (Client → API → S3)

**Client Action (per part):**
```javascript
// Get presigned URL for each part
const partResponse = await fetch(
  `https://api.nextplay.com/v1/uploads/${upload_id}/parts/presign`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      part_number: partNum,
      content_length: partSize
    })
  }
);

const { presigned_url } = await partResponse.json();

// Upload part directly to S3
const uploadResponse = await fetch(presigned_url, {
  method: 'PUT',
  headers: {
    'Content-Type': 'video/mp4',
    'Content-Length': partSize.toString()
  },
  body: partData
});

const etag = uploadResponse.headers.get('ETag');
parts.push({ part_number: partNum, etag });
```

**API Server Actions:**
1. Verify JWT token and extract `user_id`
2. Verify upload belongs to user
3. Check upload not expired (< 1 hour old)
4. Validate part_number within range
5. Generate S3 presigned URL with:
   - Method: PUT
   - Expiration: 10 minutes
   - Required headers: Content-Type, Content-Length
6. Create/update `upload_parts` record
7. Return presigned URL

---

### Step 3: Complete Upload (Client → API)

**Client Action:**
```javascript
const completeResponse = await fetch(
  `https://api.nextplay.com/v1/uploads/${upload_id}/complete`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      parts: [
        { part_number: 1, etag: '...' },
        { part_number: 2, etag: '...' },
        // ... all parts
      ]
    })
  }
);

const { video_id, status } = await completeResponse.json();
```

**API Server Actions:**
1. Verify JWT token and extract `user_id`
2. Verify upload belongs to user
3. Validate all parts provided (check against `upload_parts` table)
4. Call AWS S3 CompleteMultipartUpload API with part ETags
5. Update `uploads.status` = COMPLETED
6. Update `uploads.completed_at` = NOW()
7. Update `videos.status` = UPLOADED
8. Create `transcode_jobs` record (status=QUEUED)
9. Enqueue job to SQS/Redis queue:
   ```json
   {
     "job_type": "transcode_video",
     "video_id": "...",
     "upload_id": "...",
     "user_id": "...",
     "input_s3_key": "uploads/.../original.mp4"
   }
   ```
10. Track analytics: `upload_completed`
11. Return success response

---

### Step 4: Video Validation & Transcoding (Worker)

**Worker Process (Node.js/Python/Go):**

```python
# Pseudocode for transcoding worker

async def process_transcode_job(job):
    video_id = job['video_id']
    input_key = job['input_s3_key']
    
    # 1. Download video metadata (first 10MB for probing)
    video_info = await probe_video_metadata(input_key)
    
    # 2. Validate duration
    if video_info['duration_ms'] > 30000:
        await db.execute("""
            UPDATE videos 
            SET status = 'REJECTED_TOO_LONG', 
                duration_ms = %s 
            WHERE id = %s
        """, (video_info['duration_ms'], video_id))
        
        await s3.delete_object(Bucket=bucket, Key=input_key)
        return
    
    # 3. Validate codec
    if video_info['video_codec'] not in ['h264', 'h265', 'hevc']:
        await db.execute("""
            UPDATE videos 
            SET status = 'REJECTED_FORMAT' 
            WHERE id = %s
        """, (video_id,))
        return
    
    # 4. Update video metadata
    await db.execute("""
        UPDATE videos 
        SET duration_ms = %s,
            width = %s,
            height = %s,
            fps = %s,
            status = 'PROCESSING'
        WHERE id = %s
    """, (
        video_info['duration_ms'],
        video_info['width'],
        video_info['height'],
        video_info['fps'],
        video_id
    ))
    
    # 5. Submit AWS MediaConvert job
    job_id = await submit_mediaconvert_job(
        input_key=input_key,
        output_prefix=f"videos/{job['user_id']}/{video_id}",
        settings={
            'renditions': ['720p', '480p', '240p'],
            'hls': True,
            'thumbnail': True,
            'preview': True
        }
    )
    
    # 6. Update transcode_jobs table
    await db.execute("""
        UPDATE transcode_jobs 
        SET job_id = %s,
            status = 'PROCESSING',
            started_at = NOW()
        WHERE video_id = %s
    """, (job_id, video_id))
```

---

### Step 5: MediaConvert Job Submission

**MediaConvert Job Template:**

```json
{
  "Role": "arn:aws:iam::ACCOUNT_ID:role/MediaConvertRole",
  "Settings": {
    "Inputs": [
      {
        "FileInput": "s3://nextplay-videos-prod/uploads/{user_id}/{video_id}/original.mp4",
        "VideoSelector": {},
        "AudioSelectors": {
          "Audio Selector 1": {
            "DefaultSelection": "DEFAULT"
          }
        }
      }
    ],
    "OutputGroups": [
      {
        "Name": "File Group - MP4 720p",
        "OutputGroupSettings": {
          "Type": "FILE_GROUP_SETTINGS",
          "FileGroupSettings": {
            "Destination": "s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/720p/"
          }
        },
        "Outputs": [
          {
            "NameModifier": "video",
            "VideoDescription": {
              "Width": 1280,
              "Height": 720,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 2500000,
                  "RateControlMode": "CBR",
                  "CodecProfile": "HIGH",
                  "CodecLevel": "LEVEL_4"
                }
              }
            },
            "AudioDescriptions": [
              {
                "CodecSettings": {
                  "Codec": "AAC",
                  "AacSettings": {
                    "Bitrate": 128000,
                    "SampleRate": 48000
                  }
                }
              }
            ],
            "ContainerSettings": {
              "Container": "MP4"
            }
          }
        ]
      },
      {
        "Name": "File Group - MP4 480p",
        "OutputGroupSettings": {
          "Type": "FILE_GROUP_SETTINGS",
          "FileGroupSettings": {
            "Destination": "s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/480p/"
          }
        },
        "Outputs": [
          {
            "NameModifier": "video",
            "VideoDescription": {
              "Width": 854,
              "Height": 480,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 1000000,
                  "RateControlMode": "CBR"
                }
              }
            },
            "AudioDescriptions": [
              {
                "CodecSettings": {
                  "Codec": "AAC",
                  "AacSettings": {
                    "Bitrate": 128000
                  }
                }
              }
            ],
            "ContainerSettings": {
              "Container": "MP4"
            }
          }
        ]
      },
      {
        "Name": "File Group - MP4 240p",
        "OutputGroupSettings": {
          "Type": "FILE_GROUP_SETTINGS",
          "FileGroupSettings": {
            "Destination": "s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/240p/"
          }
        },
        "Outputs": [
          {
            "NameModifier": "video",
            "VideoDescription": {
              "Width": 426,
              "Height": 240,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 400000,
                  "RateControlMode": "CBR"
                }
              }
            },
            "AudioDescriptions": [
              {
                "CodecSettings": {
                  "Codec": "AAC",
                  "AacSettings": {
                    "Bitrate": 96000
                  }
                }
              }
            ],
            "ContainerSettings": {
              "Container": "MP4"
            }
          }
        ]
      },
      {
        "Name": "Apple HLS",
        "OutputGroupSettings": {
          "Type": "HLS_GROUP_SETTINGS",
          "HlsGroupSettings": {
            "Destination": "s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/hls/",
            "SegmentLength": 6,
            "MinSegmentLength": 0
          }
        },
        "Outputs": [
          {
            "NameModifier": "_720p",
            "VideoDescription": {
              "Width": 1280,
              "Height": 720,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 2500000
                }
              }
            }
          },
          {
            "NameModifier": "_480p",
            "VideoDescription": {
              "Width": 854,
              "Height": 480,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 1000000
                }
              }
            }
          },
          {
            "NameModifier": "_240p",
            "VideoDescription": {
              "Width": 426,
              "Height": 240,
              "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                  "Bitrate": 400000
                }
              }
            }
          }
        ]
      }
    ]
  }
}
```

---

### Step 6: Processing Completion (EventBridge → Lambda)

**MediaConvert CloudWatch Event:**
```json
{
  "version": "0",
  "id": "12345678-1234-1234-1234-123456789012",
  "detail-type": "MediaConvert Job State Change",
  "source": "aws.mediaconvert",
  "account": "123456789012",
  "time": "2025-12-25T12:07:15Z",
  "region": "us-east-1",
  "detail": {
    "status": "COMPLETE",
    "jobId": "1234567890abcdef",
    "outputGroupDetails": [
      {
        "outputDetails": [
          {
            "outputFilePaths": [
              "s3://nextplay-videos-prod/videos/{user_id}/{video_id}/renditions/720p/video.mp4"
            ],
            "durationInMs": 15234
          }
        ]
      }
    ]
  }
}
```

**Lambda Handler (Completion):**
```python
async def handle_mediaconvert_completion(event):
    job_id = event['detail']['jobId']
    status = event['detail']['status']
    
    # Get transcode job from database
    job = await db.fetchone("""
        SELECT video_id, user_id, output_s3_prefix
        FROM transcode_jobs
        WHERE job_id = %s
    """, (job_id,))
    
    if status == 'COMPLETE':
        # Create video_assets records
        assets = []
        
        # 720p MP4
        assets.append({
            'kind': 'MP4_720',
            'url': f"https://cdn.nextplay.com/videos/{job['user_id']}/{job['video_id']}/renditions/720p/video.mp4",
            's3_key': f"videos/{job['user_id']}/{job['video_id']}/renditions/720p/video.mp4"
        })
        
        # ... (similar for 480p, 240p, HLS, thumbnail)
        
        # Insert assets
        await db.executemany("""
            INSERT INTO video_assets (video_id, kind, url, s3_bucket, s3_key)
            VALUES (%s, %s, %s, %s, %s)
        """, [(job['video_id'], a['kind'], a['url'], 'nextplay-videos-prod', a['s3_key']) for a in assets])
        
        # Update video status
        await db.execute("""
            UPDATE videos
            SET status = 'READY'
            WHERE id = %s
        """, (job['video_id'],))
        
        # Update transcode job
        await db.execute("""
            UPDATE transcode_jobs
            SET status = 'COMPLETED',
                completed_at = NOW()
            WHERE job_id = %s
        """, (job_id,))
        
        # Optional: Send push notification
        await send_notification(
            user_id=job['user_id'],
            title='Video ready!',
            body='Your video has been processed and is ready to publish.'
        )
    
    elif status == 'ERROR':
        await db.execute("""
            UPDATE videos
            SET status = 'PROCESSING_FAILED'
            WHERE id = %s
        """, (job['video_id'],))
        
        await db.execute("""
            UPDATE transcode_jobs
            SET status = 'FAILED',
                error_message = %s
            WHERE job_id = %s
        """, (event['detail']['errorMessage'], job_id))
```

---

### Step 7: Status Polling (Client → API)

**Client Action:**
```javascript
// Poll every 5 seconds until READY or FAILED
const pollStatus = async () => {
  const response = await fetch(
    `https://api.nextplay.com/v1/videos/${video_id}/status`,
    {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    }
  );
  
  const { status, progress } = await response.json();
  
  if (status === 'READY') {
    // Show publish button
    return 'READY';
  } else if (status.startsWith('REJECTED_') || status === 'PROCESSING_FAILED') {
    // Show error message
    return 'FAILED';
  } else {
    // Continue polling
    setTimeout(pollStatus, 5000);
  }
};

pollStatus();
```

---

### Step 8: Publish Video (Client → API)

**Client Action:**
```javascript
const publishResponse = await fetch(
  `https://api.nextplay.com/v1/videos/${video_id}/publish`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      visibility: 'public',
      notify_followers: true
    })
  }
);

const { status, published_at } = await publishResponse.json();
// status === 'PUBLISHED'
```

**API Server Actions:**
1. Verify JWT token and extract `user_id`
2. Verify video belongs to user
3. Check video status is 'READY'
4. Check duration ≤ 30,000ms
5. Check required assets exist (MP4_720, THUMB)
6. Update video:
   - status = PUBLISHED
   - published_at = NOW()
   - visibility = request.visibility
7. Create feed entries for followers (if public)
8. Send push notifications to followers (if enabled)
9. Track analytics: `publish_completed`
10. Return success response

---

## 4. Error Handling & Retries

### Upload Failures

**Scenario**: Network interruption during upload

**Handling**:
1. Client detects failed part upload (HTTP error or timeout)
2. Client retries failed part (max 3 times)
3. If retry fails, client can:
   - Abort upload: DELETE `/v1/uploads/{upload_id}`
   - Resume later: Re-request presigned URL for failed parts

**Database State**:
- `uploads.status` remains 'IN_PROGRESS'
- `upload_parts.is_uploaded` = false for failed parts

### Processing Failures

**Scenario**: MediaConvert job fails

**Handling**:
1. EventBridge triggers Lambda with ERROR status
2. Lambda updates:
   - `videos.status` = 'PROCESSING_FAILED'
   - `transcode_jobs.status` = 'FAILED'
   - `transcode_jobs.error_message` = error details
3. User receives error notification
4. User can retry (initiates new upload)

### Duration Validation Failure

**Scenario**: Video exceeds 30 seconds

**Handling**:
1. Worker validates duration after upload
2. If duration > 30s:
   - Update `videos.status` = 'REJECTED_TOO_LONG'
   - Update `videos.duration_ms` = actual duration
   - Delete original file from S3
3. API returns rejection reason to client
4. Client prompts user to trim video

---

## 5. Monitoring & Observability

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `upload_initiate_success_rate` | % of successful upload initiations | < 95% |
| `upload_complete_success_rate` | % of successful upload completions | < 90% |
| `transcode_success_rate` | % of successful transcoding jobs | < 95% |
| `average_processing_time` | Avg time from upload to READY | > 180 seconds |
| `duration_rejection_rate` | % of videos rejected for duration | > 5% |
| `format_rejection_rate` | % of videos rejected for format | > 2% |

### CloudWatch Logs

**Log Groups**:
- `/aws/lambda/nextplay-upload-api`
- `/aws/lambda/nextplay-transcode-worker`
- `/aws/lambda/nextplay-completion-handler`
- `/aws/mediaconvert/jobs`

**Structured Logging**:
```json
{
  "timestamp": "2025-12-25T12:00:00Z",
  "level": "INFO",
  "service": "upload-api",
  "event": "upload_initiated",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "video_id": "f9e8d7c6-b5a4-3210-9876-543210fedcba",
  "upload_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "file_size_bytes": 45678901,
  "content_type": "video/mp4"
}
```

### Alarms

**CloudWatch Alarms**:
1. High upload failure rate (> 10%)
2. High transcoding failure rate (> 5%)
3. Long processing times (> 5 minutes p95)
4. Queue depth too high (> 100 pending jobs)
5. S3 error rate spike (> 1%)

---

## 6. Cleanup & Maintenance

### Expired Uploads
```sql
-- Run every 10 minutes via cron
SELECT cleanup_expired_uploads();

-- Deletes S3 objects for expired uploads
DELETE FROM uploads 
WHERE status = 'EXPIRED'
AND created_at < NOW() - INTERVAL '7 days';
```

### Failed Jobs
```sql
-- Retry failed transcode jobs (max 3 attempts)
UPDATE transcode_jobs
SET status = 'QUEUED',
    retry_count = retry_count + 1
WHERE status = 'FAILED'
AND retry_count < 3
AND created_at > NOW() - INTERVAL '1 day';
```

### Old Videos
```sql
-- Archive old unpublished videos
UPDATE videos
SET status = 'DELETED'
WHERE status IN ('DRAFT', 'REJECTED_TOO_LONG', 'REJECTED_FORMAT')
AND created_at < NOW() - INTERVAL '30 days';
```

---

## 7. Performance Optimizations

### Multipart Upload
- **Part size**: 10MB (optimal for mobile networks)
- **Parallelism**: Upload 3 parts concurrently
- **Retry logic**: Exponential backoff with jitter

### Transcoding
- **Priority queue**: Paid users, verified users first
- **Batch processing**: Process similar videos together
- **Caching**: Reuse transcoding profiles

### Database
- **Connection pooling**: Max 20 connections per API instance
- **Query optimization**: Indexed on status, user_id, created_at
- **Read replicas**: Status polling uses read replica

---

**This completes the upload and processing flow documentation.**
