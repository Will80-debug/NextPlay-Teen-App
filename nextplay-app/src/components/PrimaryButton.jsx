import React from 'react';

const PrimaryButton = ({ children, onClick, className = '', variant = 'primary', disabled = false }) => {
  const baseStyles = "w-full py-4 px-8 rounded-full font-semibold text-lg transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100";
  
  const variants = {
    primary: "bg-gradient-to-r from-red-600 via-red-700 to-red-800 text-white shadow-lg shadow-red-900/50 hover:shadow-xl hover:shadow-red-900/70 border-2 border-red-500",
    secondary: "bg-transparent text-amber-200 border-2 border-amber-500 hover:bg-amber-500/10 shadow-lg shadow-amber-900/30",
  };

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`${baseStyles} ${variants[variant]} ${className}`}
    >
      {children}
    </button>
  );
};

export default PrimaryButton;
