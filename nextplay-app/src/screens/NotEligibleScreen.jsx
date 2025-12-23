import { useNavigate } from 'react-router-dom';
import './NotEligibleScreen.css';

function NotEligibleScreen() {
  const navigate = useNavigate();

  const handleExit = () => {
    // Clear any stored data
    localStorage.clear();
    // In a real app, this would close the app or redirect to an exit page
    navigate('/');
  };

  const handleLearnMore = () => {
    // Open a simple page explaining the 13+ rule
    window.open('https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa', '_blank');
  };

  return (
    <div className="screen-container not-eligible-screen">
      <div className="logo-container">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" />
      </div>

      <div className="content-box not-eligible-box">
        <div className="warning-icon">⚠️</div>
        
        <h1 className="title">Not eligible yet</h1>
        
        <p className="subtitle">
          NextPlay is only available for people 13 and older. We can't create an account right now.
        </p>

        <button className="primary-button" onClick={handleExit}>
          Exit
        </button>

        <button className="secondary-button learn-more" onClick={handleLearnMore}>
          Learn more
        </button>
      </div>
    </div>
  );
}

export default NotEligibleScreen;
