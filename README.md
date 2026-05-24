# SnapBack

A mindful productivity Flutter app for teenagers. Plan your day by voice; when you scroll past your self-set limit on Instagram / TikTok / YouTube / Snapchat, SnapBack draws a gentle overlay referencing the actual tasks you said you'd do.

## Setup

1. **Install deps**
   ```bash
   flutter pub get
   ```

2. **Configure secrets**
   - `.env` is gitignored. The hackathon `.env` ships in the working tree with a real OpenAI key.
   - For a clean checkout: `cp .env.example .env` and paste your key.

3. **Run**
   ```bash
   flutter run
   ```

## Architecture

- **`lib/main.dart`** — entry point, Hive + dotenv + notifications init, routing
- **`lib/config/`** — env, constants, calm-minimalist theme
- **`lib/models/`** — Hive types (TaskModel, SessionModel) with hand-written adapters
- **`lib/services/`** — storage, voice (Whisper), notifications, permissions, overlay bridge, native sync
- **`lib/agents/`** — 4 OpenAI agents: TaskExtractor, Intervention, MoodSafetyGate, Reflection
- **`lib/state/`** — Provider-based state for tasks, sessions, prefs
- **`lib/screens/`** — Onboarding, Home, VoiceInput, Planner, Reflection, Settings
- **`android/app/src/main/kotlin/.../`** — AccessibilityService, OverlayService, BootReceiver, MainActivity

## How the intervention loop works

1. `SnapBackAccessibilityService` watches `TYPE_WINDOW_STATE_CHANGED` for the 4 monitored packages.
2. Every 30s, it checks if the current session has exceeded the user's scroll limit (read from native SharedPreferences, pushed there from Dart on app pause).
3. If exceeded, it starts `OverlayService` with the app name + minutes.
4. `OverlayService` becomes a foreground service, inflates `overlay_intervention.xml` via `WindowManager.addView` with `TYPE_APPLICATION_OVERLAY`.
5. It calls Flutter via `MethodChannel("com.snapback.app/overlay") → getInterventionMessage` — Dart's `OverlayBridgeService` invokes `InterventionAgent` which posts to OpenAI and returns a personalized message.
6. The user must type ≥5 characters to unlock the buttons. Each keystroke (debounced 1s) calls `classifyMood` → `MoodSafetyGate`; if distress is detected, the overlay swaps to a caring response with the Umang helpline.
7. Sessions are CSV-queued in native prefs and drained into Hive when the Flutter app next resumes.

## Streak rules

Runs in `StorageService.computeAndUpdateStreak()`, called when ReflectionScreen opens after the user's reflection hour:

- `plannedToday == 0` → keep streak (don't punish empty days)
- `completionRate >= 0.5` AND `scrollToday <= 2 × limit` → +1 if yesterday continued, else reset to 1
- Otherwise → 0

## Known limits (hackathon scope)

- OpenAI key sits in the APK. Production path: move agent HTTP calls to a Cloudflare Worker proxy.
- Whisper is request/response — no live transcript streaming.
- In-app scroll detection (TYPE_VIEW_SCROLLED) is unreliable across Android versions; we use foreground-app duration which works everywhere.
- OEM battery savers (Xiaomi, Realme, Oppo) may kill the accessibility service. Settings screen surfaces this; user must disable battery optimization manually.

## Testing

```bash
flutter analyze
flutter test
```

For UI verification, enable **Settings → Demo data** to seed 5 tasks + 3 sessions. Toggle off to clear.
