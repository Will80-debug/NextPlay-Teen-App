-- NextPlay Video Upload Backend - PostgreSQL Schema
-- Version: 1.0.0
-- Date: 2025-12-25

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TYPE age_band AS ENUM ('13-15', '16-17', '18+');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age_band age_band NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Auth fields
    auth_provider VARCHAR(50) NOT NULL, -- 'email', 'apple', 'google'
    auth_provider_id VARCHAR(255),
    
    -- Profile
    avatar_url TEXT,
    bio TEXT,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    
    -- Safety settings
    account_private BOOLEAN NOT NULL DEFAULT true, -- Default private for 13-15
    allow_comments BOOLEAN NOT NULL DEFAULT true,
    allow_messages BOOLEAN NOT NULL DEFAULT false,
    
    -- Constraints
    CONSTRAINT valid_handle CHECK (handle ~ '^[a-zA-Z0-9_]{3,30}$')
);

CREATE INDEX idx_users_handle ON users(handle);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- ============================================================================
-- VIDEOS TABLE
-- ============================================================================
CREATE TYPE video_status AS ENUM (
    'DRAFT',              -- Initial creation
    'UPLOADING',          -- Upload in progress
    'UPLOADED',           -- Upload complete, pending processing
    'PROCESSING',         -- Transcoding in progress
    'READY',              -- Transcoding complete, ready to publish
    'PUBLISHED',          -- Published and visible
    'PROCESSING_FAILED',  -- Transcoding failed
    'REJECTED_TOO_LONG',  -- Duration > 30 seconds
    'REJECTED_FORMAT',    -- Invalid format/codec
    'DELETED'             -- Soft delete
);

CREATE TYPE video_category AS ENUM (
    'sports', 'dance', 'art', 'comedy', 'stem', 'gaming', 'music', 'fitness'
);

CREATE TYPE video_visibility AS ENUM ('public', 'private', 'unlisted');

CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Metadata
    title VARCHAR(80) NOT NULL,
    caption TEXT,
    category video_category NOT NULL,
    visibility video_visibility NOT NULL DEFAULT 'public',
    
    -- Video properties
    duration_ms INTEGER, -- Duration in milliseconds (NULL until processed)
    width INTEGER,
    height INTEGER,
    fps DECIMAL(5,2),
    
    -- Status
    status video_status NOT NULL DEFAULT 'DRAFT',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    
    -- Engagement metrics
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    view_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    
    -- Moderation
    moderation_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    moderation_reviewed_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_duration CHECK (duration_ms IS NULL OR duration_ms <= 30000),
    CONSTRAINT valid_title_length CHECK (LENGTH(title) > 0 AND LENGTH(title) <= 80),
    CONSTRAINT published_has_timestamp CHECK (
        (status = 'PUBLISHED' AND published_at IS NOT NULL) OR 
        (status != 'PUBLISHED' AND published_at IS NULL)
    )
);

CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_videos_category ON videos(category);
CREATE INDEX idx_videos_created_at ON videos(created_at DESC);
CREATE INDEX idx_videos_published_at ON videos(published_at DESC) WHERE published_at IS NOT NULL;
CREATE INDEX idx_videos_visibility ON videos(visibility);

-- ============================================================================
-- VIDEO_ASSETS TABLE
-- ============================================================================
CREATE TYPE asset_kind AS ENUM (
    'ORIGINAL',    -- Original uploaded file
    'HLS',         -- HLS manifest and segments
    'MP4_720',     -- 720p MP4
    'MP4_480',     -- 480p MP4
    'MP4_240',     -- 240p MP4
    'THUMB',       -- Thumbnail image
    'PREVIEW'      -- 3-5 second preview clip
);

CREATE TABLE video_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    
    -- Asset details
    kind asset_kind NOT NULL,
    url TEXT NOT NULL, -- CDN URL
    s3_bucket VARCHAR(255) NOT NULL,
    s3_key TEXT NOT NULL,
    
    -- Video properties (NULL for thumbnails)
    width INTEGER,
    height INTEGER,
    bitrate_kbps INTEGER,
    file_size_bytes BIGINT,
    codec VARCHAR(50),
    container VARCHAR(20),
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(video_id, kind)
);

CREATE INDEX idx_video_assets_video_id ON video_assets(video_id);
CREATE INDEX idx_video_assets_kind ON video_assets(kind);

-- ============================================================================
-- UPLOADS TABLE
-- ============================================================================
CREATE TYPE upload_status AS ENUM (
    'INITIATED',    -- Upload session created
    'IN_PROGRESS',  -- Parts being uploaded
    'COMPLETING',   -- Complete API called, assembling parts
    'COMPLETED',    -- Upload successful
    'FAILED',       -- Upload failed
    'EXPIRED',      -- Upload session expired
    'ABORTED'       -- User cancelled
);

CREATE TABLE uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    
    -- S3 multipart upload details
    s3_bucket VARCHAR(255) NOT NULL,
    s3_key TEXT NOT NULL,
    s3_upload_id VARCHAR(255) NOT NULL, -- AWS multipart upload ID
    
    -- Upload metadata
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    total_parts INTEGER NOT NULL,
    
    -- Status
    status upload_status NOT NULL DEFAULT 'INITIATED',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '1 hour'),
    
    -- Error tracking
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    
    -- Constraints
    CONSTRAINT valid_file_size CHECK (file_size_bytes > 0 AND file_size_bytes <= 157286400), -- 150MB
    CONSTRAINT valid_content_type CHECK (content_type IN ('video/mp4', 'video/quicktime', 'video/webm'))
);

CREATE INDEX idx_uploads_user_id ON uploads(user_id);
CREATE INDEX idx_uploads_video_id ON uploads(video_id);
CREATE INDEX idx_uploads_status ON uploads(status);
CREATE INDEX idx_uploads_created_at ON uploads(created_at DESC);
CREATE INDEX idx_uploads_expires_at ON uploads(expires_at) WHERE status IN ('INITIATED', 'IN_PROGRESS');

-- ============================================================================
-- UPLOAD_PARTS TABLE (Track multipart upload progress)
-- ============================================================================
CREATE TABLE upload_parts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_id UUID NOT NULL REFERENCES uploads(id) ON DELETE CASCADE,
    
    -- Part details
    part_number INTEGER NOT NULL,
    etag VARCHAR(255), -- S3 ETag after upload
    size_bytes BIGINT,
    
    -- Status
    is_uploaded BOOLEAN NOT NULL DEFAULT false,
    uploaded_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(upload_id, part_number)
);

CREATE INDEX idx_upload_parts_upload_id ON upload_parts(upload_id);

-- ============================================================================
-- VIDEO_TAGS TABLE
-- ============================================================================
CREATE TABLE video_tags (
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (video_id, tag),
    CONSTRAINT max_tags_per_video CHECK (
        (SELECT COUNT(*) FROM video_tags WHERE video_id = video_tags.video_id) <= 5
    )
);

CREATE INDEX idx_video_tags_tag ON video_tags(tag);
CREATE INDEX idx_video_tags_video_id ON video_tags(video_id);

-- ============================================================================
-- MODERATION_FLAGS TABLE
-- ============================================================================
CREATE TYPE moderation_status AS ENUM (
    'pending',      -- Awaiting review
    'approved',     -- Content approved
    'rejected',     -- Content rejected
    'appealed',     -- User appealed rejection
    'auto_approved' -- Auto-approved by AI
);

CREATE TABLE moderation_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    
    -- Moderation details
    status moderation_status NOT NULL DEFAULT 'pending',
    reason TEXT,
    flagged_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- AI moderation scores (0-1, higher = more likely inappropriate)
    ai_violence_score DECIMAL(3,2),
    ai_adult_score DECIMAL(3,2),
    ai_hate_score DECIMAL(3,2),
    
    -- Review
    reviewed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    reviewer_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_moderation_flags_video_id ON moderation_flags(video_id);
CREATE INDEX idx_moderation_flags_status ON moderation_flags(status);
CREATE INDEX idx_moderation_flags_created_at ON moderation_flags(created_at DESC);

-- ============================================================================
-- TRANSCODE_JOBS TABLE
-- ============================================================================
CREATE TYPE transcode_status AS ENUM (
    'QUEUED',       -- Job queued for processing
    'PROCESSING',   -- Transcoding in progress
    'COMPLETED',    -- Transcoding successful
    'FAILED',       -- Transcoding failed
    'CANCELLED'     -- Job cancelled
);

CREATE TABLE transcode_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    upload_id UUID NOT NULL REFERENCES uploads(id) ON DELETE CASCADE,
    
    -- Job details
    job_id VARCHAR(255), -- AWS MediaConvert job ID
    status transcode_status NOT NULL DEFAULT 'QUEUED',
    
    -- Input/output
    input_s3_key TEXT NOT NULL,
    output_s3_prefix TEXT NOT NULL,
    
    -- Progress
    progress_percent INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Error tracking
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    
    -- Metrics
    duration_ms INTEGER,
    input_size_bytes BIGINT,
    output_size_bytes BIGINT
);

CREATE INDEX idx_transcode_jobs_video_id ON transcode_jobs(video_id);
CREATE INDEX idx_transcode_jobs_status ON transcode_jobs(status);
CREATE INDEX idx_transcode_jobs_created_at ON transcode_jobs(created_at DESC);

-- ============================================================================
-- RATE_LIMITS TABLE
-- ============================================================================
CREATE TABLE rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Limit type
    action VARCHAR(50) NOT NULL, -- 'upload_initiate', 'publish_video', etc.
    
    -- Window
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    
    -- Count
    request_count INTEGER NOT NULL DEFAULT 1,
    max_requests INTEGER NOT NULL, -- e.g., 10 for uploads/hour
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, action, window_start)
);

CREATE INDEX idx_rate_limits_user_action ON rate_limits(user_id, action);
CREATE INDEX idx_rate_limits_window_end ON rate_limits(window_end);

-- ============================================================================
-- ANALYTICS_EVENTS TABLE
-- ============================================================================
CREATE TABLE analytics_events (
    id BIGSERIAL PRIMARY KEY,
    
    -- Event details
    event_name VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
    
    -- Metadata
    metadata JSONB,
    
    -- Client info
    user_agent TEXT,
    ip_address INET,
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_analytics_events_event_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_video_id ON analytics_events(video_id);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_videos_updated_at BEFORE UPDATE ON videos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-set account_private based on age_band
CREATE OR REPLACE FUNCTION set_default_privacy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.age_band = '13-15' THEN
        NEW.account_private = true;
        NEW.allow_messages = false;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_user_privacy BEFORE INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION set_default_privacy();

-- Validate video duration before publish
CREATE OR REPLACE FUNCTION validate_video_publish()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'PUBLISHED' AND OLD.status != 'PUBLISHED' THEN
        IF NEW.duration_ms IS NULL THEN
            RAISE EXCEPTION 'Cannot publish video without duration';
        END IF;
        
        IF NEW.duration_ms > 30000 THEN
            RAISE EXCEPTION 'Video duration exceeds 30 second limit';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM video_assets WHERE video_id = NEW.id AND kind = 'MP4_720') THEN
            RAISE EXCEPTION 'Cannot publish video without transcoded assets';
        END IF;
        
        NEW.published_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_video_before_publish BEFORE UPDATE ON videos
    FOR EACH ROW EXECUTE FUNCTION validate_video_publish();

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Check rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action VARCHAR(50),
    p_max_requests INTEGER,
    p_window_duration INTERVAL
) RETURNS BOOLEAN AS $$
DECLARE
    v_window_start TIMESTAMPTZ;
    v_window_end TIMESTAMPTZ;
    v_current_count INTEGER;
BEGIN
    v_window_end = NOW();
    v_window_start = v_window_end - p_window_duration;
    
    -- Get current count for this window
    SELECT COALESCE(SUM(request_count), 0) INTO v_current_count
    FROM rate_limits
    WHERE user_id = p_user_id
      AND action = p_action
      AND window_end > v_window_start;
    
    -- Return true if under limit
    RETURN v_current_count < p_max_requests;
END;
$$ LANGUAGE plpgsql;

-- Increment rate limit counter
CREATE OR REPLACE FUNCTION increment_rate_limit(
    p_user_id UUID,
    p_action VARCHAR(50),
    p_max_requests INTEGER,
    p_window_duration INTERVAL
) RETURNS VOID AS $$
DECLARE
    v_window_start TIMESTAMPTZ;
    v_window_end TIMESTAMPTZ;
BEGIN
    v_window_end = NOW();
    v_window_start = v_window_end - p_window_duration;
    
    INSERT INTO rate_limits (user_id, action, window_start, window_end, request_count, max_requests)
    VALUES (p_user_id, p_action, v_window_start, v_window_end, 1, p_max_requests)
    ON CONFLICT (user_id, action, window_start)
    DO UPDATE SET
        request_count = rate_limits.request_count + 1,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Clean up expired uploads
CREATE OR REPLACE FUNCTION cleanup_expired_uploads() RETURNS void AS $$
BEGIN
    UPDATE uploads
    SET status = 'EXPIRED'
    WHERE status IN ('INITIATED', 'IN_PROGRESS')
      AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE DATA (for development)
-- ============================================================================

-- Insert sample user
INSERT INTO users (handle, email, age_band, auth_provider, is_verified)
VALUES 
    ('test_user_1', 'test1@nextplay.com', '16-17', 'email', true),
    ('test_user_2', 'test2@nextplay.com', '18+', 'apple', true),
    ('test_user_3', 'test3@nextplay.com', '13-15', 'google', true)
ON CONFLICT (email) DO NOTHING;

-- Grant permissions (adjust as needed for your environment)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nextplay_api;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nextplay_api;

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

CREATE OR REPLACE VIEW video_stats AS
SELECT 
    v.id,
    v.user_id,
    u.handle,
    v.title,
    v.category,
    v.status,
    v.duration_ms,
    v.like_count,
    v.comment_count,
    v.view_count,
    v.created_at,
    v.published_at,
    COUNT(DISTINCT va.id) as asset_count,
    ARRAY_AGG(DISTINCT va.kind) as available_assets
FROM videos v
JOIN users u ON v.user_id = u.id
LEFT JOIN video_assets va ON v.id = va.video_id
GROUP BY v.id, u.handle;

-- ============================================================================
-- MAINTENANCE JOBS (run via cron)
-- ============================================================================

-- Clean up expired uploads (run every 10 minutes)
-- SELECT cleanup_expired_uploads();

-- Clean up old rate limit records (run daily)
-- DELETE FROM rate_limits WHERE window_end < NOW() - INTERVAL '7 days';

-- Clean up old analytics events (run weekly)
-- DELETE FROM analytics_events WHERE created_at < NOW() - INTERVAL '90 days';

COMMENT ON TABLE users IS 'User accounts with age-banded privacy settings';
COMMENT ON TABLE videos IS 'Video metadata and status tracking';
COMMENT ON TABLE video_assets IS 'Transcoded video renditions and thumbnails';
COMMENT ON TABLE uploads IS 'S3 multipart upload sessions';
COMMENT ON TABLE upload_parts IS 'Individual parts of multipart uploads';
COMMENT ON TABLE video_tags IS 'User-defined hashtags for videos';
COMMENT ON TABLE moderation_flags IS 'Content moderation tracking';
COMMENT ON TABLE transcode_jobs IS 'Video transcoding job tracking';
COMMENT ON TABLE rate_limits IS 'API rate limiting by user and action';
COMMENT ON TABLE analytics_events IS 'First-party analytics events';
