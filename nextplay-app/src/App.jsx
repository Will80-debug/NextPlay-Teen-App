import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState } from 'react';
import WelcomeScreen from './screens/WelcomeScreen';
import AgeScreen from './screens/AgeScreen';
import UnderAgeScreen from './screens/UnderAgeScreen';
import InterestsScreen from './screens/InterestsScreen';
import SignInScreen from './screens/SignInScreen';
import SafetySettingsScreen from './screens/SafetySettingsScreen';
import AdTransparencyScreen from './screens/AdTransparencyScreen';
import HomeScreen from './screens/HomeScreen';

function App() {
  // Set to true for testing/demo purposes (bypass onboarding)
  const [userAge, setUserAge] = useState(16);
  const [ageVerified, setAgeVerified] = useState(true);
  const [accountCreated, setAccountCreated] = useState(true);
  const [interests, setInterests] = useState(['Sports', 'Music']);
  const [safetySettings, setSafetySettings] = useState({ dataCollection: true });

  return (
    <Router>
      <div className="min-h-screen bg-black">
        <Routes>
          <Route path="/" element={<Navigate to="/home" replace />} />
          <Route path="/welcome" element={<WelcomeScreen />} />
          <Route 
            path="/age" 
            element={
              <AgeScreen 
                setUserAge={setUserAge} 
                setAgeVerified={setAgeVerified} 
              />
            } 
          />
          <Route path="/underage" element={<UnderAgeScreen />} />
          <Route 
            path="/interests" 
            element={
              ageVerified && userAge >= 13 ? (
                <InterestsScreen setInterests={setInterests} />
              ) : (
                <Navigate to="/age" replace />
              )
            } 
          />
          <Route 
            path="/signin" 
            element={
              ageVerified && userAge >= 13 ? (
                <SignInScreen setAccountCreated={setAccountCreated} />
              ) : (
                <Navigate to="/age" replace />
              )
            } 
          />
          <Route 
            path="/safety" 
            element={
              accountCreated ? (
                <SafetySettingsScreen 
                  userAge={userAge} 
                  setSafetySettings={setSafetySettings} 
                />
              ) : (
                <Navigate to="/signin" replace />
              )
            } 
          />
          <Route 
            path="/ads" 
            element={
              safetySettings ? (
                <AdTransparencyScreen />
              ) : (
                <Navigate to="/safety" replace />
              )
            } 
          />
          <Route 
            path="/home" 
            element={
              accountCreated ? (
                <HomeScreen interests={interests} />
              ) : (
                <Navigate to="/" replace />
              )
            } 
          />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
