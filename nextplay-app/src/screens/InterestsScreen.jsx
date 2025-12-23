import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import CosmicBackground from '../components/CosmicBackground';
import CategoryCard from '../components/CategoryCard';
import PrimaryButton from '../components/PrimaryButton';

const InterestsScreen = ({ setInterests }) => {
  const navigate = useNavigate();
  const [selectedInterests, setSelectedInterests] = useState(['Sports']);

  const categories = [
    { id: 'sports', title: 'Sports', icon: '⚽' },
    { id: 'dance', title: 'Dance', icon: '💃' },
    { id: 'art', title: 'Art', icon: '🎨' },
    { id: 'stem', title: 'STEM', icon: '🧪' },
    { id: 'gaming', title: 'Gaming', icon: '🎮' },
    { id: 'music', title: 'Music', icon: '🎵' },
    { id: 'fitness', title: 'Fitness', icon: '🏋️' },
  ];

  const toggleInterest = (interestId) => {
    setSelectedInterests((prev) =>
      prev.includes(interestId)
        ? prev.filter((id) => id !== interestId)
        : [...prev, interestId]
    );
  };

  const handleContinue = () => {
    setInterests(selectedInterests);
    navigate('/signin');
  };

  return (
    <CosmicBackground>
      <div className="min-h-screen flex flex-col px-6 py-8">
        {/* Logo */}
        <div className="w-full flex justify-center mb-8">
          <img 
            src="/logo2-nextplay.jpg" 
            alt="NextPlay Logo" 
            className="w-40 h-auto object-contain"
          />
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col items-center max-w-2xl mx-auto w-full">
          <h1 className="text-4xl font-bold mb-3 text-amber-200 text-center">
            What are you into?
          </h1>
          
          <p className="text-amber-100/70 text-center mb-8">
            This helps build your feed. You can change this anytime.
          </p>

          {/* Category Grid */}
          <div className="grid grid-cols-3 gap-4 mb-8 w-full">
            {categories.map((category) => (
              <CategoryCard
                key={category.id}
                title={category.title}
                icon={category.icon}
                isSelected={selectedInterests.includes(category.id)}
                onClick={() => toggleInterest(category.id)}
              />
            ))}
          </div>

          {/* Continue Button */}
          <div className="w-full max-w-md mt-auto">
            <PrimaryButton onClick={handleContinue}>
              Continue
            </PrimaryButton>
          </div>

          {/* Footer */}
          <div className="mt-6 flex items-center justify-center space-x-2 text-amber-200/60 text-sm">
            <span className="text-amber-400">▲</span>
            <span>Player 1 Academy App</span>
          </div>
        </div>
      </div>
    </CosmicBackground>
  );
};

export default InterestsScreen;
