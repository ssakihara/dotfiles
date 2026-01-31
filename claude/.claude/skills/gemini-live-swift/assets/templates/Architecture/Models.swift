import Foundation

// MARK: - Message Models

struct VoiceMessage: Identifiable, Equatable {
    let id = UUID()
    enum Role {
        case user
        case assistant
    }
    let role: Role
    let text: String
    let timestamp = Date()

    static func user(_ text: String) -> VoiceMessage {
        VoiceMessage(role: .user, text: text)
    }

    static func assistant(_ text: String) -> VoiceMessage {
        VoiceMessage(role: .assistant, text: text)
    }
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case setupComplete
    case error(String)

    var isConnected: Bool {
        if case .connected = self, case .setupComplete = self {
            return true
        }
        return false
    }

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .setupComplete: return "Ready"
        case .error(let message): return "Error: \(message)"
        }
    }
}

// MARK: - Session Configuration

struct SessionConfiguration {
    let apiKey: String
    let modelName: String
    let voiceName: String
    let enableTranscription: Bool

    init(
        apiKey: String,
        modelName: String = "gemini-2.5-flash-native-audio-preview-12-2025",
        voiceName: String = "Puck",
        enableTranscription: Bool = true
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.voiceName = voiceName
        self.enableTranscription = enableTranscription
    }

    var liveGenerationConfig: LiveGenerationConfig {
        var config = LiveGenerationConfig(
            responseModalities: [.audio],
            speech: SpeechConfig(voiceName: voiceName)
        )

        if enableTranscription {
            config.inputAudioTranscription = AudioTranscriptionConfig()
            config.outputAudioTranscription = AudioTranscriptionConfig()
        }

        return config
    }
}
