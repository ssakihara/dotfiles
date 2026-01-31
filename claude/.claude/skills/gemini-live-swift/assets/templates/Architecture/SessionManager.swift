import FirebaseAILogic
import Combine

// MARK: - Session State Actor

private actor ConnectionState {
    enum State {
        case disconnected
        case connecting
        case connected
        case setupComplete
    }

    private var state: State = .disconnected

    var current: State { state }

    func transition(to newState: State) {
        state = newState
    }

    var isConnected: Bool {
        if case .setupComplete = state { return true }
        return false
    }
}

// MARK: - Session Manager

@MainActor
final class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Callbacks
    var onAudioReceived: ((Data) -> Void)?
    var onTranscription: ((VoiceMessage) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?

    // MARK: - Private Properties
    private var session: LiveModelSession?
    private var liveModel: LiveModel?
    private var state = ConnectionState()
    private var configuration: SessionConfiguration?

    // MARK: - Connection

    func connect(with configuration: SessionConfiguration) async throws {
        self.configuration = configuration

        let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

        liveModel = firebaseAI.liveModel(
            modelName: configuration.modelName,
            generationConfig: configuration.liveGenerationConfig
        )

        state.transition(to: .connecting)
        connectionState = .connecting

        session = try await liveModel?.connect()

        state.transition(to: .connected)
        connectionState = .connected
        onConnected?()

        // Start receive loop
        Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func disconnect() {
        Task {
            try? await session?.close()
            session = nil
            liveModel = nil
            state.transition(to: .disconnected)
            connectionState = .disconnected
            onDisconnected?(nil)
        }
    }

    func reconnect() async throws {
        guard let configuration = configuration else { return }
        disconnect()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        try await connect(with: configuration)
    }

    // MARK: - Sending

    func sendAudio(_ data: Data) {
        Task {
            guard state.isConnected else { return }
            try? await session?.sendAudioRealtime(data)
        }
    }

    func sendText(_ text: String) {
        Task {
            guard state.isConnected else { return }
            try? await session?.sendTextRealtime(text)
        }
    }

    func sendAudioEnd() {
        Task {
            guard state.isConnected else { return }
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
            connectionState = .error(error.localizedDescription)
            onDisconnected?(error)
        }
    }

    private func handleMessage(_ message: LiveModelMessage) async {
        switch message.payload {
        case .setupComplete:
            state.transition(to: .setupComplete)
            connectionState = .setupComplete

        case .content(let content):
            await handleContent(content)

        @unknown default:
            break
        }
    }

    private func handleContent(_ content: LiveContent) async {
        // Handle transcription
        if let input = content.inputAudioTranscription?.text {
            onTranscription?(.user(input))
        }
        if let output = content.outputAudioTranscription?.text {
            onTranscription?(.assistant(output))
        }

        // Handle audio
        guard let modelTurn = content.modelTurn else { return }

        for part in modelTurn.parts {
            if let audioPart = part as? InlineDataPart,
               audioPart.mimeType.starts(with: "audio/") {
                onAudioReceived?(audioPart.data)
            }
        }
    }
}
