import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './AgeScreen.css';

function AgeScreen() {
  const navigate = useNavigate();
  const [month, setMonth] = useState('January');
  const [year, setYear] = useState('2011');

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 100 }, (_, i) => currentYear - i);

  const calculateAge = () => {
    const birthYear = parseInt(year);
    const birthMonth = months.indexOf(month);
    const today = new Date();
    const age = today.getFullYear() - birthYear;
    const monthDiff = today.getMonth() - birthMonth;
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < 1)) {
      return age - 1;
    }
    return age;
  };

  const handleContinue = () => {
    const age = calculateAge();
    
    if (age < 13) {
      navigate('/not-eligible');
    } else {
      // Store age band for later use
      let ageBand;
      if (age >= 13 && age <= 15) {
        ageBand = '13-15';
      } else if (age >= 16 && age <= 17) {
        ageBand = '16-17';
      } else {
        ageBand = '18+';
      }
      
      // Store in localStorage (client-side only)
      localStorage.setItem('ageBand', ageBand);
      localStorage.setItem('birthYear', year);
      
      navigate('/create-account');
    }
  };

  return (
    <div className="screen-container age-screen">
      <div className="logo-container">
        <img src="/nextplay-logo-3d.png" alt="NextPlay" className="logo-3d" />
      </div>

      <div className="content-box">
        <h1 className="title">What's your birth month and year?</h1>
        
        <div className="age-inputs">
          <div className="input-group">
            <select 
              className="custom-select"
              value={month}
              onChange={(e) => setMonth(e.target.value)}
            >
              {months.map((m) => (
                <option key={m} value={m}>{m}</option>
              ))}
            </select>
          </div>

          <div className="input-group">
            <select 
              className="custom-select"
              value={year}
              onChange={(e) => setYear(e.target.value)}
            >
              {years.map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>
        </div>

        <button className="primary-button" onClick={handleContinue}>
          Continue
        </button>

        <p className="footer-text">
          We use this to confirm eligibility and apply age-appropriate safety settings.
        </p>

        <div className="help-icon">?</div>
      </div>
    </div>
  );
}

export default AgeScreen;
