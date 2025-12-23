import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './SafetySettingsScreen.css';

function SafetySettingsScreen() {
  const navigate = useNavigate();
  const [ageBand, setAgeBand] = useState('13-15');
  const [settings, setSettings] = useState({
    comments: 'people-you-follow',
    messages: 'no-one',
    mentions: false,
    visibility: 'private'
  });

  useEffect(() => {
    // Get age band from localStorage
    const storedAgeBand = localStorage.getItem('ageBand') || '13-15';
    setAgeBand(storedAgeBand);

    // Set appropriate defaults based on age
    if (storedAgeBand === '16-17') {
      setSettings({
        comments: 'people-you-follow',
        messages: 'people-you-follow',
        mentions: false,
        visibility: 'private'
      });
    }
  }, []);

  const handleSettingChange = (setting, value) => {
    setSettings(prev => ({ ...prev, [setting]: value }));
  };

  const handleContinue = () => {
    // Store settings in localStorage
    localStorage.setItem('safetySettings', JSON.stringify(settings));
    navigate('/content-preferences');
  };

  return (
    <div className="screen-container safety-settings-screen">
      <div className="logo-container small-logo">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" style={{ maxWidth: '250px' }} />
      </div>

      <div className="content-box wide-box">
        <h1 className="title">Choose your safety settings</h1>
        <p className="subtitle">We've set safe defaults for you. You can change these later.</p>

        <div className="settings-grid">
          <div className="setting-item">
            <label className="setting-label">Who can comment?</label>
            <select 
              className="setting-select"
              value={settings.comments}
              onChange={(e) => handleSettingChange('comments', e.target.value)}
            >
              <option value="no-one">No one</option>
              <option value="people-you-follow">People you follow</option>
              <option value="everyone">Everyone</option>
            </select>
          </div>

          <div className="setting-item">
            <label className="setting-label">Who can message you?</label>
            <select 
              className="setting-select"
              value={settings.messages}
              onChange={(e) => handleSettingChange('messages', e.target.value)}
            >
              <option value="no-one">No one</option>
              <option value="people-you-follow">People you follow</option>
            </select>
          </div>

          <div className="setting-item">
            <label className="setting-label">Allow mentions/tags?</label>
            <div className="toggle-container">
              <button 
                className={`toggle-button ${settings.mentions ? 'active' : ''}`}
                onClick={() => handleSettingChange('mentions', !settings.mentions)}
              >
                <span className="toggle-slider"></span>
              </button>
              <span className="toggle-text">{settings.mentions ? 'On' : 'Off'}</span>
            </div>
          </div>

          <div className="setting-item">
            <label className="setting-label">Account visibility</label>
            <select 
              className="setting-select"
              value={settings.visibility}
              onChange={(e) => handleSettingChange('visibility', e.target.value)}
            >
              <option value="private">Private</option>
              <option value="public">Public</option>
            </select>
          </div>
        </div>

        <button className="primary-button" onClick={handleContinue}>
          Continue
        </button>

        <p className="footer-text">
          These settings help keep you safe on NextPlay. You can adjust them anytime in your profile settings.
        </p>
      </div>
    </div>
  );
}

export default SafetySettingsScreen;
