# NextPlay - Short Videos. Real Creativity.

A youth-focused social video platform with comprehensive age-appropriate safety features and onboarding flow.

## 🎯 Features

### Onboarding Flow (Age-Gate Compliance)
- **Screen 0 - Welcome**: Neutral introduction without age coaching
- **Screen 1 - Age Verification**: Non-biased age screening with month/year dropdowns
- **Screen 2A - Under 13 Hard Stop**: FTC-compliant rejection with no account creation
- **Screen 2B - Create Account**: OAuth options (Apple, Google) and optional email
- **Screen 3 - Safety Settings**: Age-banded default privacy settings
  - 13-15: Strict defaults (private account, limited interactions)
  - 16-17: Moderate defaults (follower-only interactions)
- **Screen 4 - Content Preferences**: Interest selection for feed personalization
- **Screen 5 - Ad Transparency**: Clear explanation of contextual advertising
- **Home Screen**: Full featured social video feed with challenges and trending content

### Privacy & Safety
- ✅ Age-band storage (13-15, 16-17, 18+) instead of full DOB
- ✅ Client-side age calculation
- ✅ No server-side data collection for under-13 users
- ✅ Age-appropriate default privacy settings
- ✅ Contextual advertising (content-based, not user-tracking)
- ✅ First-party interest preferences only

## 🎨 Design

The app features a premium dark theme with gold accents inspired by the provided designs:
- Starfield animated background
- Golden particle effects
- 3D NextPlay logo with floating animation
- Premium glossy buttons with shadows and gradients
- Responsive design for mobile and desktop

## 🚀 Tech Stack

- **React 19** - Modern React with hooks
- **React Router 7** - Client-side routing
- **Vite** - Fast build tool and dev server
- **CSS3** - Custom animations and responsive design

## 📦 Installation

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🔧 Development

The project is structured as follows:

```
nextplay-app/
├── public/
│   ├── nextplay-logo-3d.png      # 3D logo for headers
│   └── nextplay-logo-round.png   # Round logo for avatars
├── src/
│   ├── screens/
│   │   ├── WelcomeScreen.jsx
│   │   ├── AgeScreen.jsx
│   │   ├── NotEligibleScreen.jsx
│   │   ├── CreateAccountScreen.jsx
│   │   ├── SafetySettingsScreen.jsx
│   │   ├── ContentPreferencesScreen.jsx
│   │   ├── AdTransparencyScreen.jsx
│   │   └── HomeScreen.jsx
│   ├── App.jsx
│   ├── App.css
│   └── main.jsx
└── package.json
```

## 🎮 User Flow

1. **Welcome** → User sees brand introduction
2. **Age Gate** → User enters birth month/year
3. **Age Check**:
   - Under 13: Redirect to "Not Eligible" screen (hard stop)
   - 13+: Continue to account creation
4. **Account Creation** → OAuth sign-in options
5. **Safety Settings** → Age-appropriate defaults pre-selected
6. **Content Preferences** → Interest selection for feed
7. **Ad Transparency** → Education about advertising practices
8. **Home Screen** → Access to full app features

## 🔐 Privacy Compliance

This app follows FTC guidelines for youth-focused platforms:

- **COPPA Compliance**: Hard stop for users under 13
- **Neutral Age Screening**: No coaching or default ages
- **Data Minimization**: Only birth year stored (if needed)
- **Age-Banded Defaults**: Stricter privacy for younger users
- **Transparent Advertising**: Clear explanation of ad practices
- **No Tracking**: Contextual ads instead of behavioral targeting

## 📱 Screens Preview

### Onboarding Screens
- Welcome with brand messaging
- Age verification with neutral language
- Under-13 rejection screen
- Account creation with OAuth
- Safety settings with age-appropriate defaults
- Content preferences selection
- Ad transparency disclosure

### Home Screen
- Feed/Missions tabs
- Daily challenges banner
- Challenge cards carousel
- Trending video feed
- Interactive video actions
- Bottom navigation bar

## 🌟 Key Design Elements

- **Color Scheme**: Dark brown/black backgrounds with gold (#d4a574, #ffd700) accents
- **Typography**: Clean sans-serif with golden text shadows
- **Animations**: Floating, pulsing, shimmer effects
- **Components**: Premium glossy cards with borders and shadows
- **Icons**: Emoji-based for universal understanding

## 📄 License

This is a demo application created for educational purposes.

## 🤝 Credits

- Design inspired by TikTok-style social video platforms
- Compliance guidelines from FTC COPPA regulations
- Built with modern React and Vite
