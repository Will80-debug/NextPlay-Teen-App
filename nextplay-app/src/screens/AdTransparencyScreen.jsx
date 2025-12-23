import { useNavigate } from 'react-router-dom';
import './AdTransparencyScreen.css';

function AdTransparencyScreen() {
  const navigate = useNavigate();

  const handleContinue = () => {
    // Mark onboarding as complete
    localStorage.setItem('onboardingComplete', 'true');
    navigate('/home');
  };

  return (
    <div className="screen-container ad-transparency-screen">
      <div className="logo-container small-logo">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" style={{ maxWidth: '250px' }} />
      </div>

      <div className="content-box">
        <div className="ad-icon">📢</div>
        
        <h1 className="title">About ads on NextPlay</h1>
        
        <p className="subtitle ad-description">
          We show ads to keep NextPlay free. We aim to show contextual ads based on the type of videos you're watching, not sensitive personal info.
        </p>

        <div className="info-box">
          <h3 className="info-title">What this means:</h3>
          <ul className="info-list">
            <li>✓ Ads are based on video content, not your personal data</li>
            <li>✓ We don't sell your information to advertisers</li>
            <li>✓ You control your privacy settings</li>
            <li>✓ Age-appropriate ads only</li>
          </ul>
        </div>

        <button className="primary-button" onClick={handleContinue}>
          Got it
        </button>

        <p className="footer-text">
          You can learn more about our ad practices in the <a href="#" className="link">Privacy Policy</a>.
        </p>
      </div>
    </div>
  );
}

export default AdTransparencyScreen;
