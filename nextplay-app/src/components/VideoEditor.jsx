import { useState, useRef, useEffect } from 'react';
import './VideoEditor.css';

function VideoEditor({ videoFile, onNext, onBack }) {
  const [duration, setDuration] = useState(0);
  const [trimStart, setTrimStart] = useState(0);
  const [trimEnd, setTrimEnd] = useState(0);
  const [coverTime, setCoverTime] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [videoUrl, setVideoUrl] = useState('');
  const [coverFrame, setCoverFrame] = useState(null);
  const [error, setError] = useState(null);

  const videoRef = useRef(null);
  const canvasRef = useRef(null);

  useEffect(() => {
    const url = URL.createObjectURL(videoFile);
    setVideoUrl(url);

    return () => {
      URL.revokeObjectURL(url);
    };
  }, [videoFile]);

  const handleLoadedMetadata = () => {
    const vid = videoRef.current;
    if (vid) {
      const dur = vid.duration;
      setDuration(dur);
      
      if (dur > 30.0) {
        // Force user to trim
        setTrimStart(0);
        setTrimEnd(30.0);
        setError(`Video is ${dur.toFixed(1)}s. Please trim to 30 seconds or less.`);
      } else {
        setTrimStart(0);
        setTrimEnd(dur);
      }
      
      setCoverTime(0);
      generateCoverFrame(0);
    }
  };

  const generateCoverFrame = (time) => {
    const video = videoRef.current;
    const canvas = canvasRef.current;
    
    if (video && canvas) {
      video.currentTime = time;
      
      video.onseeked = () => {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0);
        
        canvas.toBlob((blob) => {
          setCoverFrame(blob);
        }, 'image/jpeg', 0.9);
      };
    }
  };

  const handleTrimStartChange = (e) => {
    const value = parseFloat(e.target.value);
    setTrimStart(value);
    
    if (trimEnd - value > 30.0) {
      setTrimEnd(value + 30.0);
    }
    
    validateTrim(value, trimEnd);
  };

  const handleTrimEndChange = (e) => {
    const value = parseFloat(e.target.value);
    setTrimEnd(value);
    
    if (value - trimStart > 30.0) {
      setTrimStart(value - 30.0);
    }
    
    validateTrim(trimStart, value);
  };

  const validateTrim = (start, end) => {
    const finalDuration = end - start;
    if (finalDuration > 30.0) {
      setError('Final video must be 30 seconds or less');
    } else {
      setError(null);
    }
  };

  const handleCoverTimeChange = (e) => {
    const time = parseFloat(e.target.value);
    setCoverTime(time);
    generateCoverFrame(time);
  };

  const togglePlay = () => {
    const video = videoRef.current;
    if (video) {
      if (isPlaying) {
        video.pause();
      } else {
        video.currentTime = trimStart;
        video.play();
      }
      setIsPlaying(!isPlaying);
    }
  };

  const handleTimeUpdate = () => {
    const video = videoRef.current;
    if (video) {
      setCurrentTime(video.currentTime);
      
      // Stop at trim end
      if (video.currentTime >= trimEnd) {
        video.pause();
        video.currentTime = trimStart;
        setIsPlaying(false);
      }
    }
  };

  const handleNext = () => {
    const finalDuration = trimEnd - trimStart;
    
    if (finalDuration > 30.0) {
      setError('Please trim video to 30 seconds or less before continuing');
      return;
    }

    onNext({
      trimStart,
      trimEnd,
      duration: finalDuration,
      coverFrame
    });
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="video-editor">
      <div className="editor-header">
        <button onClick={onBack} className="back-button">
          <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M19 12H5M12 19l-7-7 7-7"/>
          </svg>
        </button>
        <h2>Edit Video</h2>
        <button onClick={handleNext} className="next-button" disabled={!!error}>
          Next
        </button>
      </div>

      {error && (
        <div className="error-banner">
          <span className="error-icon">⚠️</span>
          {error}
        </div>
      )}

      <div className="editor-content">
        {/* Video Preview */}
        <div className="video-preview-section">
          <video
            ref={videoRef}
            src={videoUrl}
            className="preview-video"
            onLoadedMetadata={handleLoadedMetadata}
            onTimeUpdate={handleTimeUpdate}
            onClick={togglePlay}
          />
          
          {!isPlaying && (
            <button className="play-overlay" onClick={togglePlay}>
              <svg width="64" height="64" fill="currentColor">
                <path d="M20 10v44l34-22z"/>
              </svg>
            </button>
          )}

          <canvas ref={canvasRef} style={{ display: 'none' }} />
        </div>

        {/* Editing Controls */}
        <div className="editing-controls">
          {/* Duration Info */}
          <div className="duration-info">
            <div className="info-row">
              <span className="label">Original:</span>
              <span className="value">{formatTime(duration)}</span>
            </div>
            <div className="info-row">
              <span className="label">Final:</span>
              <span className={`value ${(trimEnd - trimStart) > 30 ? 'error' : 'success'}`}>
                {formatTime(trimEnd - trimStart)}
              </span>
            </div>
          </div>

          {/* Trim Controls */}
          <div className="control-group">
            <h3>Trim Video</h3>
            <div className="trim-controls">
              <div className="slider-group">
                <label>Start: {formatTime(trimStart)}</label>
                <input
                  type="range"
                  min="0"
                  max={duration}
                  step="0.1"
                  value={trimStart}
                  onChange={handleTrimStartChange}
                  className="slider"
                />
              </div>
              
              <div className="slider-group">
                <label>End: {formatTime(trimEnd)}</label>
                <input
                  type="range"
                  min="0"
                  max={duration}
                  step="0.1"
                  value={trimEnd}
                  onChange={handleTrimEndChange}
                  className="slider"
                />
              </div>
            </div>
          </div>

          {/* Cover Frame Selection */}
          <div className="control-group">
            <h3>Cover Frame</h3>
            <div className="cover-selection">
              <div className="slider-group">
                <label>Select at: {formatTime(coverTime)}</label>
                <input
                  type="range"
                  min={trimStart}
                  max={trimEnd}
                  step="0.1"
                  value={coverTime}
                  onChange={handleCoverTimeChange}
                  className="slider"
                />
              </div>
              
              {coverFrame && (
                <div className="cover-preview">
                  <img 
                    src={URL.createObjectURL(coverFrame)} 
                    alt="Cover frame"
                    className="cover-thumbnail"
                  />
                  <span className="cover-label">Selected Cover</span>
                </div>
              )}
            </div>
          </div>

          {/* Instructions */}
          <div className="instructions-box">
            <p>🎬 Adjust sliders to trim your video to 30 seconds or less</p>
            <p>🖼️ Choose a cover frame that represents your video</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default VideoEditor;
