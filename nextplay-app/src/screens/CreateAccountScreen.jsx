import { useNavigate } from 'react-router-dom';
import './CreateAccountScreen.css';

function CreateAccountScreen() {
  const navigate = useNavigate();

  const handleSignInWithApple = () => {
    // In a real app, this would initiate Apple Sign-In with "Hide My Email"
    alert('Sign in with Apple - would prompt for authentication');
    navigate('/safety-settings');
  };

  const handleSignInWithGoogle = () => {
    // In a real app, this would initiate Google Sign-In
    alert('Sign in with Google - would prompt for authentication');
    navigate('/safety-settings');
  };

  const handleUseEmail = () => {
    // In a real app, this would show an email input form
    alert('Email sign-up - would show email form');
    navigate('/safety-settings');
  };

  return (
    <div className="screen-container create-account-screen">
      <div className="logo-container">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" />
      </div>

      <div className="content-box">
        <h1 className="title">Create your account</h1>

        <div className="auth-buttons">
          <button className="auth-button apple-button" onClick={handleSignInWithApple}>
            <span className="auth-icon apple-icon">🍎</span>
            <span className="auth-text">Sign in with Apple</span>
            <span className="hide-email-badge">Hide My Email 🔒</span>
          </button>

          <button className="auth-button google-button" onClick={handleSignInWithGoogle}>
            <span className="auth-icon google-icon">G</span>
            <span className="auth-text">Sign in with Google</span>
          </button>

          <button className="auth-button email-button" onClick={handleUseEmail}>
            <span className="auth-icon email-icon">✉️</span>
            <span className="auth-text">Use email <span className="optional-text">(optional)</span></span>
          </button>
        </div>

        <p className="footer-text academy-footer">
          <span className="academy-icon">⚠️</span> This is a Player 1 Academy App <span className="info-icon">ⓘ</span>
        </p>

        <p className="footer-text terms-footer">
          By continuing, you agree to our <a href="#" className="link">Terms</a> and <a href="#" className="link">Privacy Policy</a>.
        </p>
      </div>
    </div>
  );
}

export default CreateAccountScreen;
