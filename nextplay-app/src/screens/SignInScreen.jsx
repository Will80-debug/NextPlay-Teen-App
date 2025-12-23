import { useNavigate } from 'react-router-dom';
import CosmicBackground from '../components/CosmicBackground';
import PrimaryButton from '../components/PrimaryButton';

const SignInScreen = ({ setAccountCreated }) => {
  const navigate = useNavigate();

  const handleSignIn = (method) => {
    // Simulate account creation
    setAccountCreated(true);
    navigate('/safety');
  };

  return (
    <CosmicBackground>
      <div className="min-h-screen flex flex-col items-center justify-between px-6 py-12">
        {/* Logo */}
        <div className="w-full flex justify-center pt-8">
          <img 
            src="/logo2-nextplay.jpg" 
            alt="NextPlay Logo" 
            className="w-48 h-auto object-contain"
          />
        </div>

        {/* Center content */}
        <div className="flex-1 flex flex-col items-center justify-center w-full max-w-md">
          <h1 className="text-4xl font-bold mb-12 text-amber-200 text-center">
            Create your account
          </h1>

          <div className="w-full space-y-4">
            {/* Sign in with Apple */}
            <button
              onClick={() => handleSignIn('apple')}
              className="w-full bg-white text-black py-4 px-6 rounded-full font-semibold text-lg flex items-center justify-center space-x-3 transition-all duration-300 transform hover:scale-105 shadow-lg"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
              </svg>
              <span>Sign in with Apple</span>
            </button>

            {/* Hide My Email hint */}
            <div className="flex items-center justify-center space-x-2 text-amber-300 text-sm">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>Hide My Email</span>
            </div>

            {/* Sign in with Google */}
            <button
              onClick={() => handleSignIn('google')}
              className="w-full bg-gradient-to-br from-gray-800 to-gray-900 text-white py-4 px-6 rounded-full font-semibold text-lg flex items-center justify-center space-x-3 border-2 border-amber-700/50 transition-all duration-300 transform hover:scale-105 shadow-lg"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              <span>Sign in with Google</span>
            </button>

            {/* Email option */}
            <button
              onClick={() => handleSignIn('email')}
              className="w-full bg-transparent text-amber-200 py-4 px-6 rounded-full font-semibold text-lg flex items-center justify-center space-x-3 border-2 border-amber-700/50 transition-all duration-300 transform hover:scale-105 hover:bg-amber-900/20"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span>Use email <span className="text-amber-400/70">(optional)</span></span>
            </button>
          </div>

          {/* Info badge */}
          <div className="mt-8 flex items-center space-x-2 text-amber-200/70 text-sm">
            <span>This is a Player 1 Academy app</span>
            <button className="w-5 h-5 rounded-full border border-amber-400/50 flex items-center justify-center text-amber-400 text-xs">
              i
            </button>
          </div>
        </div>

        {/* Footer */}
        <div className="max-w-md text-center">
          <p className="text-sm text-amber-200/60">
            By continuing, you agree to our{' '}
            <a href="#" className="text-amber-300 underline">Terms</a>
            {' '}and{' '}
            <a href="#" className="text-amber-300 underline">Privacy Policy</a>.
          </p>
        </div>
      </div>
    </CosmicBackground>
  );
};

export default SignInScreen;
