# NextPlay App - Screen Flow Guide

## 📱 Complete Navigation Flow

This document provides a visual guide to navigating through all screens of the NextPlay app.

---

## 🚀 Screen 0: Welcome

**Path**: `/`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│                             │
│   "Welcome to NextPlay"     │
│   Short videos.             │
│   Real creativity.          │
│                             │
│   [Continue Button]         │
│                             │
│  We'll ask for your birth   │
│  month and year...          │
└─────────────────────────────┘
```

### Navigation
- **Action**: Click "Continue"
- **Next**: Age Screen (`/age`)

---

## 🎂 Screen 1: Age Gate

**Path**: `/age`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│  What's your birth          │
│  month and year?            │
│                             │
│  ┌─────────┬─────────┐      │
│  │ January │  2011   │      │
│  └─────────┴─────────┘      │
│                             │
│  [Continue Button]          │
│                             │
│  [?]                        │
└─────────────────────────────┘
```

### Logic
```javascript
// Age calculation happens on-device
const age = currentYear - birthYear;

if (age < 13) {
  navigate('/underage');
} else {
  navigate('/interests');
}
```

### Navigation
- **Age < 13**: Under Age Screen (`/underage`)
- **Age ≥ 13**: Interests Screen (`/interests`)

---

## 🚫 Screen 2A: Under Age (Hard Stop)

**Path**: `/underage`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│        [X Icon]             │
│                             │
│    Not eligible yet         │
│                             │
│  NextPlay is only available │
│  for people 13 and older.   │
│                             │
│     [Exit Button]           │
│                             │
│      Learn more             │
└─────────────────────────────┘
```

### Navigation
- **Exit**: Closes app or navigates to safe page
- **Learn More**: Opens FTC COPPA info (external link)
- **No account created**
- **No data stored server-side**

---

## 🎯 Screen 3: Interests

**Path**: `/interests`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│   What are you into?        │
│  This helps build your feed │
│                             │
│  ┌───────┬───────┬───────┐  │
│  │ ⚽    │ 💃    │ 🎨    │  │
│  │Sports│ Dance │  Art  │  │
│  │  ✓   │       │       │  │
│  └───────┴───────┴───────┘  │
│  ┌───────┬───────┬───────┐  │
│  │ 🧪    │ 🎮    │ 🎵    │  │
│  │ STEM │Gaming │ Music │  │
│  └───────┴───────┴───────┘  │
│  ┌───────┐                  │
│  │ 🏋️    │                  │
│  │Fitness│                  │
│  └───────┘                  │
│                             │
│    [Continue Button]        │
│                             │
│  ▲ Player 1 Academy App     │
└─────────────────────────────┘
```

### Navigation
- **Action**: Select interests (multi-select), click "Continue"
- **Next**: Sign In Screen (`/signin`)

---

## 🔐 Screen 4: Sign In

**Path**: `/signin`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│   Create your account       │
│                             │
│  ┌─────────────────────┐    │
│  │  Sign in with Apple │    │
│  │   Hide My Email  ℹ️  │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Sign in with Google │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Use email (optional)│    │
│  └─────────────────────┘    │
│                             │
│  This is a Player 1         │
│  Academy app ⓘ              │
│                             │
│  By continuing, you agree   │
│  to our Terms and Privacy   │
└─────────────────────────────┘
```

### Navigation
- **Action**: Select sign-in method
- **Next**: Safety Settings Screen (`/safety`)
- **Data Stored**: Age band (13-15/16-17/18+), OAuth identifier

---

## 🛡️ Screen 5: Safety Settings

**Path**: `/safety`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│  Choose your safety         │
│  settings                   │
│  Age band: 13-15            │
│                             │
│  ┌─────────────────────┐    │
│  │ Who can comment?    │    │
│  │ People you follow ▼ │    │
│  ├─────────────────────┤    │
│  │ Who can message?    │    │
│  │ No one           ▼  │    │
│  ├─────────────────────┤    │
│  │ Allow mentions?     │    │
│  │                  ○  │    │
│  ├─────────────────────┤    │
│  │ Account visibility  │    │
│  │ Private          ▼  │    │
│  └─────────────────────┘    │
│                             │
│  ℹ️  These settings help    │
│  protect your privacy...    │
│                             │
│    [Continue Button]        │
└─────────────────────────────┘
```

### Age-Banded Defaults

**13-15 (Most Restrictive)**
- Comments: People you follow
- Messages: No one
- Mentions: Off
- Visibility: Private

**16-17 (Moderate)**
- Comments: People you follow
- Messages: People you follow
- Mentions: Off
- Visibility: Private

**18+ (Flexible)**
- Comments: Everyone
- Messages: People you follow
- Mentions: On
- Visibility: Public

### Navigation
- **Action**: Review/adjust settings, click "Continue"
- **Next**: Ad Transparency Screen (`/ads`)

---

## 📢 Screen 6: Ad Transparency

**Path**: `/ads`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│        [ℹ️ Icon]            │
│                             │
│   About ads on NextPlay     │
│                             │
│  ┌─────────────────────┐    │
│  │ We show ads to keep │    │
│  │ NextPlay free. We   │    │
│  │ aim to show         │    │
│  │ contextual ads...   │    │
│  └─────────────────────┘    │
│                             │
│  ✓ Ads based on video       │
│    content, not personal    │
│    data                     │
│                             │
│  ✓ We don't sell your       │
│    personal information     │
│                             │
│  ✓ Manage ad preferences    │
│    in Settings              │
│                             │
│      [Got it Button]        │
│                             │
│  Learn more about our       │
│  ad practices               │
└─────────────────────────────┘
```

### Navigation
- **Action**: Click "Got it"
- **Next**: Home Feed Screen (`/home`)

---

## 🏠 Screen 7: Home Feed

**Path**: `/home`

### Layout
```
┌─────────────────────────────┐
│     [NextPlay Logo]         │
│                             │
│     Feed  |  Missions       │
│     ‾‾‾‾                    │
│  ┌─────────────────────┐    │
│  │ DAILY CHALLENGE:    │NEW!│
│  │ Show Off Your       │    │
│  │ Talent!             │    │
│  │ [Start] 🎤       [▶️] │   │
│  └─────────────────────┘    │
│                             │
│  Challenges         See All │
│  ┌─────┬─────┬─────┐        │
│  │ 😂  │ 💃  │ 🎬  │        │
│  │Funny│Dance│Edit │        │
│  │ ⭐⭐⭐│ ⭐⭐⭐│ ⭐⭐⭐│        │
│  └─────┴─────┴─────┘        │
│                             │
│  ┌─────────────────────┐    │
│  │    [Trending]       │    │
│  │                     │    │
│  │   🛹 Skater Video   │    │
│  │                     │    │
│  │ kickflip_kid        │    │
│  │ Skaterlife! 😎🔥    │    │
│  │ #skateboard         │    │
│  │ 🎵 Turn It Up       │❤️  │
│  │                     │27.8K│
│  │                     │💬  │
│  │                     │1.1K│
│  │                     │⭐  │
│  │                     │612 │
│  └─────────────────────┘    │
│                             │
├─────────────────────────────┤
│  🏠   🔍   ➕   🔔³  👤    │
│ Home Explore  Notif Profile│
└─────────────────────────────┘
```

### Bottom Navigation
- **🏠 Home**: Current screen
- **🔍 Explore**: Browse content
- **➕ Create**: Upload new video (center, elevated)
- **🔔 Notifications**: View notifications (with badge count)
- **👤 Profile**: User profile

### Navigation
- **Complete**: User can now use the app
- **Navigation**: All bottom nav items lead to respective sections

---

## 🔄 Complete Flow Diagram

```
                    START
                      │
                      ▼
            ┌─────────────────┐
            │  0. Welcome     │
            │  "Continue"     │
            └─────────────────┘
                      │
                      ▼
            ┌─────────────────┐
            │  1. Age Gate    │
            │  Enter DOB      │
            └─────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
    ┌──────────┐          ┌──────────┐
    │ Under 13 │          │  13+     │
    │ (EXIT)   │          │ Continue │
    └──────────┘          └──────────┘
                                  │
                                  ▼
                          ┌──────────┐
                          │ 3. Inter-│
                          │   ests   │
                          └──────────┘
                                  │
                                  ▼
                          ┌──────────┐
                          │ 4. Sign  │
                          │   In     │
                          └──────────┘
                                  │
                                  ▼
                          ┌──────────┐
                          │ 5. Safety│
                          │ Settings │
                          └──────────┘
                                  │
                                  ▼
                          ┌──────────┐
                          │ 6. Ad    │
                          │Transprncy│
                          └──────────┘
                                  │
                                  ▼
                          ┌──────────┐
                          │ 7. Home  │
                          │  Feed    │
                          └──────────┘
                                  │
                              APP READY
```

---

## 🎯 Protected Routes

The app uses route protection to ensure users can't skip steps:

```javascript
// Age verification required
/interests → Requires: ageVerified && userAge >= 13
/signin    → Requires: ageVerified && userAge >= 13

// Account required
/safety    → Requires: accountCreated
/ads       → Requires: safetySettings
/home      → Requires: accountCreated
```

If a user tries to navigate directly to a protected route, they'll be redirected back to the appropriate starting point.

---

## 🔐 Data Collection Points

### Screen 1 (Age Gate)
- **Collected**: Birth month and year
- **Processed**: Age calculation (on-device)
- **Stored**: Age band only (13-15, 16-17, 18+)

### Screen 3 (Interests)
- **Collected**: Selected interest categories
- **Purpose**: Feed personalization
- **Privacy**: First-party only (not shared with advertisers)

### Screen 4 (Sign In)
- **Collected**: OAuth identifier from provider
- **Email**: Optional (can use "Hide My Email")
- **Storage**: Minimal identifier only

### Screen 5 (Safety Settings)
- **Collected**: User preferences
- **Defaults**: Age-appropriate pre-selections
- **Control**: User can modify anytime

---

## 🎨 Design Consistency

All screens follow the same design language:

✅ Cosmic black background with stars
✅ Gold/bronze/amber color palette
✅ Rounded cards with glowing borders
✅ Gradient buttons with hover effects
✅ NextPlay logo in header
✅ Clear typography hierarchy
✅ Smooth transitions between screens

---

## 📱 Mobile-First Design

Every screen is optimized for mobile:
- Touch-friendly button sizes
- Scrollable content
- Bottom navigation (thumb-friendly)
- Clear visual hierarchy
- Readable text sizes

---

## ✨ Animations & Effects

- **Background**: Animated starfield
- **Buttons**: Hover scale effects
- **Cards**: Glow on selection
- **Transitions**: Smooth page changes
- **Loading**: Graceful state handling

---

## 🎉 End Result

After completing all screens, users arrive at a fully-functional home feed with:
- Personalized content based on interests
- Daily challenges to engage
- Trending videos to watch
- Full navigation capabilities
- Age-appropriate safety settings
- Transparent ad experience

**The NextPlay experience is ready! 🚀**
