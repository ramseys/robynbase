# RobynBase iOS App Proposal

**Date:** November 16, 2025
**Author:** Development Team
**Status:** Draft Proposal

---

## Executive Summary

This proposal outlines a strategy for creating an iOS app for RobynBase using **Hotwire Native**, the mobile framework developed and used by 37signals for Basecamp and HEY. This approach enables:

- **Maximum code reuse** from our existing Rails web application (~80-90% code sharing)
- **Shared codebase** that will support both iOS and Android
- **Small team efficiency** by leveraging existing web development skills
- **Native performance** for high-value features while maintaining web flexibility
- **Future-proof architecture** aligned with modern Rails best practices

---

## Table of Contents

1. [Background: The 37signals Approach](#background-the-37signals-approach)
2. [Why Hotwire Native for RobynBase](#why-hotwire-native-for-robynbase)
3. [Technical Architecture](#technical-architecture)
4. [Code Sharing Strategy](#code-sharing-strategy)
5. [Implementation Roadmap](#implementation-roadmap)
6. [Android Path](#android-path)
7. [Benefits & Trade-offs](#benefits--trade-offs)
8. [Resource Requirements](#resource-requirements)
9. [Alternatives Considered](#alternatives-considered)
10. [Recommendation](#recommendation)

---

## Background: The 37signals Approach

### What is Hotwire Native?

Hotwire Native (launched in 2024) is 37signals' framework for building native iOS and Android apps that leverage existing Hotwire (Turbo + Stimulus) web applications. It represents the evolution of their "Turbo Native" approach used in Basecamp and HEY.

### Core Philosophy: "Hybrid Sweet Spot"

37signals uses what they call the **"Hybrid Sweet Spot"** approach:

- **Web content** for most screens (using your existing Rails views)
- **Native navigation** for app-like feel (iOS/Android navigation patterns)
- **Selective native implementation** for high-value features (gestures, animations, offline access)

### Real-World Success

- **Basecamp** - Full-featured project management app on iOS and Android
- **HEY** - Email client with complex interactions
- **HEY Calendar** - Native-heavy app that still uses Turbo for many screens
- All built by small teams sharing code across platforms

### Key Quote from DHH (2024)

> "Native mobile apps are optional for B2B startups in 2024... PWAs have gotten so good that you can ship a fantastic mobile experience without writing a line of Swift or Kotlin."

However, for apps like RobynBase where a native app provides real value (offline access, notifications, better media integration), Hotwire Native offers the **best of both worlds**.

---

## Why Hotwire Native for RobynBase

### Perfect Fit with Current Stack

RobynBase already uses the **exact technologies** that Hotwire Native is designed for:

| Technology | Current Web | Hotwire Native |
|------------|-------------|----------------|
| Framework | Rails 7.2 | ✅ Perfect match |
| Frontend | Turbo Rails 2.0 | ✅ Core dependency |
| JavaScript | Stimulus.js | ✅ Works out of box |
| Styling | Bootstrap 5 | ✅ Fully supported |
| Architecture | Server-rendered HTML | ✅ Designed for this |

**This means we're not fighting our current architecture—we're extending it.**

### Code Sharing Maximized

With Hotwire Native, we can reuse:

- **100% of Rails backend code** (models, controllers, business logic)
- **80-90% of frontend code** (views, Stimulus controllers, CSS)
- **All existing features** (search, infinite scroll, maps, media embeds)
- **Authentication and authorization** (CanCanCan policies)

### Single Team, Multiple Platforms

- Same developers can work on web, iOS, and Android
- No need to hire separate mobile developers (initially)
- Shared bug fixes and features across all platforms
- Consistent user experience across web and mobile

### Enables Android Future

Hotwire Native has **parallel frameworks** for iOS and Android:

- `hotwire-native-ios` (Swift)
- `hotwire-native-android` (Kotlin)
- Nearly identical APIs and patterns
- Code sharing between iOS and Android apps (~70-80%)

---

## Technical Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Rails Backend (Shared)                   │
│  Models | Controllers | Views | Stimulus | API Endpoints    │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
       ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
       │   Web   │      │   iOS   │      │ Android │
       │ Browser │      │  Native │      │ Native  │
       └─────────┘      └─────────┘      └─────────┘
                             │                 │
                        ┌────▼─────────────────▼────┐
                        │  Hotwire Native (Shared)  │
                        │  Turbo | Strada | Bridge  │
                        └───────────────────────────┘
```

### Three Layers of Implementation

#### Layer 1: Web Screens (80% of app)

Most screens render HTML from Rails, displayed in native web views:

- **Gig listings** - Reuse existing infinite scroll tables
- **Song details** - Existing view with lyrics, tabs, performances
- **Search results** - Existing omnisearch interface
- **Venue lists** - Existing table views
- **Composition details** - Album information and tracklists

**Implementation:**
- Minimal iOS code (navigation container)
- Existing ERB templates and Stimulus controllers
- Turbo handles page transitions
- Feels native with proper navigation

#### Layer 2: Enhanced Web (Bridge Components)

Add native features to web screens using **Strada bridge components**:

- **Native share sheet** - Share gigs/songs via iOS share
- **Native navigation** - iOS back button, tab bar
- **Native buttons** - iOS-style action buttons in navbar
- **Native alerts** - iOS-style notifications and confirmations
- **Native form controls** - Camera, location, file pickers

**Implementation:**
- Small Swift components (~50-100 lines each)
- JavaScript bridge in Stimulus controllers
- Graceful degradation (works on web without native)

#### Layer 3: Fully Native Screens (Critical features)

Build fully native for features that demand best performance:

**High Priority Native:**

1. **Media Player** - Native audio/video for embedded content
   - Better performance than web player
   - Background playback
   - Lock screen controls
   - Download for offline

2. **Map View** - Native map for venue exploration
   - Better gestures and performance
   - User location integration
   - Clustering for many venues

3. **On This Day** - Native dashboard/widget
   - iOS Today widget
   - Rich notifications
   - Offline access to cached data

**Lower Priority Native:**

4. **Offline Mode** - Download setlists for offline viewing
5. **Camera Integration** - Upload gig photos from app
6. **Quick Search** - Native search bar with suggestions

**Implementation:**
- Swift code for UI
- Fetch data from Rails JSON API
- Local caching with Core Data or Realm
- Turbo handles navigation between native and web

---

## Code Sharing Strategy

### What Gets Shared

#### Backend (100% shared)

```ruby
# All existing code works as-is
class GigsController < ApplicationController
  def index
    @gigs = Gig.includes(:venue, :gigsets => :song)
               .order(date: :desc)
               .page(params[:page])

    respond_to do |format|
      format.html  # Web and mobile use same view
      format.json  # For native screens
    end
  end
end
```

#### Views (80% shared)

```erb
<!-- app/views/gigs/index.html.erb -->
<!-- Used by web browser AND mobile app -->
<div class="container">
  <%= render partial: "gig_table", locals: { gigs: @gigs } %>
</div>

<!-- Mobile-specific styling via media queries or Turbo Native detection -->
<% if turbo_native_app? %>
  <meta name="turbo-visit-control" content="reload">
<% end %>
```

#### Stimulus Controllers (100% shared)

```javascript
// app/javascript/controllers/infinite_scroll_controller.js
// Works identically on web and mobile
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observeScrolling()
  }

  observeScrolling() {
    // Same code runs in mobile WebView
  }
}
```

#### CSS (85% shared)

```scss
// app/assets/stylesheets/robyn.css.scss
// Bootstrap works perfectly in mobile WebView

// Add mobile-specific overrides
@media (max-width: 768px) {
  .gig-table {
    font-size: 14px;
  }
}

// Turbo Native specific
.turbo-native {
  .navbar {
    display: none; // Use native navigation
  }
}
```

### What's Platform-Specific

#### iOS Native Code (~10-15% of mobile app)

```swift
// iOS/Sources/AppDelegate.swift
import UIKit
import HotwireNative

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

// iOS/Sources/SceneDelegate.swift
// Navigation setup (~100 lines)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = NavigationController()
        window?.makeKeyAndVisible()
    }
}

// iOS/Sources/BridgeComponents/ShareComponent.swift
// Native share button (~50 lines)
final class ShareComponent: BridgeComponent {
    override class var name: String { "share" }

    @objc func share() {
        // iOS share sheet implementation
    }
}
```

#### Android Code (Similar structure in Kotlin)

```kotlin
// Android/app/src/main/kotlin/MainActivity.kt
// Same concepts, different language
class MainActivity : HotwireNativeActivity() {
    // ~100-150 lines for setup
}
```

### API Development for Native Screens

For fully native screens, we'll need JSON endpoints:

```ruby
# New namespace: app/controllers/api/v1/
module Api
  module V1
    class GigsController < BaseController
      def index
        @gigs = Gig.includes(:venue, :gigsets => :song)
                   .order(date: :desc)
                   .page(params[:page])

        render json: GigSerializer.new(@gigs, params: { include_related: true })
      end

      def show
        @gig = Gig.includes(:venue, :gigsets => :song, :media).find(params[:id])
        render json: GigSerializer.new(@gig)
      end
    end
  end
end
```

**Estimated API work:**
- 5-10 controllers (Gigs, Songs, Venues, Compositions, Search)
- JSON serializers for each model
- Token authentication (devise-token-auth or custom JWT)
- ~2-3 weeks of development

---

## Implementation Roadmap

### Phase 1: Foundation (4-6 weeks)

**Goal:** Basic iOS app displaying web content

**Tasks:**

1. **Setup Hotwire Native iOS project**
   - Initialize Xcode project
   - Add Hotwire Native dependencies
   - Configure base URL (robynbase.com or staging)
   - Setup code signing and provisioning

2. **Rails backend adjustments**
   - Add Turbo Native detection helper
   - Create mobile-optimized layout (reduced navbar, simplified footer)
   - Add user agent detection
   - Test existing pages in mobile WebView

3. **Basic navigation**
   - Tab bar: Home, Search, On This Day, More
   - Native navigation stack
   - Handle all existing routes

4. **Testing and refinement**
   - Test all major flows
   - Fix any mobile-specific CSS issues
   - Optimize touch targets
   - Test on iPhone and iPad

**Deliverable:** Working iOS app browsing all existing RobynBase content

---

### Phase 2: Enhanced Features (4-6 weeks)

**Goal:** Add native polish and mobile-specific features

**Tasks:**

1. **Strada bridge components**
   - Native share button (share gigs, songs, setlists)
   - Native navbar buttons (+ iOS styled actions)
   - Native alerts and confirmations
   - Native form components (camera for photo upload)

2. **API development**
   - `/api/v1/gigs` endpoint
   - `/api/v1/songs` endpoint
   - `/api/v1/search` endpoint
   - `/api/v1/on_this_day` endpoint
   - Token authentication

3. **Mobile-specific views**
   - Simplified gig detail page
   - Mobile-optimized search interface
   - Improved table layouts for mobile

4. **Performance optimization**
   - Image optimization (WebP, lazy loading)
   - Reduce JavaScript bundle size
   - Optimize database queries for mobile

**Deliverable:** Polished iOS app with native feel

---

### Phase 3: Native Features (6-8 weeks)

**Goal:** Build high-value native screens

**Tasks:**

1. **Native media player** ⭐ High value
   - Audio player for Archive.org, Soundcloud
   - Video player for YouTube, Vimeo
   - Background playback
   - Lock screen controls
   - Download for offline

2. **Native map view** ⭐ High value
   - MapKit integration
   - Cluster venues by city
   - "Near me" functionality
   - Tap venue to see gigs

3. **On This Day widget** ⭐ High value
   - iOS Today widget
   - Show gigs from this date in history
   - Deep link to gig details
   - Local notifications

4. **Local caching**
   - Core Data schema
   - Sync recent gigs for offline
   - Cache search results
   - Downloaded media storage

**Deliverable:** Feature-complete iOS app with killer native features

---

### Phase 4: Polish & Launch (3-4 weeks)

**Goal:** App Store submission

**Tasks:**

1. **Testing**
   - Comprehensive QA across devices (iPhone SE to Pro Max, iPad)
   - Performance testing
   - Accessibility testing (VoiceOver, Dynamic Type)
   - Offline mode testing

2. **App Store preparation**
   - Screenshots and preview videos
   - App Store description
   - Privacy policy update
   - App Store guidelines compliance

3. **Analytics and monitoring**
   - Integrate analytics (Mixpanel, Firebase, or simple)
   - Crash reporting (Sentry or Crashlytics)
   - Performance monitoring

4. **Beta testing**
   - TestFlight distribution
   - Gather feedback from fans
   - Fix bugs and iterate

**Deliverable:** RobynBase iOS app live on App Store

---

### Total Timeline: 17-24 weeks (4-6 months)

This assumes:
- One full-time developer (iOS + Rails)
- Or two developers (one mobile-focused, one backend-focused)
- Part-time QA/testing support

---

## Android Path

### When to Start Android

**Recommendation:** Start Android development **after iOS Phase 2** is complete.

**Reasoning:**
- Validate the approach works on one platform first
- Reuse all backend work (API, mobile layouts, etc.)
- Learn from iOS mistakes
- iOS typically has higher engagement for niche content apps

### Android Development Effort

**Estimated timeline:** 60-70% of iOS timeline

- **Phase 1 (Foundation):** 3-4 weeks (faster, patterns established)
- **Phase 2 (Enhanced):** 3-4 weeks (API already built)
- **Phase 3 (Native):** 4-5 weeks (similar features, different implementation)
- **Phase 4 (Polish):** 2-3 weeks

**Total Android:** 12-16 weeks (3-4 months)

### Code Sharing: iOS to Android

While iOS and Android use different languages (Swift vs Kotlin), Hotwire Native enables **architectural code sharing**:

| Component | Shared? |
|-----------|---------|
| Backend (Rails) | ✅ 100% |
| Views (HTML/ERB) | ✅ 100% |
| Stimulus controllers | ✅ 100% |
| CSS | ✅ 100% |
| API contracts | ✅ 100% |
| Navigation structure | ✅ 90% (same concepts) |
| Bridge components | ⚠️ 0% (but same API) |
| Native screens | ⚠️ 0% (but same design) |

**Practical code sharing:** ~70-75% of total work reused

### Alternative: Cross-Platform Native

If Android is a near-term priority (within 6 months), consider:

**React Native or Flutter?**

❌ **Not recommended** for RobynBase because:
- Requires rewriting all frontend in JavaScript/TypeScript or Dart
- Can't reuse existing Turbo/Stimulus code
- Larger app bundle sizes
- Adds complexity to team skillset
- Still need Rails API work

✅ **Hotwire Native** is better because:
- Leverages existing Rails/Turbo/Stimulus code
- Smaller team can maintain both
- Consistent with Rails ecosystem
- 37signals proven approach

---

## Benefits & Trade-offs

### Benefits of Hotwire Native Approach

#### For Development

✅ **Massive code reuse** - 80-90% sharing across web and mobile
✅ **Small team efficiency** - Same developers, multiple platforms
✅ **Faster iteration** - Change once, deploy everywhere
✅ **Rails-native** - Works with your existing stack
✅ **Progressive enhancement** - Start simple, add native features gradually
✅ **Future-proof** - Aligned with modern Rails direction
✅ **Battle-tested** - Used by Basecamp, HEY in production

#### For Users

✅ **Consistent experience** - Same features across web and mobile
✅ **Always up-to-date** - Web content updates instantly
✅ **Native feel** - iOS/Android navigation patterns
✅ **Offline capable** - Can cache content for offline viewing
✅ **Better media** - Native players for audio/video
✅ **Location features** - "Find gigs near me"
✅ **Notifications** - "On This Day" reminders

#### For Business

✅ **Lower development cost** - One team vs. separate web/iOS/Android teams
✅ **Faster time to market** - Reuse existing code
✅ **Easier maintenance** - Fewer codebases to maintain
✅ **Flexibility** - Can adjust native/web balance over time

### Trade-offs to Consider

#### Limitations

⚠️ **Not 100% native feel** - Web screens won't feel as polished as fully native
⚠️ **Learning curve** - Team needs to learn iOS/Android development basics
⚠️ **Some features require native code** - Offline, notifications, etc.
⚠️ **WebView performance** - Slightly slower than fully native (usually imperceptible)
⚠️ **App size** - Includes WebView, ~10-15MB vs ~5MB for pure native

#### When Fully Native is Better

Pure native (Swift/SwiftUI or Kotlin/Jetpack Compose) would be better if:

- App is used primarily on mobile (web is secondary)
- Requires complex animations and gestures throughout
- Needs extensive offline capabilities
- Performance is absolutely critical
- Budget allows for separate mobile team

**For RobynBase:** None of these apply. RobynBase is primarily a **content browsing** app with occasional updates, which is perfect for Hotwire Native's hybrid approach.

---

## Resource Requirements

### Team

**Minimum viable:**
- 1 full-stack developer (Rails + iOS basics)
- Part-time QA/testing

**Ideal:**
- 1 Rails developer (backend, API, mobile layouts)
- 1 iOS developer (native screens, bridge components)
- Part-time designer (mobile-specific UI/UX)
- Part-time QA/testing

### Skills Needed

**Must have:**
- Rails development (already have ✅)
- HTML/CSS/JavaScript (already have ✅)
- Git/version control (already have ✅)

**Need to learn:**
- Swift basics (Xcode, UIKit/SwiftUI fundamentals)
- iOS development concepts (view controllers, navigation, storyboards)
- Hotwire Native framework (well-documented)
- App Store submission process

**Learning resources:**
- Official Hotwire Native docs: https://native.hotwired.dev/
- "Hotwire Native for Rails Developers" (book, currently in beta)
- 37signals Dev blog: https://dev.37signals.com/
- iOS tutorials for Rails developers

**Time to proficiency:** 2-4 weeks for Rails developer to learn enough iOS

### Infrastructure

**Development:**
- Mac computer (required for iOS development) - $1,000-2,500
- Apple Developer account - $99/year
- Xcode (free)
- TestFlight for beta testing (free)

**Backend:**
- Existing Rails infrastructure (already have ✅)
- Possible: Staging server for mobile testing - ~$20-50/month

**Optional services:**
- Analytics (Mixpanel/Firebase) - Free tier available
- Crash reporting (Sentry) - Free tier available
- Push notifications (AWS SNS or OneSignal) - Free tier available

**Total infrastructure cost:** ~$100-150/year (mostly Apple Developer account)

---

## Alternatives Considered

### Option 1: Progressive Web App (PWA)

**Description:** Make the existing website installable as a PWA

**Pros:**
- ✅ Zero iOS development needed
- ✅ Works on all platforms (iOS, Android, desktop)
- ✅ Instant updates
- ✅ Smallest development effort

**Cons:**
- ❌ Limited iOS features (no push notifications, limited offline)
- ❌ Not discoverable in App Store
- ❌ Less "app-like" feel
- ❌ Can't access native APIs (camera, location, etc.)

**Verdict:** Good for quick win, but limited long-term value on iOS

---

### Option 2: Fully Native iOS (Swift/SwiftUI)

**Description:** Build a completely native iOS app from scratch

**Pros:**
- ✅ Best possible iOS experience
- ✅ Full access to iOS APIs
- ✅ Best performance
- ✅ Most "Apple-like" feel

**Cons:**
- ❌ ~0% code sharing with web
- ❌ Need to duplicate all features
- ❌ Requires dedicated iOS developer
- ❌ Android would require separate Kotlin app
- ❌ Much longer development time (6-12 months)
- ❌ Higher maintenance burden (3 codebases)

**Verdict:** Overkill for RobynBase's needs; too expensive

---

### Option 3: React Native

**Description:** Build iOS and Android apps with React Native

**Pros:**
- ✅ One codebase for iOS and Android
- ✅ Large community and ecosystem
- ✅ Can share some business logic
- ✅ Hot reload for faster development

**Cons:**
- ❌ Need to rewrite all frontend in React
- ❌ Can't reuse existing Turbo/Stimulus code
- ❌ Still need Rails API (same work as Hotwire Native)
- ❌ Larger app bundle size
- ❌ Different skillset from Rails team
- ❌ Occasional native module issues

**Verdict:** Doesn't leverage existing Rails/Turbo investment

---

### Option 4: Flutter

**Description:** Build iOS and Android apps with Flutter (Dart)

**Pros:**
- ✅ One codebase for iOS and Android
- ✅ Excellent performance
- ✅ Beautiful UI out of box
- ✅ Growing ecosystem

**Cons:**
- ❌ Completely new language (Dart)
- ❌ Can't reuse any existing frontend code
- ❌ Still need Rails API
- ❌ Even further from Rails ecosystem
- ❌ Smaller community than React Native

**Verdict:** Too far from existing skillset

---

### Comparison Matrix

| Approach | Code Reuse | Dev Time (iOS) | Dev Time (Android) | Team Size | Long-term Maintenance |
|----------|------------|----------------|-------------------|-----------|----------------------|
| **Hotwire Native** ⭐ | 80-90% | 4-6 months | 3-4 months | 1-2 devs | Low (shared code) |
| PWA | 100% | 2-4 weeks | 0 (same app) | 1 dev | Very Low |
| Fully Native | 0% | 6-12 months | 6-12 months | 2-4 devs | High (3 codebases) |
| React Native | 30-40% | 6-9 months | 0 (same app) | 2-3 devs | Medium (2 codebases) |
| Flutter | 30-40% | 6-9 months | 0 (same app) | 2-3 devs | Medium (2 codebases) |

---

## Recommendation

### ✅ Proceed with Hotwire Native

**Hotwire Native is the clear choice for RobynBase because:**

1. **Perfect alignment** with existing Rails 7.2 + Turbo + Stimulus stack
2. **Maximum code reuse** (~80-90%) across web, iOS, and Android
3. **Small team efficiency** - same developers can build all platforms
4. **Proven approach** - used successfully by 37signals
5. **Progressive path** - start simple, add native features as needed
6. **Android-ready** - same approach works for Android with 70-75% code sharing
7. **Cost-effective** - lowest development and maintenance costs

### Implementation Strategy

**Phase 1 (Immediate):** Start with iOS foundation
- 4-6 weeks to basic app
- Validate approach with web content in native shell
- Low risk, high learning value

**Phase 2 (3 months):** Add polish and API
- Native features via bridge components
- Build API for future native screens
- App starts feeling native

**Phase 3 (6 months):** Build killer native features
- Media player, maps, offline mode
- Launch on App Store
- Gather user feedback

**Phase 4 (9-12 months):** Add Android
- Reuse all backend work
- 3-4 months to Android parity
- Now supporting web, iOS, and Android with small team

### Success Metrics

**After 6 months (iOS launch):**
- iOS app in App Store
- 1,000+ downloads from Robyn Hitchcock fans
- 4.5+ star rating
- 70%+ of iOS users are active weekly
- <1% crash rate

**After 12 months (Android launch):**
- Both iOS and Android apps available
- 5,000+ total downloads
- 30% of RobynBase usage is mobile
- Maintaining all platforms with small team

### Next Steps

If approved, we should:

1. **Week 1:** Setup development environment
   - Purchase/setup Mac for iOS development
   - Register Apple Developer account
   - Install Xcode and create "Hello World" Hotwire Native app

2. **Week 2:** Prototype foundation
   - Point app at staging.robynbase.com
   - Test existing pages in WebView
   - Identify CSS/layout issues

3. **Week 3-4:** Plan detailed implementation
   - Create detailed tickets for Phase 1
   - Design mobile-specific layouts
   - Plan API structure

4. **Month 2+:** Begin Phase 1 implementation

---

## Appendix: Additional Resources

### Documentation

- **Hotwire Native Official Docs:** https://native.hotwired.dev/
- **Turbo Handbook:** https://turbo.hotwired.dev/handbook/
- **Strada (Bridge Components):** https://strada.hotwired.dev/
- **37signals Dev Blog:** https://dev.37signals.com/

### Learning Resources

- **"Hotwire Native for Rails Developers"** - Book by Joe Masilotti (in beta)
- **Masilotti.com tutorials** - Excellent step-by-step guides
- **SupeRails Hotwire Native series** - Video tutorials
- **William Kennedy's blog** - Recent iOS and Android tutorials

### Code Examples

- **GitHub: hotwire-native-ios** - https://github.com/hotwired/hotwire-native-ios
- **GitHub: hotwire-native-android** - https://github.com/hotwired/hotwire-native-android
- **Turbo iOS Demo** - Sample app in repository
- **Turbo Android Demo** - Sample app in repository

### Community

- **Hotwire Discussion Forum:** https://discuss.hotwired.dev/
- **37signals Discord** - Active community
- **r/rails** - Reddit community often discusses Hotwire Native

---

## Questions or Concerns?

This proposal is a starting point for discussion. Key questions to consider:

1. **Timeline:** Is 4-6 months to iOS launch acceptable?
2. **Resources:** Can we allocate developer time or need to hire?
3. **Priorities:** Which native features are most valuable?
4. **Android timing:** When do we want Android (immediately after iOS, or wait)?
5. **Budget:** Any constraints on Apple Developer account, hardware, etc.?

---

**End of Proposal**

*This proposal will be updated based on feedback and as we learn more during prototyping.*
