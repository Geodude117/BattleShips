# Salvo Sums — App Store submission

Everything needed to submit Salvo Sums, and the text to paste into App Store Connect.

## Checklist

### Already done in this repo
- [x] App icon, 1024 × 1024 PNG with no transparency (`BattleMaths/Assets.xcassets/AppIcon.appiconset`)
- [x] Display name "Salvo Sums" and bundle ID `com.geodude117.SalvoSums`
- [x] Privacy manifest (`BattleMaths/PrivacyInfo.xcprivacy`): no tracking, no data collected, UserDefaults declared with reason `CA92.1`
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO`, so App Store Connect won't ask about encryption on every upload
- [x] Privacy policy and support pages, linked from the app's menu
- [x] Screenshots for 6.9" iPhone and 13" iPad (`docs/screenshots/`)

### You need to do
- [ ] Join the [Apple Developer Program](https://developer.apple.com/programs/) (£79 a year as an individual)
- [ ] In Xcode, pick your team under **BattleMaths target → Signing & Capabilities**
- [ ] Test on a real iPhone, including the sound effects and haptics
- [ ] In [App Store Connect](https://appstoreconnect.apple.com), create the app with bundle ID `com.geodude117.SalvoSums` (this also reserves the name)
- [ ] Fill in the listing below, the App Privacy section and the age rating questionnaire
- [ ] Upload a build: **Product → Archive** in Xcode, then **Distribute App → App Store Connect**
- [ ] Optional: try it with friends through TestFlight before release
- [ ] Choose the build in App Store Connect and **Submit for Review**

## Listing text

| Field | Value | Limit |
| --- | --- | --- |
| Name | Salvo Sums | 30 |
| Subtitle | GCSE maths sea battle game | 30 |
| Primary category | Education | |
| Secondary category | Games | |
| Keywords | `gcse,maths,math,revision,fractions,algebra,percentages,pythagoras,ratio,probability,equations,quiz` | 100 |
| Support URL | https://geodude117.github.io/Portfolio/salvo-sums/ | |
| Privacy Policy URL | https://geodude117.github.io/Portfolio/salvo-sums/privacy/ | |
| Copyright | 2026 Geovan | |
| Price | Free | |

Keep the word "Battleship" out of the name, subtitle and keywords. It's a Hasbro trademark, and Apple can reject listings that use other companies' trademarks.

### Promotional text (170 characters, can be changed any time without review)

Five in a row unlocks an Airstrike or Sonar scan. Every wrong answer comes with a worked explanation, so you learn as you play.

### Description

Sink the enemy fleet with your maths skills.

Salvo Sums turns GCSE maths revision into a naval battle. You can't fire until you've earned your ammo, and the only way to load your guns is to answer a maths question correctly.

HOW IT WORKS
• Place your five ships on the grid, or let the game place them for you.
• Answer a multiple-choice question to load your guns. Foundation questions earn one shot, Higher questions earn two.
• Get three in a row for a bonus shot, and five in a row to unlock a special weapon: an Airstrike that hits five squares, or a Sonar scan that reveals hidden ships.
• The computer has to answer its own questions too, so your accuracy decides who wins.

LEARN AS YOU PLAY
Every question has four answers, and the wrong ones are built from the mistakes students really make, such as adding the bottoms of fractions or forgetting to divide. Get one wrong and you'll see a short worked explanation, so you know exactly where it went wrong.

GCSE TOPICS
• Fractions
• Percentages
• Ratio
• Linear equations
• Area
• Probability
• Expanding brackets
• Pythagoras

THREE DIFFICULTY LEVELS
Easy, Medium and Hard opponents, from random shots to a computer that hunts down your ships once it finds them.

PRIVATE BY DESIGN
No accounts, no ads, no tracking and no internet connection needed. Salvo Sums doesn't collect any personal data.

### App Review notes

Salvo Sums needs no login and works fully offline. To play: tap "Random fleet", then "Start battle", then "Answer a question to load ammo". A correct answer loads shots to fire at the "Enemy waters" grid.

## App Privacy answers

- **Data collection:** "No, we do not collect data from this app" → shown as **Data Not Collected**.

## Age rating

Answer the questionnaire honestly. The app has no violence beyond sinking abstract ships on a grid, no user-generated content, no web browsing and no purchases, so it should come out at the lowest rating. Don't opt into the **Kids** category: it's meant for children under 11, and GCSE students are older.

## Screenshots

| Size | Folder | Pixels |
| --- | --- | --- |
| iPhone 6.9" | `docs/screenshots/iphone-6.9/` | 1320 × 2868 |
| iPad 13" | `docs/screenshots/ipad-13/` | 2064 × 2752 |

Upload them in order: battle, question, explanation, placement. App Store Connect scales them down for smaller devices.

### Updating the screenshots

1. In Xcode, choose the **Screenshots** scheme.
2. Pick the **iPhone 16 Pro Max** simulator and press **⌘U**.
3. Pick the **iPad Pro 13-inch** simulator and press **⌘U** again.
4. The PNGs are saved straight into `docs/screenshots/`. Switch back to the **BattleMaths** scheme afterwards.

The test launches the app with `-screenshots battle` or `-screenshots question`, which set up a ready-made mid-game position. That only works in debug builds, so it never ships to players.
