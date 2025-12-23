import React from 'react';

const CategoryCard = ({ title, icon, isSelected, onClick }) => {
  return (
    <button
      onClick={onClick}
      className={`
        relative p-6 rounded-2xl aspect-square flex flex-col items-center justify-center
        transition-all duration-300 transform hover:scale-105
        ${isSelected 
          ? 'bg-gradient-to-br from-amber-600/40 to-amber-800/40 border-2 border-amber-400 shadow-lg shadow-amber-600/50' 
          : 'bg-gradient-to-br from-amber-900/20 to-red-900/20 border-2 border-amber-700/50 hover:border-amber-600/70'
        }
      `}
    >
      {isSelected && (
        <div className="absolute top-3 right-3">
          <svg className="w-6 h-6 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
        </div>
      )}
      
      <div className="text-5xl mb-3">{icon}</div>
      <div className="text-amber-100 font-semibold text-center">{title}</div>
    </button>
  );
};

export default CategoryCard;
