import AVFoundation
import Combine

// MARK: - Audio Manager

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
        audioEngine = nil
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

// MARK: - Errors

enum AudioManagerError: LocalizedError {
    case inputFormatUnavailable
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .inputFormatUnavailable:
            return "Unable to access input audio format"
        case .conversionFailed:
            return "Audio format conversion failed"
        }
    }
}
