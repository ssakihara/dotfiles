import Combine

// MARK: - Voice Chat View Model

@MainActor
final class VoiceChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var messages: [VoiceMessage] = []
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let audioManager = AudioManager()
    private let sessionManager = SessionManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Configuration

    private var configuration: SessionConfiguration?

    func setConfiguration(_ config: SessionConfiguration) {
        self.configuration = config
    }

    // MARK: - Connection

    func connect() {
        guard let configuration = configuration else {
            errorMessage = "Configuration not set"
            return
        }

        Task {
            do {
                try await sessionManager.connect(with: configuration)
            } catch {
                errorMessage = error.localizedDescription
                connectionState = .error(error.localizedDescription)
            }
        }
    }

    func disconnect() {
        stopRecording()
        sessionManager.disconnect()
        connectionState = .disconnected
    }

    // MARK: - Recording

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
        audioLevel = 0
    }

    // MARK: - Setup

    func setupBindings() {
        // SessionManager bindings
        sessionManager.$connectionState
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)

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

        // Transcription handler
        sessionManager.onTranscription = { [weak self] message in
            self?.messages.append(message)
        }

        // Connection handlers
        sessionManager.onConnected = { [weak self] in
            self?.errorMessage = nil
        }

        sessionManager.onDisconnected = { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func clearMessages() {
        messages.removeAll()
    }
}
