# NextPlay App

**NextPlay** is a short-form video sharing app designed with teen safety and FTC compliance in mind. This app features a complete onboarding flow with age verification, interest selection, safety settings, and ad transparency.

## 🎨 Design Features

- **Cosmic Theme**: Luxurious gold/bronze color scheme with starfield background effects
- **Responsive UI**: Built with React and Tailwind CSS for a smooth, modern experience
- **Player 1 Academy Branding**: Official Player 1 Academy app integration

## 📱 App Flow

### Screen 0: Welcome
- **Title**: "Welcome to NextPlay"
- **Subtitle**: "Short videos. Real creativity."
- **Footer**: Age verification notice (FTC-compliant neutral language)
- **Action**: Continue button navigates to age verification

### Screen 1: Age Verification (Neutral)
- **FTC-Compliant Design**: Neutral age screening without coaching
- **Inputs**: Birth month and year dropdowns (all years available)
- **On-Device Calculation**: Age band calculated locally before account creation
- **Under-13 Path**: Hard stop with no account creation
- **13+ Path**: Proceeds to interests screen

### Screen 2A: Under-13 (Hard Stop)
- **Ineligible Message**: Clear explanation that NextPlay is 13+
- **Actions**:
  - Exit button (closes app)
  - Learn More link (opens FTC COPPA information)
- **Data Handling**: No account created, no server-side data stored

### Screen 2B: Eligible Path - Interests
- **Title**: "What are you into?"
- **Categories**: Sports, Dance, Art, STEM, Gaming, Music, Fitness
- **Multi-Select**: Users can select multiple interests
- **Purpose**: Helps build personalized feed
- **Footer**: "This helps build your feed. You can change this anytime."

### Screen 3: Create Account
- **Sign-in Options**:
  - Sign in with Apple (with "Hide My Email" encouraged)
  - Sign in with Google
  - Use email (optional)
- **Footer**: Terms and Privacy Policy agreement
- **Data Minimization**: Stores age band (13-15/16-17/18+) instead of full DOB

### Screen 4: Safety Settings (Age-Banded)
Defaults are automatically set based on age band:

**For 13-15 (Most Restrictive)**:
- Comments: People you follow
- Messages: No one
- Mentions/Tags: Off
- Account Visibility: Private

**For 16-17 (Moderate)**:
- Comments: People you follow
- Messages: People you follow
- Mentions/Tags: Off
- Account Visibility: Private

**For 18+ (Flexible)**:
- Comments: Everyone
- Messages: People you follow
- Mentions/Tags: On
- Account Visibility: Public

Users can adjust these settings, but safer defaults are pre-selected.

### Screen 5: Ad Transparency
- **Clear Messaging**: Explains ad model in teen-friendly language
- **Key Points**:
  - Ads shown to keep NextPlay free
  - Contextual ads based on video content (not sensitive personal info)
  - No selling of personal information
- **Action**: "Got it" button to proceed

### Screen 6: Home Feed
Full-featured home screen with:
- **Top Navigation**: Feed and Missions tabs
- **Daily Challenge Banner**: "Show Off Your Talent!" with start button
- **Challenges Section**: Grid of creative challenges (Funny Skit, Dance Party, Edit Like a Pro)
- **Trending Content**: Featured video with engagement metrics
- **Bottom Navigation**: Home, Explore, Create (center), Notifications (with badge), Profile

## 🔒 FTC Compliance Features

### Age Gate Requirements
✅ **Neutral Age Screening**: No pre-selected age or "I'm over 13" checkbox
✅ **On-Device Processing**: Age calculated locally before account creation
✅ **Hard Stop for Under-13**: No account creation, no data collection
✅ **Clear Messaging**: Transparent about why age information is collected

### Data Minimization
✅ **Age Bands**: Store 13-15/16-17/18+ instead of full date of birth
✅ **Purpose Limitation**: Age used only for eligibility and safety settings
✅ **Local Storage**: Under-13 interaction stored locally only (no server transmission)

### Safety Defaults
✅ **Age-Appropriate Settings**: Automatic restrictions for younger users
✅ **User Control**: Settings can be adjusted while maintaining safer defaults
✅ **Privacy First**: Private accounts by default for minors

### Transparency
✅ **Ad Disclosure**: Clear, teen-friendly explanation of ad model
✅ **Contextual Ads**: Based on video content, not sensitive user data
✅ **No Data Selling**: Explicit commitment not to sell personal information

## 🛠 Technical Stack

- **Framework**: React 18 with Vite
- **Routing**: React Router v6
- **Styling**: Tailwind CSS with custom cosmic theme
- **State Management**: React Hooks (useState)
- **Build Tool**: Vite for fast development and optimized builds

## 🚀 Getting Started

### Installation
```bash
cd nextplay-app
npm install
```

### Development
```bash
npm run dev
```

### Build for Production
```bash
npm run build
```

### Preview Production Build
```bash
npm run preview
```

## 📂 Project Structure

```
nextplay-app/
├── public/
│   ├── logo1-nextplay.jpg      # 3D logo variant
│   └── logo2-nextplay.jpg      # Standard logo
├── src/
│   ├── components/
│   │   ├── CosmicBackground.jsx    # Animated starfield background
│   │   ├── PrimaryButton.jsx       # Reusable button component
│   │   └── CategoryCard.jsx        # Interest selection card
│   ├── screens/
│   │   ├── WelcomeScreen.jsx
│   │   ├── AgeScreen.jsx
│   │   ├── UnderAgeScreen.jsx
│   │   ├── InterestsScreen.jsx
│   │   ├── SignInScreen.jsx
│   │   ├── SafetySettingsScreen.jsx
│   │   ├── AdTransparencyScreen.jsx
│   │   └── HomeScreen.jsx
│   ├── App.jsx                     # Main app with routing
│   ├── main.jsx                    # Entry point
│   └── index.css                   # Global styles with Tailwind
├── tailwind.config.js              # Tailwind configuration
├── postcss.config.js               # PostCSS configuration
└── package.json
```

## 🎨 Design System

### Colors
- **Gold**: `#ffd700` - Primary accent color
- **Bronze**: `#b87333` - Secondary accent
- **Amber Gradients**: Various shades for depth
- **Red Accents**: `#dc2626` - Call-to-action buttons
- **Cosmic Black**: `#000000` with radial gradients

### Typography
- **Headings**: Bold, gradient text effects
- **Body**: Clear, readable amber/white text
- **System Font**: Native system fonts for optimal performance

### Components
- **Buttons**: Gradient backgrounds with hover effects
- **Cards**: Glass-morphism with amber borders
- **Inputs**: Custom dropdowns with gold accents
- **Navigation**: Bottom nav bar with icon highlights

## 🔐 Privacy & Safety

### Data Stored
- Age band (not full DOB)
- Selected interests
- Safety preferences
- Account identifier (from OAuth provider)

### Data NOT Stored for Under-13
- No account creation
- No server-side data
- Local flag only (to prevent re-entry)

### User Rights
- Change interests anytime
- Adjust safety settings
- Delete account (future feature)
- Export data (future feature)

## 📋 Compliance Checklist

- [x] FTC-compliant neutral age gate
- [x] No account creation for under-13
- [x] Age-banded safety defaults
- [x] Transparent ad disclosure
- [x] Data minimization (age bands)
- [x] Privacy-first design
- [x] User control over settings
- [x] Clear terms and privacy policy links

## 🌟 Key Features

1. **Beautiful UI**: Cosmic theme with gold accents and smooth animations
2. **Safe by Default**: Age-appropriate restrictions automatically applied
3. **Transparent**: Clear communication about ads and data usage
4. **Compliant**: Follows FTC recommendations for teen apps
5. **Engaging**: Interactive challenges and trending content
6. **Accessible**: Intuitive navigation and clear messaging

## 📱 Responsive Design

The app is designed to work seamlessly across:
- Mobile devices (primary target)
- Tablets
- Desktop browsers

## 🔄 User Flow Summary

```
Welcome → Age Gate → [Under 13: Exit] or [13+: Interests] → Sign In → Safety Settings → Ad Transparency → Home Feed
```

## 🎯 Target Audience

- **Primary**: Ages 13-17 (with appropriate safeguards)
- **Secondary**: Ages 18+ (with more flexible settings)
- **Excluded**: Under 13 (per COPPA requirements)

## 📞 Support

For questions or concerns:
- Terms of Service: [Link to be added]
- Privacy Policy: [Link to be added]
- Support Email: [To be configured]

## 🏆 Credits

- **Design**: Based on attached mockups and FTC guidelines
- **Branding**: Player 1 Academy
- **Framework**: React + Vite + Tailwind CSS
- **Compliance**: FTC COPPA recommendations

---

**Note**: This is a demonstration app showcasing FTC-compliant onboarding flows for teen social media platforms. Production deployment would require additional features like backend integration, content moderation, and full legal review.
