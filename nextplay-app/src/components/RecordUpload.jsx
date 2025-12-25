import { useState } from 'react';
import VideoRecorder from './VideoRecorder';
import VideoEditor from './VideoEditor';
import VideoMetadata from './VideoMetadata';
import uploadService from '../services/uploadService';
import './RecordUpload.css';

function RecordUpload({ onClose, onSuccess }) {
  const [step, setStep] = useState('choice'); // choice, record, upload, edit, metadata, processing, success, error
  const [videoFile, setVideoFile] = useState(null);
  const [editData, setEditData] = useState(null);
  const [uploadResult, setUploadResult] = useState(null);
  const [error, setError] = useState(null);
  const [processingStatus, setProcessingStatus] = useState('processing');

  const handleChoiceRecord = () => {
    setStep('record');
  };

  const handleChoiceUpload = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'video/*';
    
    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (file) {
        try {
          // Validate duration
          await uploadService.validateVideoDuration(file);
          setVideoFile(file);
          setStep('edit');
        } catch (err) {
          // If duration > 30s, still allow but force trim
          setVideoFile(file);
          setStep('edit');
        }
      }
    };
    
    input.click();
  };

  const handleVideoRecorded = (file) => {
    setVideoFile(file);
    setStep('edit');
  };

  const handleEditNext = (data) => {
    setEditData(data);
    setStep('metadata');
  };

  const handleUpload = async (file, metadata, onProgress) => {
    try {
      // Add cover frame from edit data
      if (editData?.coverFrame) {
        metadata.coverFrame = editData.coverFrame;
      }
      
      // Upload video
      const result = await uploadService.uploadVideo(file, metadata, onProgress);
      
      setUploadResult(result);
      setStep('processing');
      
      // Start polling for processing status
      pollProcessingStatus(result.videoId);
      
    } catch (err) {
      setError(err.message);
      setStep('error');
    }
  };

  const pollProcessingStatus = async (videoId) => {
    const maxAttempts = 60; // 5 minutes max (60 * 5s)
    let attempts = 0;

    const checkStatus = async () => {
      try {
        const status = await uploadService.checkProcessingStatus(videoId);
        
        if (status.state === 'completed') {
          setProcessingStatus('completed');
          setStep('success');
          
          // Auto-publish after processing
          await uploadService.publishVideo(videoId);
          
          // Wait 2 seconds then callback
          setTimeout(() => {
            if (onSuccess) {
              onSuccess(status);
            } else {
              onClose();
            }
          }, 2000);
          
        } else if (status.state === 'failed') {
          setError('Video processing failed. Please try again.');
          setStep('error');
          
        } else if (attempts < maxAttempts) {
          // Still processing, check again in 5 seconds
          attempts++;
          setTimeout(checkStatus, 5000);
        } else {
          setError('Processing is taking longer than expected. Your video will appear in your profile once ready.');
          setStep('error');
        }
      } catch (err) {
        setError('Failed to check processing status.');
        setStep('error');
      }
    };

    checkStatus();
  };

  const handleBack = () => {
    if (step === 'edit') {
      setStep('choice');
      setVideoFile(null);
    } else if (step === 'metadata') {
      setStep('edit');
    }
  };

  const handleRetry = () => {
    setStep('choice');
    setVideoFile(null);
    setEditData(null);
    setError(null);
  };

  return (
    <>
      {step === 'choice' && (
        <div className="record-upload-choice">
          <div className="choice-overlay" onClick={onClose}></div>
          <div className="choice-modal">
            <button className="modal-close" onClick={onClose}>
              <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M6 6l12 12M6 18L18 6"/>
              </svg>
            </button>

            <h2 className="choice-title">Create Video</h2>
            <p className="choice-subtitle">Maximum 30 seconds</p>

            <div className="choice-buttons">
              <button onClick={handleChoiceRecord} className="choice-button">
                <div className="button-icon">📹</div>
                <div className="button-text">
                  <div className="button-title">Record</div>
                  <div className="button-desc">Use camera to record</div>
                </div>
              </button>

              <button onClick={handleChoiceUpload} className="choice-button">
                <div className="button-icon">📁</div>
                <div className="button-text">
                  <div className="button-title">Upload</div>
                  <div className="button-desc">Choose from library</div>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}

      {step === 'record' && (
        <VideoRecorder
          onVideoRecorded={handleVideoRecorded}
          onClose={() => setStep('choice')}
        />
      )}

      {step === 'edit' && videoFile && (
        <VideoEditor
          videoFile={videoFile}
          onNext={handleEditNext}
          onBack={handleBack}
        />
      )}

      {step === 'metadata' && videoFile && editData && (
        <VideoMetadata
          videoFile={videoFile}
          editData={editData}
          onUpload={handleUpload}
          onBack={handleBack}
        />
      )}

      {step === 'processing' && (
        <div className="processing-screen">
          <div className="processing-content">
            <div className="spinner-container">
              <div className="spinner"></div>
            </div>
            <h2 className="processing-title">Processing Video...</h2>
            <p className="processing-subtitle">
              This may take a minute. Please don't close this page.
            </p>
            <div className="processing-steps">
              <div className="step completed">
                <span className="step-icon">✓</span>
                <span>Upload Complete</span>
              </div>
              <div className="step active">
                <span className="step-icon">⏳</span>
                <span>Transcoding Video</span>
              </div>
              <div className="step">
                <span className="step-icon">○</span>
                <span>Publishing</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {step === 'success' && (
        <div className="success-screen">
          <div className="success-content">
            <div className="success-icon">🎉</div>
            <h2 className="success-title">Posted Successfully!</h2>
            <p className="success-subtitle">Your video is now live</p>
            <button onClick={onClose} className="success-button">
              Done
            </button>
          </div>
        </div>
      )}

      {step === 'error' && (
        <div className="error-screen">
          <div className="error-content">
            <div className="error-icon">⚠️</div>
            <h2 className="error-title">Upload Failed</h2>
            <p className="error-message">{error}</p>
            <div className="error-actions">
              <button onClick={handleRetry} className="retry-button">
                Try Again
              </button>
              <button onClick={onClose} className="cancel-button">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default RecordUpload;
