import { useNavigate } from 'react-router-dom';
import CosmicBackground from '../components/CosmicBackground';
import PrimaryButton from '../components/PrimaryButton';

const WelcomeScreen = () => {
  const navigate = useNavigate();

  return (
    <CosmicBackground>
      <div className="min-h-screen flex flex-col items-center justify-between px-6 py-12">
        {/* Logo at top */}
        <div className="w-full flex justify-center pt-8">
          <img 
            src="/logo2-nextplay.jpg" 
            alt="NextPlay Logo" 
            className="w-64 h-auto object-contain"
          />
        </div>

        {/* Center content */}
        <div className="flex-1 flex flex-col items-center justify-center text-center max-w-md">
          <h1 className="text-5xl font-bold mb-4 text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600">
            Welcome to NextPlay
          </h1>
          <p className="text-xl text-amber-100/80 mb-12">
            Short videos. Real creativity.
          </p>

          <div className="w-full max-w-sm">
            <PrimaryButton onClick={() => navigate('/age')}>
              Continue
            </PrimaryButton>
          </div>
        </div>

        {/* Footer */}
        <div className="max-w-md text-center">
          <p className="text-sm text-amber-200/60 leading-relaxed">
            We'll ask for your birth month and year to confirm you meet the minimum age to use NextPlay.
          </p>
        </div>
      </div>
    </CosmicBackground>
  );
};

export default WelcomeScreen;
