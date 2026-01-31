# Session Management

Robust connection handling for production apps.

## Connection States

```
[Disconnected] → [Connecting] → [Connected] → [Setup Complete]
       ↓              ↓              ↓
   [Error] ←──── [Error] ←──── [Error]
       ↓
   [Disconnected]
```

## Basic Session Management

### Simple Connect/Disconnect

```swift
class BasicSessionManager {
    private var session: LiveModelSession?
    private var liveModel: LiveModel?

    func connect(apiKey: String) async throws {
        let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())
        liveModel = firebaseAI.liveModel(
            modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
            generationConfig: LiveGenerationConfig(
                responseModalities: [.audio]
            )
        )
        session = try await liveModel?.connect()
    }

    func disconnect() {
        Task {
            try? await session?.close()
            session = nil
        }
    }
}
```

## Robust Session Management

### State Tracking Actor

Thread-safe state management:

```swift
private actor SessionState {
    enum State {
        case disconnected
        case connecting
        case connected
        case setupComplete
        case error(Error)
    }

    private var state: State = .disconnected

    var currentState: State { state }

    func transition(to newState: State) -> State {
        state = newState
        return state
    }

    var isConnected: Bool {
        if case .connected = state, case .setupComplete = state {
            return true
        }
        return false
    }
}
```

### Reconnection Logic

Exponential backoff reconnection:

```swift
@MainActor
final class RobustSessionManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionState: String = "Disconnected"

    private var session: LiveModelSession?
    private var liveModel: LiveModel?
    private var state = SessionState()
    private var reconnectTask: Task<Void, Never>?
    private var apiKey: String?

    // Reconnection configuration
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0  // Start at 1 second
    private let maxReconnectDelay: TimeInterval = 32.0   // Max 32 seconds

    func connect(apiKey: String) async throws {
        self.apiKey = apiKey
        reconnectAttempts = 0

        let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

        liveModel = firebaseAI.liveModel(
            modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
            generationConfig: LiveGenerationConfig(
                responseModalities: [.audio],
                inputAudioTranscription: AudioTranscriptionConfig(),
                outputAudioTranscription: AudioTranscriptionConfig()
            )
        )

        _ = await state.transition(to: .connecting)
        connectionState = "Connecting..."

        session = try await liveModel?.connect()

        _ = await state.transition(to: .connected)
        connectionState = "Connected"

        isConnected = true

        // Start receive loop
        Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0

        Task {
            try? await session?.close()
            session = nil
            liveModel = nil
            _ = await state.transition(to: .disconnected)

            await MainActor.run {
                isConnected = false
                connectionState = "Disconnected"
            }
        }
    }

    func reconnect() async throws {
        guard let apiKey = apiKey else { return }

        disconnect()

        let delay = calculateReconnectDelay()
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        reconnectAttempts += 1
        try await connect(apiKey: apiKey)
    }

    private func calculateReconnectDelay() -> TimeInterval {
        let exponentialDelay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts))
        return min(exponentialDelay, maxReconnectDelay)
    }

    private func receiveLoop() async {
        do {
            guard let session = session else { return }

            for try await message in session.responses {
                switch message.payload {
                case .setupComplete:
                    _ = await state.transition(to: .setupComplete)
                    await MainActor.run {
                        connectionState = "Setup Complete"
                    }
                case .content(let content):
                    await handleContent(content)
                @unknown default:
                    break
                }
            }
        } catch {
            _ = await state.transition(to: .error(error))

            await MainActor.run {
                isConnected = false
                connectionState = "Error: \(error.localizedDescription)"
            }

            // Attempt reconnection
            if reconnectAttempts < maxReconnectAttempts {
                reconnectTask = Task {
                    do {
                        try await reconnect()
                    } catch {
                        await MainActor.run {
                            connectionState = "Reconnection failed"
                        }
                    }
                }
            }
        }
    }

    private func handleContent(_ content: LiveContent) async {
        // Handle content (audio, transcription, etc.)
    }
}
```

## Session Lifecycle

### Initialization

```swift
func initializeSession(apiKey: String) async throws {
    // 1. Create Firebase AI instance
    let firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

    // 2. Configure LiveModel
    liveModel = firebaseAI.liveModel(
        modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
        generationConfig: config
    )

    // 3. Connect to session
    session = try await liveModel?.connect()

    // 4. Wait for setup complete
    for try await message in session!.responses {
        if case .setupComplete = message.payload {
            break
        }
    }
}
```

### Graceful Shutdown

```swift
func shutdownSession() async {
    // 1. Stop audio recording
    audioManager.stopRecording()

    // 2. Signal end of audio input
    try? await session?.sendAudioEnd()

    // 3. Wait for final response (optional timeout)
    try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

    // 4. Close session
    try? await session?.close()

    // 5. Cleanup
    session = nil
    liveModel = nil
}
```

## Error Handling

### Connection Errors

```swift
enum SessionError: LocalizedError {
    case notConnected
    case connectionFailed(Error)
    case sessionExpired
    case rateLimited
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Session not connected"
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .sessionExpired:
            return "Session expired (15 minute limit)"
        case .rateLimited:
            return "Rate limit exceeded"
        case .invalidAPIKey:
            return "Invalid API key"
        }
    }
}
```

### Retry Strategy

```swift
func withRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
    var attempts = 0
    let maxAttempts = 3

    while attempts < maxAttempts {
        do {
            return try await operation()
        } catch {
            attempts += 1

            if attempts >= maxAttempts {
                throw error
            }

            // Don't retry on certain errors
            if let sessionError = error as? SessionError {
                switch sessionError {
                case .invalidAPIKey, .rateLimited:
                    throw error  // Don't retry
                default:
                    break
                }
            }

            // Exponential backoff
            let delay = pow(2.0, Double(attempts))
            try await Task.sleep(nanoseconds: UInt64(delay * 500_000_000))  // ms to ns
        }
    }

    fatalError("Unreachable")
}
```

## Session Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Max Duration | 15 minutes | Per session |
| Free Tier Requests | 15/day | Google AI API |
| Rate Limit | Varies | Based on model |

Handling session expiration:

```swift
private func receiveLoop() async {
    let startTime = Date()
    let maxDuration: TimeInterval = 15 * 60  // 15 minutes

    do {
        for try await message in session!.responses {
            // Check session duration
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= maxDuration {
                await handleSessionExpired()
                break
            }

            await handleMessage(message)
        }
    } catch {
        await handleError(error)
    }
}

private func handleSessionExpired() async {
    // Notify user
    // Optionally reconnect automatically
    disconnect()

    await MainActor.run {
        showSessionExpiredAlert = true
    }
}
```

## Testing Connection

```swift
func testConnection() async -> Bool {
    do {
        try await connect(apiKey: testApiKey)

        // Send test text
        try await session?.sendTextRealtime("Hello")

        // Wait for response
        for try await message in session!.responses {
            if case .content = message.payload {
                try? await session?.close()
                return true
            }
        }
    } catch {
        return false
    }

    return false
}
```
