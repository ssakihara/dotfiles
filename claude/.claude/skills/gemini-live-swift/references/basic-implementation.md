# Basic Implementation

Minimal single-file implementation for prototyping.

## Prerequisites

```swift
import FirebaseAILogic
import AVFoundation
```

## Complete Code

```swift
import SwiftUI
import FirebaseAILogic
import AVFoundation

struct BasicVoiceChatView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var sessionManager = SessionManager()
    @State private var isConnected = false
    @State private var transcribedText = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.title)

            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .padding()
            }

            Button(isConnected ? "Disconnect" : "Connect") {
                if isConnected {
                    disconnect()
                } else {
                    connect()
                }
            }
            .buttonStyle(.borderedProminent)

            Button(audioManager.isRecording ? "Stop" : "Start Recording") {
                if audioManager.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(.bordered)
            .disabled(!isConnected)
        }
        .padding()
    }

    func connect() {
        sessionManager.connect(apiKey: "YOUR_API_KEY_HERE") {
            isConnected = true
            startRecording()
        }
    }

    func disconnect() {
        stopRecording()
        sessionManager.disconnect()
        isConnected = false
    }

    func startRecording() {
        audioManager.startRecording { audioData in
            sessionManager.sendAudio(audioData)
        }
    }

    func stopRecording() {
        audioManager.stopRecording()
    }
}

// MARK: - Session Manager
class SessionManager: NSObject, ObservableObject {
    private var session: LiveModelSession?
    private var liveModel: LiveModel?

    func connect(apiKey: String, onComplete: @escaping () -> Void) {
        Task {
            let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

            liveModel = firebaseAI.liveModel(
                modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
                generationConfig: LiveGenerationConfig(
                    responseModalities: [.audio],
                    inputAudioTranscription: AudioTranscriptionConfig(),
                    outputAudioTranscription: AudioTranscriptionConfig()
                )
            )

            session = try await liveModel?.connect()

            await MainActor.run { onComplete() }

            // Receive loop
            for try await message in session!.responses {
                await handle(message)
            }
        }
    }

    func sendAudio(_ data: Data) {
        Task {
            try? await session?.sendAudioRealtime(data)
        }
    }

    func disconnect() {
        Task {
            try? await session?.close()
            session = nil
        }
    }

    private func handle(_ message: LiveModelMessage) async {
        switch message.payload {
        case .content(let content):
            if let inputText = content.inputAudioTranscription?.text {
                print("Input: \(inputText)")
            }
            if let outputText = content.outputAudioTranscription?.text {
                print("Output: \(outputText)")
            }
            if let modelTurn = content.modelTurn {
                for part in modelTurn.parts {
                    if let audioPart = part as? InlineDataPart,
                       audioPart.mimeType.starts(with: "audio/") {
                        // Play audio
                        await playAudio(audioPart.data)
                    }
                }
            }
        default:
            break
        }
    }

    private func playAudio(_ data: Data) async {
        // Implement audio playback
    }
}

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var converter: AVAudioConverter?

    @Published var isRecording = false
    var onAudioData: ((Data) -> Void)?

    // 24kHz 16-bit PCM mono format for Gemini Live
    private let targetFormat: AVAudioFormat = {
        var streamDesc = AudioStreamBasicDescription(
            mSampleRate: 24000.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        return AVAudioFormat(streamDescription: &streamDesc)!
    }()

    func startRecording(handler: @escaping (Data) -> Void) {
        onAudioData = handler

        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode

        guard let inputFormat = inputNode?.outputFormat(forBus: 0) else { return }
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        let bufferSize: AVAudioFrameCount = 8192
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            if let data = self.convertBuffer(buffer) {
                self.onAudioData?(data)
            }
        }

        try? audioEngine?.start()
        isRecording = true
    }

    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        isRecording = false
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let converter = converter else { return nil }

        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate) + 1000
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else { return nil }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error,
              let channelData = outputBuffer.int16ChannelData else { return nil }

        let frameCount = Int(outputBuffer.frameLength)
        return Data(bytes: channelData[0], count: frameCount * 2)
    }
}
```

## Key Points

1. **24kHz Format**: Both input and output must be 24kHz 16-bit PCM mono
2. **Session Management**: Always connect before sending audio
3. **Transcription**: Enable with `AudioTranscriptionConfig()`
4. **Streaming**: Use `sendAudioRealtime()` for continuous audio chunks
