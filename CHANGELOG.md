# Changelog

## 1.2.0+7 — 2026-07-30

Build number raised above App Store Connect’s last uploaded build (`6`).

## 1.2.0+3 — 2026-07-30 (superseded build)

### Added
- Offline-first Train and Profile: cache routines/profile, complete workouts offline, sync when back online
- Incremental cloud exercise catalog downloads with local media cache
- Offline status banner and sync bootstrap (upload prompts only for pending sessions)
- Social feed: posts, comments, reactions, and bell notifications
- Max-weight personal records and routine sync/duplicate from workout summary
- Quick Add voice notes (Whisper/Gemini) and clearer food-entry hints
- Daily bilingual fitness tip popup
- Cloud exercise catalog with browse, filter, and similar-swap
- Runner and Hyrox modes (GPS, elevation, share cards, anti-fraud checks)
- BYOK AI access and proactive gym weight rules
- First-run onboarding with routine and food tutorials
- Finish-workout confirmation to avoid accidental ends
- Customizable accent colors and Gymrat plan badge

### Fixed
- Offline routine cache so routines load without network
- Similar-exercise swap sets and cancel-upload banner behavior
- Concentration curl per-arm toggle and runner calories in food budget
- Quick Add portion parsing and multi-ingredient underestimates (eggs, oats)
- Photo food estimates returning 0 calories with valid grams
- Per-machine kg/lb session toggle and “por pierna” load labels
- Blank screen after finishing a workout
- Exercise history leaking student sessions for trainers
- Runner crash and outdoor elevation/auto-start UX
- Workout summary share on iOS
- Social feed post lookups and session PR highlight dedupe

### Changed
- AI Coach routine generation uses cloud exercises, limits, and equipment
- Built-in runner routines award 2.5× run XP
- Profile metrics simplified; workout load controls polished

## 1.1.0+3 — 2026-07-28

Superseded by 1.2.0 before the version bump landed on `main` (tag `v1.1.0` remains for history).

## 1.0.0+2 — 2026-07-10

- iOS TestFlight bundle ID `io.fitforge.app`
- Initial public build baseline
