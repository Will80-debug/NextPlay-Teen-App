import { useState, useRef, useEffect } from 'react';
import './VideoRecorder.css';
import uploadService from '../services/uploadService';

function VideoRecorder({ onVideoRecorded, onClose }) {
  const [isRecording, setIsRecording] = useState(false);
  const [timeLeft, setTimeLeft] = useState(30);
  const [stream, setStream] = useState(null);
  const [error, setError] = useState(null);
  const [facingMode, setFacingMode] = useState('user'); // 'user' or 'environment'
  
  const videoRef = useRef(null);
  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  const timerRef = useRef(null);

  useEffect(() => {
    startCamera();
    return () => {
      stopCamera();
    };
  }, [facingMode]);

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { 
          facingMode: facingMode,
          width: { ideal: 1080 },
          height: { ideal: 1920 }
        },
        audio: true
      });
      
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
      setError(null);
    } catch (err) {
      console.error('Camera error:', err);
      setError('Camera access denied. Please enable camera permissions in your browser settings.');
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
  };

  const startRecording = () => {
    if (!stream) return;

    // Track analytics
    uploadService.trackEvent('record_started');

    chunksRef.current = [];
    
    const options = {
      mimeType: 'video/webm;codecs=vp9',
      videoBitsPerSecond: 2500000
    };

    try {
      const mediaRecorder = new MediaRecorder(stream, options);
      mediaRecorderRef.current = mediaRecorder;

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'video/webm' });
        const file = new File([blob], 'recording.webm', { type: 'video/webm' });
        onVideoRecorded(file);
      };

      mediaRecorder.start();
      setIsRecording(true);
      setTimeLeft(30);

      // Start countdown timer
      timerRef.current = setInterval(() => {
        setTimeLeft(prev => {
          if (prev <= 1) {
            stopRecording();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

    } catch (err) {
      console.error('Recording error:', err);
      setError('Failed to start recording');
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    }
  };

  const flipCamera = () => {
    setFacingMode(prev => prev === 'user' ? 'environment' : 'user');
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="video-recorder">
      <div className="recorder-container">
        {/* Video Preview */}
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted
          className="camera-preview"
        />

        {/* Error Message */}
        {error && (
          <div className="error-overlay">
            <div className="error-message">
              <span className="error-icon">⚠️</span>
              <p>{error}</p>
              <button onClick={startCamera} className="retry-button">
                Retry
              </button>
            </div>
          </div>
        )}

        {/* Recording Timer */}
        {isRecording && (
          <div className="recording-timer">
            <div className="recording-dot"></div>
            <span className="timer-text">{formatTime(timeLeft)}</span>
          </div>
        )}

        {/* Top Controls */}
        <div className="top-controls">
          <button onClick={onClose} className="close-button">
            <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M6 6l12 12M6 18L18 6"/>
            </svg>
          </button>

          <button onClick={flipCamera} className="flip-button" disabled={isRecording}>
            <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M3 12h18M3 12l4-4M3 12l4 4M21 12l-4-4M21 12l-4 4"/>
            </svg>
          </button>
        </div>

        {/* Bottom Controls */}
        <div className="bottom-controls">
          <div className="control-spacer"></div>
          
          {/* Record Button */}
          <button
            onClick={isRecording ? stopRecording : startRecording}
            className={`record-button ${isRecording ? 'recording' : ''}`}
            disabled={!!error}
          >
            <div className="record-button-outer">
              <div className="record-button-inner"></div>
            </div>
          </button>

          <div className="control-spacer"></div>
        </div>

        {/* Instructions */}
        {!isRecording && !error && (
          <div className="instructions">
            <p>Tap the button to start recording</p>
            <p className="max-duration">Maximum: 30 seconds</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default VideoRecorder;
