# Configuration Reference

Complete configuration options for Gemini Live API.

## LiveGenerationConfig

### Basic Configuration

```swift
LiveGenerationConfig(
    responseModalities: [.audio],
    // Optional configurations below
)
```

### All Parameters

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| `responseModalities` | `Set<ResponseModality>` | Yes | - |
| `speechConfig` | `SpeechConfig` | No | `Puck` voice |
| `inputAudioTranscription` | `AudioTranscriptionConfig` | No | Disabled |
| `outputAudioTranscription` | `AudioTranscriptionConfig` | No | Disabled |

## Response Modalities

```swift
enum ResponseModality {
    case audio    // Voice response only
    case text     // Text response only
}
```

### Audio-Only (Recommended for Voice Chat)

```swift
LiveGenerationConfig(
    responseModalities: [.audio]
)
```

### Text + Audio

```swift
LiveGenerationConfig(
    responseModalities: [.audio, .text]
)
```

## Voice Configuration

### Prebuilt Voices

Set voice in `SpeechConfig`:

```swift
LiveGenerationConfig(
    responseModalities: [.audio],
    speech: SpeechConfig(voiceName: "Puck")  // Default
)
```

### Available Voices

| Voice Name | Description |
|------------|-------------|
| `Puck` | Cheerful (default) |
| `Fenrir` | Excited |
| `Aoede` | Lighthearted |
| `Enceladus` | Breath |
| `Algieba` | Mellow |
| `Algenib` | Raspy |
| `Achernar` | Soft |
| `Gacrux` | Mature |
| `Zubenelgenubi` | Casual |
| `Sadaltager` | Professional |
| `Charon` | Informative |
| `Leda` | Youthful |
| `Callirrhoe` | Laid-back |
| `Iapetus` | Clear |
| `Despina` | Fluid |
| `Rasalgethi` | Informative |
| `Alnilam` | Firm |
| `Pulcherrima` | Upbeat |
| `Vindemiatrix` | Gentle |
| `Sulafat` | Warm |
| `Zephyr` | Bright |
| `Kore` | Firm |
| `Orus` | Firm |
| `Autonoe` | Bright |
| `Umbriel` | Relaxed |
| `Erinome` | Clear |
| `Laomedeia` | Cheerful |
| `Schedar` | Smooth |
| `Achird` | Friendly |
| `Sadachbia` | Lively |

## Transcription Configuration

### Enable Both Input and Output

```swift
LiveGenerationConfig(
    responseModalities: [.audio],
    inputAudioTranscription: AudioTranscriptionConfig(),
    outputAudioTranscription: AudioTranscriptionConfig()
)
```

### AudioTranscriptionConfig

Currently no additional parameters:

```swift
struct AudioTranscriptionConfig {
    // Empty - language auto-detected
}
```

### Handling Transcriptions

```swift
for try await message in session.responses {
    if case .content(let content) = message.payload {
        // User's speech transcription
        if let inputText = content.inputAudioTranscription?.text {
            print("You said: \(inputText)")
        }

        // Model's response transcription
        if let outputText = content.outputAudioTranscription?.text {
            print("Gemini said: \(outputText)")
        }
    }
}
```

## Model Names

### Google AI API (Free Tier Available)

| Model | Notes |
|-------|-------|
| `gemini-2.5-flash-native-audio-preview-12-2025` | Latest, use this |
| `gemini-2.5-flash-native-audio-preview-09-2025` | Previous version |

### Vertex AI API (Enterprise Only)

| Model | Notes |
|-------|-------|
| `gemini-live-2.5-flash-native-audio` | Released Dec 2025 |
| `gemini-live-2.5-flash-preview-native-audio-09-2025` | Preview |

**Important**: Vertex AI Live API is NOT supported in `global` location.

## Language Support

### Supported Languages

| Language | BCP-47 Code |
|----------|-------------|
| Arabic (Egypt) | ar-EG |
| German (Germany) | de-DE |
| English (US) | en-US |
| Spanish (US) | es-US |
| French (France) | fr-FR |
| Hindi (India) | hi-IN |
| Indonesian (Indonesia) | id-ID |
| Italian (Italy) | it-IT |
| Japanese (Japan) | ja-JP |
| Korean (Korea) | ko-KR |
| Dutch (Netherlands) | nl-NL |
| Polish (Poland) | pl-PL |
| Portuguese (Brazil) | pt-BR |
| Russian (Russia) | ru-RU |
| Thai (Thailand) | th-TH |
| Turkish (Turkey) | tr-TR |
| Vietnamese (Vietnam) | vi-VN |
| Romanian (Romania) | ro-RO |
| Ukrainian (Ukraine) | uk-UA |
| Bengali (Bangladesh) | bn-BD |
| English (India) | en-IN |
| Marathi (India) | mr-IN |
| Tamil (India) | ta-IN |
| Telugu (India) | te-IN |

### Forcing Language

Use system instruction (sent as first text message):

```swift
// Send as first message after connecting
let systemPrompt = """
Listen to the speaker carefully. If you detect a non-English language,
respond in the language you hear from the speaker.
You must respond unmistakably in the speaker's language.
"""
try await session.sendTextRealtime(systemPrompt)
```

Or enforce specific language:

```swift
let systemPrompt = "RESPOND IN JAPANESE. YOU MUST RESPOND UNMISTAKABLY IN JAPANESE."
try await session.sendTextRealtime(systemPrompt)
```

## Backend Configuration

### Google AI API (Recommended for Development)

```swift
let backend: GenerativeBackend = .googleAI()
// Requires: Google AI API key from https://ai.google.dev/
```

### Vertex AI API (Enterprise)

```swift
let backend: GenerativeBackend = .vertexAI(
    projectID: "your-project-id",
    location: "us-central1"  // NOT "global"!
)
// Requires: Vertex AI enabled, ADC configured
```

## Complete Configuration Example

```swift
let liveModel = FirebaseAI.firebaseAI(backend: .googleAI()).liveModel(
    modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
    generationConfig: LiveGenerationConfig(
        // Audio-only response
        responseModalities: [.audio],

        // Japanese female voice
        speech: SpeechConfig(voiceName: "Leda"),

        // Enable transcription
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig()
    )
)
```
