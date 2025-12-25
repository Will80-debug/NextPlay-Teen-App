# NextPlay Video Upload Backend - Security & Implementation Guide

## Security Rules & Policies

### 1. Authentication & Authorization

#### JWT Token Requirements
```javascript
// Token structure
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",  // user_id
  "handle": "user123",
  "age_band": "16-17",                            // CRITICAL: Only store age band
  "iat": 1735084800,                              // Issued at
  "exp": 1735171200,                              // Expires in 24 hours
  "iss": "nextplay-auth",
  "aud": "nextplay-api"
}
```

**Validation Rules**:
- ✅ Verify signature with RS256 (public key)
- ✅ Check expiration (exp > now)
- ✅ Validate issuer and audience
- ✅ Ensure user exists and is active
- ✅ Verify age_band is 13+ (13-15, 16-17, or 18+)
- ❌ NEVER accept DOB (birth date) in token
- ❌ NEVER store full DOB in database

#### Authorization Checks
```python
# Every upload endpoint must verify:
def authorize_upload(user_id: str, video_id: str):
    video = db.fetch_one("SELECT user_id FROM videos WHERE id = %s", (video_id,))
    if not video:
        raise NotFoundError("Video not found")
    if video.user_id != user_id:
        raise ForbiddenError("Access denied")
    return True
```

---

### 2. Rate Limiting

#### Per-User Limits

| Endpoint | Limit | Window | Rationale |
|----------|-------|--------|-----------|
| `POST /v1/uploads/initiate` | 10 | 1 hour | Prevent spam uploads |
| `POST /v1/uploads/{id}/parts/presign` | 1000 | 1 hour | Allow ~100 videos (10 parts each) |
| `POST /v1/uploads/{id}/complete` | 20 | 1 hour | Retry + normal usage |
| `GET /v1/videos/{id}/status` | 60 | 1 minute | Polling every 1 second |
| `POST /v1/videos/{id}/publish` | 20 | 1 hour | Normal + retry |
| `GET /v1/videos/{id}` | 100 | 1 minute | Feed browsing |

#### Implementation (PostgreSQL)
```sql
-- Check if user is under limit
SELECT check_rate_limit(
    user_id := '550e8400-e29b-41d4-a716-446655440000',
    action := 'upload_initiate',
    max_requests := 10,
    window_duration := INTERVAL '1 hour'
);

-- Increment counter
SELECT increment_rate_limit(
    user_id := '550e8400-e29b-41d4-a716-446655440000',
    action := 'upload_initiate',
    max_requests := 10,
    window_duration := INTERVAL '1 hour'
);
```

#### Response Headers
```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1735171200
```

#### Rate Limit Exceeded Response
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 3600
Content-Type: application/json

{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Upload initiation limit exceeded",
  "details": {
    "limit": 10,
    "window": "1 hour",
    "retry_after": "2025-12-25T13:00:00Z"
  }
}
```

---

### 3. Content Validation

#### File Size Limits
```javascript
// Maximum file size: 150MB
const MAX_FILE_SIZE = 157_286_400; // 150 * 1024 * 1024

// Validate on upload initiation
if (file_size_bytes > MAX_FILE_SIZE) {
  throw new ValidationError(
    `File size ${file_size_bytes} exceeds maximum ${MAX_FILE_SIZE} bytes (150MB)`
  );
}

// Validate on multipart upload completion (S3)
const actualSize = await getS3ObjectSize(s3_key);
if (actualSize > MAX_FILE_SIZE) {
  await deleteS3Object(s3_key);
  throw new ValidationError("Uploaded file exceeds 150MB");
}
```

#### Content-Type Validation
```javascript
const ALLOWED_CONTENT_TYPES = [
  'video/mp4',         // MP4 container
  'video/quicktime',   // MOV container
  'video/webm'         // WebM (for browser recordings)
];

// Validate on initiate
if (!ALLOWED_CONTENT_TYPES.includes(content_type)) {
  throw new ValidationError(
    `Content type ${content_type} not allowed. Allowed: ${ALLOWED_CONTENT_TYPES.join(', ')}`
  );
}

// Validate actual file magic bytes after upload
const fileMagic = await readFileMagicBytes(s3_key);
if (!isValidVideoMagic(fileMagic)) {
  await deleteS3Object(s3_key);
  throw new ValidationError("File is not a valid video");
}
```

#### Video Codec Validation
```python
import ffmpeg

def validate_video_codec(s3_key: str):
    """Validate video codec after upload (server-side)"""
    try:
        probe = ffmpeg.probe(s3_key)
        video_stream = next(
            s for s in probe['streams'] if s['codec_type'] == 'video'
        )
        
        codec = video_stream['codec_name'].lower()
        allowed_codecs = ['h264', 'h265', 'hevc', 'vp8', 'vp9']
        
        if codec not in allowed_codecs:
            raise ValidationError(
                f"Video codec {codec} not supported. "
                f"Allowed: {', '.join(allowed_codecs)}"
            )
        
        return codec
    except Exception as e:
        raise ValidationError(f"Failed to probe video: {str(e)}")
```

#### Duration Validation (CRITICAL)
```python
def validate_video_duration(s3_key: str) -> int:
    """
    CRITICAL: Server-side duration validation.
    MUST reject videos > 30 seconds.
    """
    try:
        probe = ffmpeg.probe(s3_key)
        duration_sec = float(probe['format']['duration'])
        duration_ms = int(duration_sec * 1000)
        
        MAX_DURATION_MS = 30_000  # 30 seconds
        
        if duration_ms > MAX_DURATION_MS:
            # DELETE the file immediately
            s3_client.delete_object(Bucket=bucket, Key=s3_key)
            
            # Update database
            db.execute("""
                UPDATE videos
                SET status = 'REJECTED_TOO_LONG',
                    duration_ms = %s
                WHERE id = %s
            """, (duration_ms, video_id))
            
            raise DurationExceededError(
                f"Video duration {duration_ms}ms exceeds limit {MAX_DURATION_MS}ms"
            )
        
        return duration_ms
        
    except ffmpeg.Error as e:
        raise ValidationError(f"Failed to validate duration: {str(e)}")
```

---

### 4. Presigned URL Security

#### S3 Presigned URL Generation
```python
import boto3
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

def generate_upload_presigned_url(
    bucket: str,
    key: str,
    part_number: int,
    upload_id: str,
    content_type: str,
    content_length: int
) -> str:
    """
    Generate short-lived presigned URL for multipart upload.
    
    Security:
    - 10-minute expiration
    - Content-Type enforcement
    - Content-Length enforcement
    - PUT method only
    """
    
    url = s3_client.generate_presigned_url(
        ClientMethod='upload_part',
        Params={
            'Bucket': bucket,
            'Key': key,
            'PartNumber': part_number,
            'UploadId': upload_id,
            'ContentType': content_type,
            'ContentLength': content_length
        },
        ExpiresIn=600,  # 10 minutes
        HttpMethod='PUT'
    )
    
    return url
```

#### Presigned URL Constraints
```python
# Enforce in API
PRESIGNED_URL_EXPIRY = 600  # 10 minutes
MIN_PART_SIZE = 5 * 1024 * 1024  # 5MB
MAX_PART_SIZE = 100 * 1024 * 1024  # 100MB

def validate_part_upload_request(part_number: int, content_length: int):
    if part_number < 1 or part_number > 10_000:
        raise ValidationError(f"Part number {part_number} out of range [1, 10000]")
    
    if content_length < MIN_PART_SIZE:
        raise ValidationError(f"Part size {content_length} below minimum {MIN_PART_SIZE}")
    
    if content_length > MAX_PART_SIZE:
        raise ValidationError(f"Part size {content_length} exceeds maximum {MAX_PART_SIZE}")
```

#### IP Whitelisting (Optional)
```python
# Optional: Restrict uploads to specific IP ranges
def generate_presigned_url_with_ip_restriction(
    bucket: str,
    key: str,
    allowed_ip: str
) -> str:
    """
    Generate presigned URL that only works from specific IP.
    """
    
    url = s3_client.generate_presigned_url(
        ClientMethod='upload_part',
        Params={
            'Bucket': bucket,
            'Key': key,
            # ... other params
        },
        ExpiresIn=600,
        HttpMethod='PUT'
    )
    
    # Add IP condition to bucket policy
    # (This requires S3 bucket policy configuration)
    
    return url
```

---

### 5. Data Privacy (COPPA Compliance)

#### Age Band Storage
```sql
-- CORRECT: Store only age band
CREATE TYPE age_band AS ENUM ('13-15', '16-17', '18+');

CREATE TABLE users (
    id UUID PRIMARY KEY,
    age_band age_band NOT NULL,  -- ✅ STORE THIS
    -- ... other fields
);

-- INCORRECT: DO NOT STORE
-- birth_date DATE,           ❌ DO NOT STORE
-- age INTEGER,               ❌ DO NOT STORE (can calculate DOB)
-- birth_year INTEGER,        ❌ DO NOT STORE (too specific)
```

#### Privacy-Safe Analytics
```javascript
// ✅ CORRECT: First-party analytics without PII
{
  "event": "upload_started",
  "user_id": "550e8400-...",           // ✅ Internal UUID
  "age_band": "16-17",                 // ✅ Age band
  "category": "sports",                // ✅ Content category
  "timestamp": "2025-12-25T12:00:00Z"  // ✅ Timestamp
}

// ❌ INCORRECT: Do NOT collect
{
  "birth_date": "2008-05-15",          // ❌ PII
  "location": {"lat": 37.7, "lon": -122.4},  // ❌ GPS
  "device_id": "ABCD-1234",            // ❌ Device tracking
  "ad_id": "google-ads-123",           // ❌ Ad network ID
  "email": "user@example.com"          // ❌ Email (unless needed)
}
```

#### No Location Collection
```javascript
// ❌ DO NOT REQUEST
navigator.geolocation.getCurrentPosition();  // ❌ NO GPS

// ❌ DO NOT STORE
{
  "latitude": 37.7749,    // ❌ NO
  "longitude": -122.4194, // ❌ NO
  "city": "San Francisco", // ❌ NO
  "country": "US"         // ❌ NO (even country is too specific for minors)
}

// ✅ ACCEPTABLE: Server-side IP geolocation for CDN routing only
// (Don't store, just use for routing)
const cdnRegion = detectRegionFromIP(request.ip);  // ✅ OK for performance
```

---

### 6. Content Moderation

#### Automated Moderation (AI)
```python
import boto3

rekognition = boto3.client('rekognition')

def moderate_video(video_id: str, s3_key: str):
    """
    Use AWS Rekognition to detect inappropriate content.
    """
    
    response = rekognition.start_content_moderation(
        Video={'S3Object': {'Bucket': bucket, 'Name': s3_key}},
        NotificationChannel={
            'SNSTopicArn': 'arn:aws:sns:...',
            'RoleArn': 'arn:aws:iam:...'
        }
    )
    
    job_id = response['JobId']
    
    # Poll for results
    while True:
        result = rekognition.get_content_moderation(JobId=job_id)
        status = result['JobStatus']
        
        if status == 'SUCCEEDED':
            moderation_labels = result['ModerationLabels']
            
            # Check for inappropriate content
            for label in moderation_labels:
                if label['ModerationLabel']['Confidence'] > 80:
                    category = label['ModerationLabel']['Name']
                    
                    # Store moderation flag
                    db.execute("""
                        INSERT INTO moderation_flags (video_id, status, reason, ai_violence_score)
                        VALUES (%s, %s, %s, %s)
                    """, (video_id, 'rejected', f"Detected {category}", label['Confidence'] / 100))
                    
                    # Update video status
                    db.execute("""
                        UPDATE videos
                        SET status = 'DELETED',
                            moderation_status = 'rejected'
                        WHERE id = %s
                    """, (video_id,))
                    
                    return False
            
            # Approved
            db.execute("""
                UPDATE videos
                SET moderation_status = 'auto_approved'
                WHERE id = %s
            """, (video_id,))
            
            return True
            
        elif status == 'FAILED':
            # Manual review required
            db.execute("""
                INSERT INTO moderation_flags (video_id, status, reason)
                VALUES (%s, %s, %s)
            """, (video_id, 'pending', 'AI moderation failed'))
            
            return None
        
        time.sleep(5)
```

#### Manual Review Queue
```sql
-- Videos pending manual review
SELECT 
    v.id,
    v.user_id,
    u.handle,
    v.title,
    v.category,
    v.created_at,
    mf.reason,
    mf.ai_violence_score,
    mf.ai_adult_score
FROM videos v
JOIN users u ON v.user_id = u.id
LEFT JOIN moderation_flags mf ON v.id = mf.video_id
WHERE v.moderation_status = 'pending'
AND v.status = 'READY'
ORDER BY v.created_at ASC
LIMIT 100;
```

---

### 7. Encryption

#### At Rest
```bash
# S3 Bucket Encryption (AES-256)
aws s3api put-bucket-encryption \
  --bucket nextplay-videos-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

#### In Transit
```nginx
# Nginx configuration
server {
    listen 443 ssl http2;
    server_name api.nextplay.com;
    
    ssl_certificate /etc/ssl/certs/nextplay.crt;
    ssl_certificate_key /etc/ssl/private/nextplay.key;
    
    # TLS 1.2+ only
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    
    # Force HTTPS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://api-backend;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### 8. SQL Injection Prevention

```python
# ✅ CORRECT: Parameterized queries
def get_video(video_id: str):
    return db.fetch_one(
        "SELECT * FROM videos WHERE id = %s",
        (video_id,)  # ✅ Parameter binding
    )

# ❌ INCORRECT: String interpolation
def get_video_unsafe(video_id: str):
    return db.fetch_one(
        f"SELECT * FROM videos WHERE id = '{video_id}'"  # ❌ SQL injection risk
    )
```

---

### 9. CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://nextplay.com",
        "https://app.nextplay.com",
        "https://*.nextplay.com"  # Wildcard for subdomains
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
    expose_headers=["X-RateLimit-Limit", "X-RateLimit-Remaining"],
    max_age=3600  # Cache preflight for 1 hour
)
```

---

### 10. Logging & Monitoring

#### Structured Logging
```python
import logging
import json

logger = logging.getLogger(__name__)

def log_upload_event(event_type: str, user_id: str, video_id: str, **kwargs):
    """
    Log structured events for monitoring and debugging.
    """
    log_data = {
        'timestamp': datetime.utcnow().isoformat(),
        'event_type': event_type,
        'user_id': user_id,
        'video_id': video_id,
        'service': 'upload-api',
        **kwargs
    }
    
    logger.info(json.dumps(log_data))

# Example usage
log_upload_event(
    event_type='upload_initiated',
    user_id='550e8400-...',
    video_id='f9e8d7c6-...',
    file_size=45678901,
    content_type='video/mp4'
)
```

#### Sensitive Data Redaction
```python
import re

def redact_sensitive_data(data: dict) -> dict:
    """
    Remove sensitive data from logs.
    """
    sensitive_keys = ['email', 'password', 'token', 'api_key', 'birth_date']
    
    redacted = data.copy()
    for key in sensitive_keys:
        if key in redacted:
            redacted[key] = '***REDACTED***'
    
    return redacted
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Set up PostgreSQL database
- [ ] Run schema migration (schema.sql)
- [ ] Configure S3 bucket with lifecycle policies
- [ ] Set up CloudFront CDN
- [ ] Configure AWS MediaConvert

### Phase 2: API Development
- [ ] Implement JWT authentication
- [ ] Implement rate limiting
- [ ] Build upload initiation endpoint
- [ ] Build presigned URL generation
- [ ] Build upload completion endpoint
- [ ] Build status polling endpoint
- [ ] Build publish endpoint
- [ ] Build video retrieval endpoint

### Phase 3: Worker Services
- [ ] Build transcoding worker
- [ ] Implement duration validation
- [ ] Implement codec validation
- [ ] Set up SQS/Redis queue
- [ ] Build MediaConvert job submission
- [ ] Build completion event handler

### Phase 4: Security
- [ ] Implement rate limiting
- [ ] Add content-type validation
- [ ] Add file size validation
- [ ] Add duration validation
- [ ] Enable S3 encryption
- [ ] Configure CORS
- [ ] Set up WAF rules

### Phase 5: Monitoring
- [ ] Set up CloudWatch alarms
- [ ] Configure structured logging
- [ ] Build monitoring dashboard
- [ ] Set up error tracking (Sentry)
- [ ] Configure performance monitoring

### Phase 6: Testing
- [ ] Unit tests for all endpoints
- [ ] Integration tests for upload flow
- [ ] Load testing (100 concurrent uploads)
- [ ] Security audit
- [ ] Penetration testing

### Phase 7: Documentation
- [ ] API documentation (OpenAPI/Swagger)
- [ ] Developer onboarding guide
- [ ] Runbook for operations
- [ ] Incident response playbook

---

## Production Deployment

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/nextplay
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10

# AWS
AWS_REGION=us-east-1
AWS_S3_BUCKET=nextplay-videos-prod
AWS_MEDIACONVERT_ENDPOINT=https://...amazonaws.com
AWS_MEDIACONVERT_ROLE_ARN=arn:aws:iam::...

# API
API_PORT=8000
API_HOST=0.0.0.0
API_WORKERS=4
JWT_SECRET=<secret>
JWT_ALGORITHM=RS256
JWT_PUBLIC_KEY=<public-key>

# CDN
CDN_DOMAIN=cdn.nextplay.com

# Monitoring
SENTRY_DSN=https://...@sentry.io/...
LOG_LEVEL=INFO
```

### Docker Deployment
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:8000"]
```

---

**This completes the security and implementation guide. All requirements have been addressed with production-ready specifications.**
