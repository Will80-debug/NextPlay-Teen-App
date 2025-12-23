import CosmicBackground from '../components/CosmicBackground';
import PrimaryButton from '../components/PrimaryButton';

const UnderAgeScreen = () => {
  const handleExit = () => {
    // In a real app, this would close the app or redirect to a safe page
    window.location.href = 'about:blank';
  };

  const handleLearnMore = () => {
    // Opens info page about age requirements
    window.open('https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa', '_blank');
  };

  return (
    <CosmicBackground>
      <div className="min-h-screen flex flex-col items-center justify-center px-6 py-12">
        {/* Logo */}
        <div className="w-full flex justify-center mb-12">
          <img 
            src="/logo2-nextplay.jpg" 
            alt="NextPlay Logo" 
            className="w-48 h-auto object-contain"
          />
        </div>

        {/* Content */}
        <div className="max-w-md text-center">
          <div className="mb-8">
            <div className="w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-red-600/30 to-red-900/30 border-2 border-red-500/50 flex items-center justify-center">
              <svg className="w-12 h-12 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          </div>

          <h1 className="text-4xl font-bold mb-4 text-amber-200">
            Not eligible yet
          </h1>
          
          <p className="text-xl text-amber-100/80 mb-8 leading-relaxed">
            NextPlay is only available for people 13 and older. We can't create an account right now.
          </p>

          <div className="space-y-4">
            <PrimaryButton onClick={handleExit}>
              Exit
            </PrimaryButton>

            <button
              onClick={handleLearnMore}
              className="w-full py-3 text-amber-300 hover:text-amber-200 transition-colors underline"
            >
              Learn more
            </button>
          </div>
        </div>
      </div>
    </CosmicBackground>
  );
};

export default UnderAgeScreen;
