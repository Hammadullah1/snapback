# 📱 SnapBack

> **A mindful productivity app for teenagers that gently interrupts doomscrolling and reconnects users with the goals they set for themselves.**

SnapBack helps users stay intentional with their screen time. Instead of blocking apps or using guilt-based notifications, it provides calm, personalized interventions based on tasks the user previously planned using their own voice.

When a user exceeds their self-defined scrolling limit on apps like **Instagram**, **TikTok**, **YouTube**, or **Snapchat**, SnapBack displays a thoughtful overlay reminding them of the commitments they made earlier.

---

# ✨ Features

* 🎙️ Voice-based daily planning
* 🤖 AI-powered task extraction using OpenAI
* 📱 Detects time spent on distracting apps
* 💬 Personalized intervention messages
* 🧠 Mood-aware safety detection
* 📝 Daily reflection journal
* 🔥 Productivity streak tracking
* 💾 Offline local storage using Hive
* 🔔 Local notifications
* ⚡ Lightweight Flutter architecture

---

# 🛠️ Tech Stack

### Frontend

* Flutter
* Provider (State Management)

### AI

* OpenAI GPT
* Whisper Speech-to-Text

### Storage

* Hive
* SharedPreferences

### Android Native

* Accessibility Service
* Foreground Overlay Service
* Method Channels
* WindowManager Overlay

---

# 🚀 Getting Started

## 1. Install Dependencies

```bash
flutter pub get
```

---

## 2. Configure Environment Variables

The project uses a `.env` file for API keys.

Create your environment file:

```bash
cp .env.example .env
```

Then add your OpenAI API key:

```env
OPENAI_API_KEY=your_api_key_here
```

---

## 3. Run the Application

```bash
flutter run
```

---

# 📂 Project Structure

```
lib/
│
├── agents/
│   ├── TaskExtractor
│   ├── Intervention
│   ├── MoodSafetyGate
│   └── Reflection
│
├── config/
│   ├── Constants
│   ├── Environment
│   └── Theme
│
├── models/
│   ├── TaskModel
│   └── SessionModel
│
├── screens/
│   ├── Home
│   ├── Planner
│   ├── VoiceInput
│   ├── Reflection
│   ├── Settings
│   └── Onboarding
│
├── services/
│   ├── Storage
│   ├── Voice
│   ├── Overlay Bridge
│   ├── Notifications
│   ├── Permissions
│   └── Native Sync
│
├── state/
│   └── Provider State Management
│
└── main.dart
```

Android-specific components are located in:

```
android/app/src/main/kotlin/
```

including:

* Accessibility Service
* Overlay Service
* Boot Receiver
* Main Activity

---

# ⚙️ How It Works

## 1. Daily Planning

The user speaks about the tasks they plan to complete.

↓

## 2. AI Task Extraction

Whisper converts speech to text.

OpenAI extracts structured tasks from the transcript.

↓

## 3. Activity Monitoring

An Android Accessibility Service monitors whether the user is actively using:

* Instagram
* TikTok
* YouTube
* Snapchat

↓

## 4. Scroll Limit Detection

Every 30 seconds the service checks whether the user's predefined screen-time limit has been exceeded.

↓

## 5. Personalized Intervention

If the limit is reached:

* A foreground overlay appears.
* Flutter requests an AI-generated intervention message.
* The message references the user's own planned tasks to encourage mindful choices.

↓

## 6. Mood Safety Check

To dismiss the overlay, the user types a short response.

Each response is analyzed by the Mood Safety agent.

If signs of emotional distress are detected, the intervention changes to a more supportive message and provides the Umang helpline.

↓

## 7. Session Synchronization

Screen-time sessions are temporarily stored in native SharedPreferences and synchronized into Hive when the Flutter application resumes.

---

# 🔥 Streak System

The streak is updated when the Reflection screen opens after the user's configured reflection hour.

### Rules

* No planned tasks → streak is preserved.
* At least **50%** of planned tasks completed **and**
  total scrolling time ≤ **2×** the user's limit → streak increases.
* Otherwise → streak resets.

---

# 🧪 Testing

Run static analysis:

```bash
flutter analyze
```

Run unit tests:

```bash
flutter test
```

---

# 🎮 Demo Mode

Navigate to:

```
Settings → Demo Data
```

Enable Demo Data to automatically generate:

* 5 sample tasks
* 3 sample sessions

Disable it to clear the demo content.

---

# ⚠️ Known Limitations

* The OpenAI API key is currently bundled with the APK for hackathon purposes. A production deployment should proxy requests through a secure backend (e.g., Cloudflare Workers).
* Whisper is used in request/response mode and does not support live transcription.
* Android's `TYPE_VIEW_SCROLLED` event is inconsistent across devices, so screen-time tracking is based on foreground application duration.
* Some Android manufacturers (e.g., Xiaomi, Realme, Oppo) may terminate Accessibility Services due to aggressive battery optimization. Users may need to manually disable battery optimization for reliable operation.

---

# 📌 Future Improvements

* Backend proxy for secure API key management
* Live streaming speech transcription
* Cross-device synchronization
* Weekly and monthly productivity insights
* Smart adaptive interventions
* Wear OS support
* AI-generated productivity summaries
* Family accountability mode

---

# 📄 License

This project was developed as part of a hackathon and is intended for educational and demonstration purposes.
