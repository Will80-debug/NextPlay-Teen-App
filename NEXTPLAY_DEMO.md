# NextPlay App - Complete Demo Guide

## 🌐 Live Demo

**Access the app here:** https://5175-i6trhlcizus3jz9fk99v3-cc2fbc16.sandbox.novita.ai

## 📱 Complete User Journey

### Screen Flow

1. **Welcome Screen** (`/`)
   - Brand introduction with "Short videos. Real creativity."
   - NextPlay 3D logo with floating animation
   - Continue button to proceed
   - Footer note about age verification

2. **Age Verification** (`/age`)
   - Neutral age gate (FTC compliant)
   - Month dropdown (January-December)
   - Year dropdown (all years, no bias)
   - Calculates age client-side
   - Routes based on age:
     - Under 13 → Not Eligible screen
     - 13+ → Account creation

3. **Not Eligible Screen** (`/not-eligible`) - *Under 13 only*
   - Hard stop for COPPA compliance
   - Warning icon with clear messaging
   - Exit button (no account creation)
   - "Learn more" link to FTC COPPA info
   - No server-side data stored

4. **Create Account** (`/create-account`) - *13+ only*
   - Sign in with Apple (with "Hide My Email" badge)
   - Sign in with Google
   - Use email (optional)
   - Player 1 Academy App badge
   - Terms and Privacy Policy agreement

5. **Safety Settings** (`/safety-settings`)
   - Age-appropriate defaults pre-selected
   - Settings:
     - Who can comment? (People you follow / No one / Everyone)
     - Who can message you? (No one / People you follow)
     - Allow mentions/tags? (Toggle on/off)
     - Account visibility (Private / Public)
   - Stricter defaults for 13-15 age band

6. **Content Preferences** (`/content-preferences`)
   - Interest selection grid:
     - Sports ⚽🏀
     - Dance 💃🕺
     - Art 🎨🖌️
     - STEM 🧪🔬
     - Gaming 🎮🕹️
     - Music 🎵🎧
     - Fitness 💪🏋️
   - Multi-select with checkmarks
   - Used for contextual feed building

7. **Ad Transparency** (`/ad-transparency`)
   - Clear explanation of advertising
   - Contextual ads (not tracking-based)
   - Privacy-friendly approach
   - Info box with key points:
     - Ads based on content, not personal data
     - No selling user information
     - User-controlled privacy
     - Age-appropriate ads only

8. **Home Screen** (`/home`)
   - Feed/Missions tabs
   - Daily Challenge banner with "Show Off Your Talent!"
   - Challenges carousel:
     - Create a Funny Skit! 🎭
     - Dance Party! 💃
     - Edit Like a Pro! 📹
     - STEM Experiment 🧪
   - Trending video section:
     - Video by @kickflip_kid
     - "Skaterlife! 😎🔥 #skateboard"
     - Music: "Turn It Up - BeatMix"
     - 27.8K likes, 1,129 comments, 612 stars
   - Bottom navigation:
     - Home 🏠
     - Explore 🔍
     - Create ▶ (center button)
     - Notifications 🔔 (3 badge)
     - Profile 👤

## 🎨 Design Elements

### Color Scheme
- Background: Dark radial gradient (black to dark brown)
- Primary: Gold (#d4a574, #ffd700)
- Secondary: Brown (#8b4513)
- Text: Light cream (#f4e4c1)

### Animations
- Starfield twinkling background
- Golden floating particles
- Logo floating effect
- Card hover lift effects
- Shimmer borders
- Pulse animations

### Components
- Glossy premium buttons with gradients
- Bordered cards with shadows
- Custom dropdowns with arrow icons
- Toggle switches
- Interactive challenge cards
- Video feed with actions overlay

## 🔐 Privacy & Compliance Features

### COPPA Compliance
- ✅ Neutral age screening (no coaching)
- ✅ Hard stop for under-13 users
- ✅ No account creation for ineligible users
- ✅ No server-side data for under-13
- ✅ Client-side age calculation only

### Privacy by Design
- ✅ Age band storage (not full DOB)
- ✅ Contextual advertising (not tracking)
- ✅ First-party interests only
- ✅ Age-appropriate defaults
- ✅ User-controlled settings
- ✅ Transparent data practices

### Age-Banded Settings

**13-15 Years (Stricter)**
- Account: Private by default
- Comments: People you follow only
- Messages: No one
- Mentions: Off by default

**16-17 Years (Moderate)**
- Account: Private by default
- Comments: People you follow only
- Messages: People you follow
- Mentions: Off by default

**18+ Years (Flexible)**
- All options available
- User can choose any setting

## 🚀 Technical Implementation

### Built With
- React 19 with hooks
- React Router 7 for navigation
- Custom CSS3 animations
- Vite for fast development
- Client-side state management (localStorage)

### Key Features
- Fully responsive design
- Smooth page transitions
- Interactive elements
- Form validation
- Age calculation
- Route protection
- Settings persistence

## 📊 Testing the Flow

### Test Case 1: Under 13 User
1. Enter birth year: 2012 or later
2. Click Continue
3. See "Not eligible yet" screen
4. No account creation possible
5. Can only exit or learn more

### Test Case 2: Teen User (13-15)
1. Enter birth year: 2009-2011
2. Click Continue
3. Create account
4. See stricter safety defaults
5. Complete onboarding
6. Access home screen

### Test Case 3: Teen User (16-17)
1. Enter birth year: 2007-2008
2. Click Continue
3. Create account
4. See moderate safety defaults
5. Complete onboarding
6. Access home screen

### Test Case 4: Adult User (18+)
1. Enter birth year: 2006 or earlier
2. Click Continue
3. Create account
4. See flexible settings
5. Complete onboarding
6. Access home screen

## 📱 Mobile Responsiveness

The app is fully responsive:
- Desktop: Full width with optimal spacing
- Tablet: Adjusted grid layouts
- Mobile: Single column, touch-friendly buttons
- All animations work smoothly

## 🎯 Key Achievements

✅ Exact design replication from screenshots
✅ All 8 screens implemented with full functionality
✅ FTC COPPA compliance throughout
✅ Premium dark theme with gold accents
✅ Smooth animations and transitions
✅ Responsive across all devices
✅ Age-appropriate privacy defaults
✅ Contextual advertising transparency
✅ Interactive home screen with full features
✅ Professional code structure and organization

## 🔗 Navigation Routes

- `/` - Welcome
- `/age` - Age verification
- `/not-eligible` - Under 13 rejection
- `/create-account` - Sign up/sign in
- `/safety-settings` - Privacy configuration
- `/content-preferences` - Interest selection
- `/ad-transparency` - Advertising info
- `/home` - Main app interface

## 💡 Usage Tips

1. **Start at the root** (`/`) to see the full onboarding flow
2. **Try different ages** to see different experiences
3. **Interact with elements** - all buttons and cards are functional
4. **Check responsiveness** - resize browser to see mobile layout
5. **Navigate freely** - use browser back/forward or direct URL access

---

**Built with ❤️ following best practices for youth safety and privacy**
