import React from 'react';

const CosmicBackground = ({ children }) => {
  return (
    <div className="min-h-screen w-full relative overflow-hidden bg-black">
      {/* Base gradient background */}
      <div className="absolute inset-0 bg-gradient-radial from-gray-900 via-black to-black"></div>
      
      {/* Animated stars/particles */}
      <div className="absolute inset-0">
        {[...Array(50)].map((_, i) => (
          <div
            key={i}
            className="absolute rounded-full animate-pulse"
            style={{
              width: Math.random() * 3 + 1 + 'px',
              height: Math.random() * 3 + 1 + 'px',
              top: Math.random() * 100 + '%',
              left: Math.random() * 100 + '%',
              background: Math.random() > 0.5 ? 'rgba(255, 215, 0, 0.4)' : 'rgba(255, 255, 255, 0.3)',
              animationDelay: Math.random() * 3 + 's',
              animationDuration: (Math.random() * 3 + 2) + 's',
            }}
          />
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10">
        {children}
      </div>
    </div>
  );
};

export default CosmicBackground;
