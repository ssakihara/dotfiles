# Production-Ready Architecture

Layered architecture for scalable, maintainable Gemini Live implementations.

## Directory Structure

```
Sources/
├── Models/
│   ├── LiveModels.swift        # LiveContent, LiveModelMessage wrappers
│   └── TranscriptionModels.swift
├── Services/
│   ├── AudioManager.swift      # AVAudioEngine recording/playback
│   ├── SessionManager.swift    # LiveModel session management
│   └── TranscriptionService.swift
├── ViewModels/
│   └── VoiceChatViewModel.swift
└── Views/
    └── VoiceChatView.swift
```

## AudioManager

Handles 24kHz PCM audio recording and playback.

```swift
import AVFoundation
import Combine

final class AudioManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var audioLevel: Float = 0.0

    // MARK: - Callbacks
    var onAudioData: ((Data) -> Void)?

    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var playerNode: AVAudioPlayerNode?
    private var playbackEngine: AVAudioEngine?
    private var converter: AVAudioConverter?

    // 24kHz 16-bit PCM mono for Gemini Live API
    private let targetFormat: AVAudioFormat = {
        var desc = AudioStreamBasicDescription(
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
        return AVAudioFormat(streamDescription: &desc)!
    }()

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else { return }

        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode

        guard let inputFormat = inputNode?.outputFormat(forBus: 0) else {
            throw AudioManagerError.inputFormatUnavailable
        }

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        let bufferSize: AVAudioFrameCount = 8192
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        try audioEngine?.start()
        isRecording = true
    }

    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        isRecording = false
        audioLevel = 0.0
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Calculate audio level
        audioLevel = calculateLevel(buffer)

        // Convert to 24kHz PCM
        guard let data = convertBufferToPCM(buffer) else { return }
        onAudioData?(data)
    }

    // MARK: - Playback

    func playAudio(_ data: Data) {
        if playerNode == nil {
            setupPlaybackEngine()
        }

        guard let buffer = dataToPCMBuffer(data),
              let playerNode = playerNode else { return }

        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            self.isPlaying = false
        }

        if playerNode.isPlaying == false {
            playerNode.play()
            isPlaying = true
        }
    }

    func stopPlayback() {
        playerNode?.stop()
        playbackEngine?.stop()
        playerNode = nil
        playbackEngine = nil
        isPlaying = false
    }

    // MARK: - Conversion

    private func convertBufferToPCM(_ buffer: AVAudioPCMBuffer) -> Data? {
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

    private func dataToPCMBuffer(_ data: Data) -> AVAudioPCMBuffer? {
        let frameCount = data.count / 2
        guard let buffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        guard let channelData = buffer.int16ChannelData else { return nil }

        data.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress?.assumingMemoryBound(to: Int16.self) {
                memcpy(channelData[0], base, data.count)
            }
        }

        return buffer
    }

    private func calculateLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) {
            sum += abs(channelData[i])
        }
        return min(sum / Float(buffer.frameLength) * 10, 1.0)
    }

    private func setupPlaybackEngine() {
        playerNode = AVAudioPlayerNode()
        playbackEngine = AVAudioEngine()

        playbackEngine?.attach(playerNode!)
        playbackEngine?.connect(playerNode!, to: playbackEngine!.outputNode, format: targetFormat)

        try? playbackEngine?.start()
    }
}

enum AudioManagerError: LocalizedError {
    case inputFormatUnavailable
    case conversionFailed
}
```

## SessionManager

Manages LiveModel connection with reconnection logic.

```swift
import FirebaseAILogic

@MainActor
final class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionError: Error?
    @Published var inputTranscript = ""
    @Published var outputTranscript = ""

    // MARK: - Callbacks
    var onAudioReceived: ((Data) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?

    // MARK: - Private Properties
    private var session: LiveModelSession?
    private var liveModel: LiveModel?
    private var apiKey: String?
    private var connectionState = ConnectionState()

    // MARK: - Connection

    func connect(apiKey: String) async throws {
        self.apiKey = apiKey

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
        isConnected = true
        connectionError = nil
        onConnected?()

        // Start receive loop
        Task {
            await receiveLoop()
        }
    }

    func disconnect() {
        Task {
            try? await session?.close()
            session = nil
            liveModel = nil
            isConnected = false
            onDisconnected?(nil)
        }
    }

    func reconnect() async throws {
        guard let apiKey = apiKey else { return }
        disconnect()
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        try await connect(apiKey: apiKey)
    }

    // MARK: - Sending

    func sendAudio(_ data: Data) {
        Task {
            guard isConnected else { return }
            try? await session?.sendAudioRealtime(data)
        }
    }

    func sendText(_ text: String) {
        Task {
            guard isConnected else { return }
            try? await session?.sendTextRealtime(text)
        }
    }

    func sendAudioEnd() {
        Task {
            guard isConnected else { return }
            try? await session?.sendAudioEnd()
        }
    }

    // MARK: - Receiving

    private func receiveLoop() async {
        do {
            guard let session = session else { return }

            for try await message in session.responses {
                await handleMessage(message)
            }
        } catch {
            isConnected = false
            connectionError = error
            onDisconnected?(error)
        }
    }

    private func handleMessage(_ message: LiveModelMessage) async {
        switch message.payload {
        case .content(let content):
            await handleContent(content)
        case .setupComplete:
            break
        @unknown default:
            break
        }
    }

    private func handleContent(_ content: LiveContent) async {
        // Transcription
        if let input = content.inputAudioTranscription?.text {
            inputTranscript = input
        }
        if let output = content.outputAudioTranscription?.text {
            outputTranscript = output
        }

        // Audio
        guard let modelTurn = content.modelTurn else { return }

        for part in modelTurn.parts {
            if let audioPart = part as? InlineDataPart,
               audioPart.mimeType.starts(with: "audio/") {
                onAudioReceived?(audioPart.data)
            }
        }
    }
}

// Thread-safe connection state
private actor ConnectionState {
    var isConnected = false
    var setupComplete = false

    func update(connected: Bool, setupComplete: Bool) {
        self.isConnected = connected
        self.setupComplete = setupComplete
    }
}
```

## ViewModel

Binds AudioManager and SessionManager to SwiftUI.

```swift
import Combine

@MainActor
final class VoiceChatViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var inputTranscript = ""
    @Published var outputTranscript = ""
    @Published var errorMessage: String?

    private let audioManager = AudioManager()
    private let sessionManager = SessionManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    func connect(apiKey: String) {
        Task {
            do {
                try await sessionManager.connect(apiKey: apiKey)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func disconnect() {
        stopRecording()
        sessionManager.disconnect()
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try audioManager.startRecording()
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopRecording() {
        audioManager.stopRecording()
        sessionManager.sendAudioEnd()
        isRecording = false
    }

    private func setupBindings() {
        // SessionManager bindings
        sessionManager.$isConnected
            .assign(to: &$isConnected)

        sessionManager.$inputTranscript
            .assign(to: &$inputTranscript)

        sessionManager.$outputTranscript
            .assign(to: &$outputTranscript)

        // AudioManager bindings
        audioManager.$isRecording
            .assign(to: &$isRecording)

        audioManager.$audioLevel
            .assign(to: &$audioLevel)

        // Audio pipeline: AudioManager -> SessionManager
        audioManager.onAudioData = { [weak sessionManager] data in
            sessionManager?.sendAudio(data)
        }

        // Audio pipeline: SessionManager -> AudioManager
        sessionManager.onAudioReceived = { [weak audioManager] data in
            audioManager?.playAudio(data)
        }
    }
}
```

## SwiftUI View

```swift
struct VoiceChatView: View {
    @StateObject private var viewModel = VoiceChatViewModel()
    @State private var apiKey = ""

    var body: some View {
        VStack(spacing: 24) {
            // Connection Status
            statusIndicator

            // Transcripts
            transcriptView

            // Audio Level Visualizer
            audioLevelView

            // Controls
            controlButtons
        }
        .padding()
        .sheet(isPresented: .constant(apiKey.isEmpty)) {
            APIKeyInputView(apiKey: $apiKey) {
                viewModel.connect(apiKey: apiKey)
            }
        }
    }

    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(viewModel.isConnected ? .green : .red)
                .frame(width: 12, height: 12)
            Text(viewModel.isConnected ? "Connected" : "Disconnected")
        }
    }

    private var transcriptView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !viewModel.inputTranscript.isEmpty {
                    Text("You: \(viewModel.inputTranscript)")
                        .foregroundStyle(.secondary)
                }
                if !viewModel.outputTranscript.isEmpty {
                    Text("Gemini: \(viewModel.outputTranscript)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var audioLevelView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))

                Rectangle()
                    .fill(.blue)
                    .frame(width: geometry.size.width * CGFloat(viewModel.audioLevel))
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button(viewModel.isRecording ? "Stop" : "Start Recording") {
                viewModel.toggleRecording()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isConnected)

            Button("Disconnect") {
                viewModel.disconnect()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Google AI API Key")
                .font(.headline)

            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            Button("Connect") {
                onConnect()
            }
            .buttonStyle(.borderedProminent)
            .disabled(apiKey.isEmpty)
        }
        .padding()
    }
}
```
