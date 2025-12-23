import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './ContentPreferencesScreen.css';

function ContentPreferencesScreen() {
  const navigate = useNavigate();
  const [selectedInterests, setSelectedInterests] = useState(['Sports']);

  const interests = [
    { id: 'sports', name: 'Sports', icon: '⚽🏀' },
    { id: 'dance', name: 'Dance', icon: '💃🕺' },
    { id: 'art', name: 'Art', icon: '🎨🖌️' },
    { id: 'stem', name: 'STEM', icon: '🧪🔬' },
    { id: 'gaming', name: 'Gaming', icon: '🎮🕹️' },
    { id: 'music', name: 'Music', icon: '🎵🎧' },
    { id: 'fitness', name: 'Fitness', icon: '💪🏋️' }
  ];

  const toggleInterest = (interest) => {
    setSelectedInterests(prev => {
      if (prev.includes(interest)) {
        return prev.filter(i => i !== interest);
      } else {
        return [...prev, interest];
      }
    });
  };

  const handleContinue = () => {
    // Store interests in localStorage
    localStorage.setItem('interests', JSON.stringify(selectedInterests));
    navigate('/ad-transparency');
  };

  return (
    <div className="screen-container content-preferences-screen">
      <div className="logo-container small-logo">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" style={{ maxWidth: '250px' }} />
      </div>

      <div className="content-box wide-box">
        <h1 className="title">What are you into?</h1>
        <p className="subtitle">This helps build your feed. You can change this anytime.</p>

        <div className="interests-grid">
          {interests.map((interest) => (
            <button
              key={interest.id}
              className={`interest-card ${selectedInterests.includes(interest.name) ? 'selected' : ''}`}
              onClick={() => toggleInterest(interest.name)}
            >
              <div className="interest-icon">{interest.icon}</div>
              <div className="interest-name">{interest.name}</div>
              {selectedInterests.includes(interest.name) && (
                <div className="checkmark">✓</div>
              )}
            </button>
          ))}
        </div>

        <button className="primary-button" onClick={handleContinue}>
          Continue
        </button>

        <p className="footer-text academy-footer">
          <span className="academy-icon">⚠️</span> Player 1 Academy App
        </p>
      </div>
    </div>
  );
}

export default ContentPreferencesScreen;
