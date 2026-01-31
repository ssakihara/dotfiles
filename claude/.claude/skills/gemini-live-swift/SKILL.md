---
name: gemini-live-swift
description: "Comprehensive Swift implementation guide for Gemini Live API using Firebase AI Logic SDK. Use when building real-time voice conversational AI features in iOS/macOS apps with FirebaseAILogic 12.8.0 or later. This skill provides: (1) Audio recording and playback at 24kHz PCM format, (2) LiveModel session management with connect/disconnect, (3) Transcription support for input/output audio, (4) SwiftUI-based architecture with AudioManager, SessionManager, and UI layers, (5) Google AI API backend integration. Trigger for tasks like add Gemini Live voice chat, implement real-time audio conversation, build voice assistant with Gemini."
---

# Gemini Live API for Swift (Firebase AI Logic)

Real-time voice conversational AI using Firebase AI Logic SDK with Gemini Live API.

## Quick Start

### Prerequisites

- Xcode 16.2+
- iOS 15+ or macOS 12+
- Swift Package Manager
- Google AI API key ([Get one here](https://ai.google.dev/))

### Install SDK

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.8.0")
]
```

Target dependencies:
```swift
.product(name: "FirebaseAILogic", package: "firebase-ios-sdk")
```

### Basic Implementation

See [references/basic-implementation.md](references/basic-implementation.md) for minimal working example.

## Architecture Patterns

This skill supports two implementation patterns:

### Pattern 1: Basic (Single File)
- Single View/Single File implementation
- Good for prototypes and learning
- See: [references/basic-implementation.md](references/basic-implementation.md)

### Pattern 2: Layered Architecture (Production-Ready)
- **AudioManager**: Handles recording/playback with 24kHz PCM
- **SessionManager**: Manages LiveModel connection state
- **ViewModel**: Connects audio to Gemini Live session
- **SwiftUI View**: Reactive UI with Combine
- See: [references/architecture.md](references/architecture.md)

## Audio Format Requirements

**Critical**: Gemini Live API requires specific audio formats:

| Direction | Format | Sample Rate |
|-----------|--------|-------------|
| Input (Recording) | 16-bit PCM, mono | 24kHz |
| Output (Playback) | 16-bit PCM, mono | 24kHz |

See [references/audio-guide.md](references/audio-guide.md) for complete audio handling details.

## Configuration

### Required Dependencies

```swift
import FirebaseAILogic
import AVFoundation
import Combine
```

### LiveModel Configuration

```swift
let liveModel = FirebaseAI.firebaseAI(backend: .googleAI()).liveModel(
    modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
    generationConfig: LiveGenerationConfig(
        responseModalities: [.audio],
        // Optional: Enable transcription
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig()
    )
)
```

### Supported Models (Google AI API)

- `gemini-2.5-flash-native-audio-preview-12-2025` (Latest, free tier)
- `gemini-2.5-flash-native-audio-preview-09-2025` (Previous)

### Voice Options

Set `speechConfig.voiceName` in `LiveGenerationConfig`. Available voices:
- `Puck` (default, cheerful)
- `Zephyr`, `Kore`, `Orus`, `Autonoe`, `Umbriel`, `Erinome`
- And 20+ more - see [references/configuration.md](references/configuration.md)

## Session Management

### Basic Connect/Disconnect

```swift
let session = try await liveModel.connect()
// Send audio...
try await session.close()
```

### Robust Session Management (Recommended)

For production apps, implement:
- Reconnection logic with exponential backoff
- Connection state tracking with Actor
- Error handling and recovery
- Session lifecycle management

See [references/session-management.md](references/session-management.md) for complete implementation.

## Transcription

Enable transcription in `LiveGenerationConfig`:

```swift
inputAudioTranscription: AudioTranscriptionConfig(),
outputAudioTranscription: AudioTranscriptionConfig()
```

Handle transcribed text in response loop:

```swift
if let inputText = content.inputAudioTranscription?.text {
    // Handle user speech transcription
}
if let outputText = content.outputAudioTranscription?.text {
    // Handle model response transcription
}
```

## Language Support

Live API auto-detects language. To enforce specific language, use system instruction:

```swift
// Swift doesn't have a direct systemInstruction parameter in LiveGenerationConfig
// Send as first text message or use backend configuration
```

Supported languages: English, Japanese, Korean, Spanish, French, German, and 15+ more. See [references/configuration.md](references/configuration.md) for full list.

## Common Workflows

### 1. Start Voice Conversation

1. Request microphone permission
2. Create `LiveModel` with audio modality
3. Connect to session
4. Start audio recorder (24kHz PCM)
5. Stream audio chunks via `sendAudioRealtime()`
6. Receive and play response audio
7. Close session when done

### 2. Add Transcription

Add `inputAudioTranscription` and `outputAudioTranscription` to `LiveGenerationConfig`.

### 3. Change Voice

Set `speechConfig.voiceName` in `LiveGenerationConfig`.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Audio not playing | Ensure 24kHz format, check audio session |
| Connection fails | Verify API key, check network |
| Transcription missing | Add AudioTranscriptionConfig |
| Poor audio quality | Check sample rate conversion |

## References

- [Official Firebase AI Logic Docs](https://firebase.google.com/docs/ai-logic/live-api)
- [Configuration Options](https://firebase.google.com/docs/ai-logic/live-api/configuration)
- [API Reference](https://firebase.google.com/docs/ai-logic/ref-docs)

## Asset Templates

Code templates are available in `assets/`:
- `assets/templates/Basic/` - Single file implementation
- `assets/templates/Architecture/` - Layered architecture implementation

## Limitations

- Session duration: 15 minutes maximum
- Free tier: 15 requests/day (Google AI API)
- Vertex AI: Live API NOT supported in `global` location
- No context compression between sessions
