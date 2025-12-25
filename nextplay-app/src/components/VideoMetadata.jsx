import { useState } from 'react';
import './VideoMetadata.css';

const CATEGORIES = [
  { id: 'sports', label: 'Sports', emoji: '⚽' },
  { id: 'dance', label: 'Dance', emoji: '💃' },
  { id: 'art', label: 'Art', emoji: '🎨' },
  { id: 'comedy', label: 'Comedy', emoji: '🎭' },
  { id: 'stem', label: 'STEM', emoji: '🧪' },
  { id: 'gaming', label: 'Gaming', emoji: '🎮' },
  { id: 'music', label: 'Music', emoji: '🎵' },
  { id: 'fitness', label: 'Fitness', emoji: '💪' }
];

function VideoMetadata({ videoFile, editData, onUpload, onBack }) {
  const [title, setTitle] = useState('');
  const [hashtags, setHashtags] = useState([]);
  const [hashtagInput, setHashtagInput] = useState('');
  const [category, setCategory] = useState('');
  const [visibility, setVisibility] = useState('public');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState(null);

  const handleTitleChange = (e) => {
    const value = e.target.value;
    if (value.length <= 80) {
      setTitle(value);
    }
  };

  const handleHashtagKeyPress = (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      addHashtag();
    }
  };

  const addHashtag = () => {
    const tag = hashtagInput.trim().replace(/^#/, '');
    
    if (tag && hashtags.length < 5 && !hashtags.includes(tag)) {
      setHashtags([...hashtags, tag]);
      setHashtagInput('');
    }
  };

  const removeHashtag = (tag) => {
    setHashtags(hashtags.filter(t => t !== tag));
  };

  const handleUpload = async () => {
    // Validation
    if (!title.trim()) {
      setError('Please enter a title');
      return;
    }

    if (!category) {
      setError('Please select a category');
      return;
    }

    setError(null);
    setIsUploading(true);

    const metadata = {
      title: title.trim(),
      tags: hashtags,
      category,
      visibility,
      ...editData
    };

    try {
      await onUpload(videoFile, metadata, (progress) => {
        setUploadProgress(progress);
      });
    } catch (err) {
      setError(err.message);
      setIsUploading(false);
    }
  };

  return (
    <div className="video-metadata">
      <div className="metadata-header">
        <button onClick={onBack} className="back-button" disabled={isUploading}>
          <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M19 12H5M12 19l-7-7 7-7"/>
          </svg>
        </button>
        <h2>Post Details</h2>
        <div className="header-spacer"></div>
      </div>

      {error && (
        <div className="error-banner">
          <span className="error-icon">⚠️</span>
          {error}
        </div>
      )}

      <div className="metadata-content">
        {isUploading ? (
          <div className="upload-progress-screen">
            <div className="progress-container">
              <div className="progress-circle">
                <svg className="progress-ring" width="120" height="120">
                  <circle
                    className="progress-ring-circle"
                    stroke="#FFD700"
                    strokeWidth="8"
                    fill="transparent"
                    r="52"
                    cx="60"
                    cy="60"
                    style={{
                      strokeDasharray: `${2 * Math.PI * 52}`,
                      strokeDashoffset: `${2 * Math.PI * 52 * (1 - uploadProgress / 100)}`
                    }}
                  />
                </svg>
                <div className="progress-text">{Math.round(uploadProgress)}%</div>
              </div>
              
              <h3 className="upload-title">Uploading...</h3>
              <p className="upload-subtitle">Please don't close this page</p>
              
              <div className="progress-bar-container">
                <div 
                  className="progress-bar" 
                  style={{ width: `${uploadProgress}%` }}
                ></div>
              </div>
            </div>
          </div>
        ) : (
          <>
            {/* Title Input */}
            <div className="form-section">
              <label className="form-label">
                Title <span className="required">*</span>
              </label>
              <input
                type="text"
                value={title}
                onChange={handleTitleChange}
                placeholder="Give your video a title..."
                className="title-input"
                maxLength={80}
              />
              <div className="char-count">{title.length}/80</div>
            </div>

            {/* Hashtags */}
            <div className="form-section">
              <label className="form-label">
                Hashtags <span className="optional">(Optional, max 5)</span>
              </label>
              
              <div className="hashtag-input-container">
                <span className="hashtag-prefix">#</span>
                <input
                  type="text"
                  value={hashtagInput}
                  onChange={(e) => setHashtagInput(e.target.value)}
                  onKeyPress={handleHashtagKeyPress}
                  onBlur={addHashtag}
                  placeholder="Enter hashtag and press Enter"
                  className="hashtag-input"
                  disabled={hashtags.length >= 5}
                />
              </div>

              {hashtags.length > 0 && (
                <div className="hashtag-list">
                  {hashtags.map((tag) => (
                    <div key={tag} className="hashtag-chip">
                      #{tag}
                      <button
                        onClick={() => removeHashtag(tag)}
                        className="remove-hashtag"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Category Selection */}
            <div className="form-section">
              <label className="form-label">
                Category <span className="required">*</span>
              </label>
              
              <div className="category-grid">
                {CATEGORIES.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => setCategory(cat.id)}
                    className={`category-button ${category === cat.id ? 'selected' : ''}`}
                  >
                    <span className="category-emoji">{cat.emoji}</span>
                    <span className="category-label">{cat.label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Visibility */}
            <div className="form-section">
              <label className="form-label">Visibility</label>
              
              <div className="visibility-options">
                <button
                  onClick={() => setVisibility('public')}
                  className={`visibility-button ${visibility === 'public' ? 'selected' : ''}`}
                >
                  <div className="visibility-icon">🌍</div>
                  <div className="visibility-text">
                    <div className="visibility-title">Public</div>
                    <div className="visibility-desc">Everyone can see</div>
                  </div>
                </button>

                <button
                  onClick={() => setVisibility('private')}
                  className={`visibility-button ${visibility === 'private' ? 'selected' : ''}`}
                >
                  <div className="visibility-icon">🔒</div>
                  <div className="visibility-text">
                    <div className="visibility-title">Private</div>
                    <div className="visibility-desc">Only you can see</div>
                  </div>
                </button>
              </div>
            </div>

            {/* Video Info */}
            <div className="video-info-box">
              <div className="info-row">
                <span className="info-label">Duration:</span>
                <span className="info-value">{editData.duration.toFixed(1)}s</span>
              </div>
              <div className="info-row">
                <span className="info-label">Trimmed:</span>
                <span className="info-value">
                  {editData.trimStart.toFixed(1)}s - {editData.trimEnd.toFixed(1)}s
                </span>
              </div>
            </div>

            {/* Upload Button */}
            <button
              onClick={handleUpload}
              className="upload-button"
              disabled={!title.trim() || !category}
            >
              <span className="upload-icon">🚀</span>
              Post Video
            </button>

            {/* Safety Notice */}
            <div className="safety-notice">
              <p>🛡️ Your video will be processed and published after review.</p>
              <p>📍 No location data is collected or shared.</p>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default VideoMetadata;
