import SwiftUI
import FirebaseAILogic
import AVFoundation

// MARK: - Main View

struct BasicVoiceChatView: View {
    @StateObject private var viewModel = BasicVoiceChatViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // Status
            HStack {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(viewModel.isConnected ? "Connected" : "Disconnected")
            }

            // Transcripts
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.inputTranscript.isEmpty {
                        HStack {
                            Text("You:")
                                .foregroundStyle(.secondary)
                            Text(viewModel.inputTranscript)
                        }
                    }
                    if !viewModel.outputTranscript.isEmpty {
                        HStack {
                            Text("Gemini:")
                                .foregroundStyle(.blue)
                            Text(viewModel.outputTranscript)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Audio Level
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(viewModel.audioLevel))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)

            // Controls
            HStack(spacing: 20) {
                Button {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    Text(viewModel.isRecording ? "Stop" : "Start Recording")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isConnected)

                Button {
                    viewModel.disconnect()
                } label: {
                    Text("Disconnect")
                }
                .buttonStyle(.bordered)
            }

            // API Key Input
            if !viewModel.isConnected {
                SecureField("Google AI API Key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.connect()
                    }
            }
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
class BasicVoiceChatViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var inputTranscript = ""
    @Published var outputTranscript = ""
    @Published var apiKey = ""

    private let audioManager = BasicAudioManager()
    private var session: LiveModelSession?
    private var liveModel: LiveModel?

    func connect() {
        Task {
            do {
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

                // Receive loop
                for try await message in session!.responses {
                    await handleMessage(message)
                }
            } catch {
                print("Connection error: \(error)")
            }
        }
    }

    func disconnect() {
        stopRecording()
        Task {
            try? await session?.close()
            session = nil
            isConnected = false
            inputTranscript = ""
            outputTranscript = ""
        }
    }

    func startRecording() {
        do {
            try audioManager.startRecording { [weak self] data, level in
                Task { @MainActor in
                    self?.audioLevel = level
                }
                self?.sendAudio(data)
            }
            isRecording = true
        } catch {
            print("Recording error: \(error)")
        }
    }

    func stopRecording() {
        audioManager.stopRecording()
        isRecording = false
        audioLevel = 0
        Task {
            try? await session?.sendAudioEnd()
        }
    }

    private func sendAudio(_ data: Data) {
        Task {
            try? await session?.sendAudioRealtime(data)
        }
    }

    private func handleMessage(_ message: LiveModelMessage) async {
        switch message.payload {
        case .content(let content):
            if let input = content.inputAudioTranscription?.text {
                inputTranscript = input
            }
            if let output = content.outputAudioTranscription?.text {
                outputTranscript = output
            }
            if let modelTurn = content.modelTurn {
                for part in modelTurn.parts {
                    if let audioPart = part as? InlineDataPart,
                       audioPart.mimeType.starts(with: "audio/") {
                        // Play audio if needed
                        // audioManager.play(audioPart.data)
                    }
                }
            }
        default:
            break
        }
    }
}

// MARK: - Audio Manager

class BasicAudioManager: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var converter: AVAudioConverter?

    // 24kHz 16-bit PCM mono
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

    var onAudioData: ((Data, Float) -> Void)?

    func startRecording(handler: @escaping (Data, Float) -> Void) throws {
        onAudioData = handler

        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode

        guard let inputFormat = inputNode?.outputFormat(forBus: 0) else {
            throw NSError(domain: "AudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No input format"])
        }

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        let bufferSize: AVAudioFrameCount = 8192
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let level = self.calculateLevel(buffer)
            if let data = self.convertBuffer(buffer) {
                self.onAudioData?(data, level)
            }
        }

        try audioEngine?.start()
    }

    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        onAudioData = nil
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

    private func calculateLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) {
            sum += abs(channelData[i])
        }
        return min(sum / Float(buffer.frameLength) * 10, 1.0)
    }
}

// MARK: - Preview

#Preview {
    BasicVoiceChatView()
}
