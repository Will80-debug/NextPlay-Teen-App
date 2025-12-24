import { useState } from 'react';
import './HomeScreen.css';

function HomeScreen() {
  const [activeTab, setActiveTab] = useState('feed');

  const challenges = [
    { 
      id: 1, 
      title: 'Create a Funny Skit!', 
      image: '🎭',
      thumbnail: 'https://picsum.photos/400/300?random=1',
      stars: 2 
    },
    { 
      id: 2, 
      title: 'Dance Party!', 
      image: '💃',
      thumbnail: 'https://picsum.photos/400/300?random=2',
      stars: 3 
    },
    { 
      id: 3, 
      title: 'Edit Like a Pro!', 
      image: '📹',
      thumbnail: 'https://picsum.photos/400/300?random=3',
      stars: 3 
    },
    { 
      id: 4, 
      title: 'STEM Experiment', 
      image: '🧪',
      thumbnail: 'https://picsum.photos/400/300?random=4',
      stars: 2 
    }
  ];

  return (
    <div className="home-screen">
      {/* Header with logo */}
      <div className="home-header">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="home-logo" />
      </div>

      {/* Tab Navigation */}
      <div className="tab-navigation">
        <button 
          className={`tab-button ${activeTab === 'feed' ? 'active' : ''}`}
          onClick={() => setActiveTab('feed')}
        >
          Feed
        </button>
        <span className="tab-divider">|</span>
        <button 
          className={`tab-button ${activeTab === 'missions' ? 'active' : ''}`}
          onClick={() => setActiveTab('missions')}
        >
          Missions
        </button>
      </div>

      {/* Daily Challenge Banner */}
      <div className="daily-challenge-banner">
        <div className="banner-content">
          <div className="banner-icon">🎤</div>
          <div className="banner-text">
            <div className="banner-title">DAILY CHALLENGE:</div>
            <div className="banner-subtitle">Show Off Your Talent!</div>
          </div>
          <button className="banner-button">Start</button>
          <div className="banner-play">
            <div className="play-button-large">▶</div>
          </div>
        </div>
        <span className="new-badge">New!</span>
      </div>

      {/* Challenges Section */}
      <div className="challenges-section">
        <div className="section-header">
          <h2 className="section-title">Challenges</h2>
          <button className="see-all-button">See All →</button>
        </div>
        
        <div className="challenges-scroll">
          {challenges.map((challenge) => (
            <div key={challenge.id} className="challenge-card">
              <div className="challenge-thumbnail">
                <img src={challenge.thumbnail} alt={challenge.title} />
                <div className="challenge-overlay">
                  <div className="challenge-icon-small">{challenge.image}</div>
                </div>
              </div>
              <div className="challenge-title">{challenge.title}</div>
              <div className="challenge-stars">
                {'⭐'.repeat(challenge.stars)}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Trending Video */}
      <div className="trending-section">
        <div className="video-card">
          <div className="trending-badge">Trending</div>
          
          <div className="video-content">
            <div className="video-thumbnail">
              <img 
                src="https://picsum.photos/800/600?random=5" 
                alt="Skateboarding video"
                className="video-thumbnail-img"
              />
            </div>

            {/* Video Actions */}
            <div className="video-actions">
              <button className="action-button">
                <span className="action-icon">❤️</span>
                <span className="action-count">27.8K</span>
              </button>
              <button className="action-button">
                <span className="action-icon">💬</span>
                <span className="action-count">1,129</span>
              </button>
              <button className="action-button">
                <span className="action-icon">⭐</span>
                <span className="action-count">612</span>
              </button>
            </div>
          </div>

          {/* Video Info */}
          <div className="video-info">
            <div className="user-info">
              <div className="user-avatar">
                <img 
                  src="https://picsum.photos/100/100?random=6" 
                  alt="kickflip_kid"
                />
              </div>
              <span className="username">👤 kickflip_kid</span>
            </div>
            <div className="video-caption">
              Skaterlife! 😎🔥 #skateboard
            </div>
            <div className="video-music">
              ♪ Turn It Up - BeatMix
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Navigation */}
      <div className="bottom-navigation">
        <button className="nav-button active">
          <span className="nav-icon">🏠</span>
          <span className="nav-label">Home</span>
        </button>
        <button className="nav-button">
          <span className="nav-icon">🔍</span>
          <span className="nav-label">Explore</span>
        </button>
        <button className="nav-button center-button">
          <div className="center-play-button">▶</div>
        </button>
        <button className="nav-button">
          <span className="nav-icon">🔔</span>
          <span className="nav-label">Notifications</span>
          <span className="notification-badge">3</span>
        </button>
        <button className="nav-button">
          <span className="nav-icon">👤</span>
          <span className="nav-label">Profile</span>
        </button>
      </div>
    </div>
  );
}

export default HomeScreen;
