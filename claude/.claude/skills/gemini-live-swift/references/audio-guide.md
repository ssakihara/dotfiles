# Audio Format Guide

Critical audio format requirements for Gemini Live API.

## Format Requirements

| Parameter | Value | Notes |
|-----------|-------|-------|
| Sample Rate | 24000 Hz | Both input and output |
| Bit Depth | 16-bit | Signed integer |
| Channels | 1 (Mono) | Stereo not supported |
| Encoding | PCM | Linear PCM |

## Why 24kHz?

Gemini Live API's native audio models are optimized for 24kHz:
- Matches model's training data format
- Balances quality and bandwidth
- Reduces latency vs 48kHz
- Standard for voice AI applications

## Recording Implementation

### AudioFormat Definition

```swift
let targetFormat: AVAudioFormat = {
    var streamDesc = AudioStreamBasicDescription(
        mSampleRate: 24000.0,              // 24kHz
        mFormatID: kAudioFormatLinearPCM,   // PCM
        mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
        mBytesPerPacket: 2,
        mFramesPerPacket: 1,
        mBytesPerFrame: 2,
        mChannelsPerFrame: 1,               // Mono
        mBitsPerChannel: 16,
        mReserved: 0
    )
    return AVAudioFormat(streamDescription: &streamDesc)!
}()
```

### Sample Rate Conversion

Most devices record at 48kHz. You must convert:

```swift
// Get device input format (typically 48kHz)
let inputFormat = inputNode.outputFormat(forBus: 0)

// Create converter
let converter = AVAudioConverter(from: inputFormat, to: targetFormat)

// Convert in the tap handler
inputNode.installTap(onBus: 0, bufferSize: 8192, format: inputFormat) { buffer, _ in
    // Convert to 24kHz
    let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: ...)

    converter.convert(to: outputBuffer) { _, _ in
        outStatus.pointee = .haveData
        return buffer
    }

    // Extract PCM data
    let data = Data(bytes: outputBuffer.int16ChannelData[0], count: ...)
}
```

## Buffer Size Guidelines

| Use Case | Buffer Size | Latency |
|----------|-------------|---------|
| Real-time conversation | 8192 frames | ~170ms @ 48kHz |
| Lower latency | 4096 frames | ~85ms @ 48kHz |
| Recording (non-interactive) | 16384 frames | ~340ms @ 48kHz |

**Recommendation**: 8192 frames for voice chat (balance quality and latency).

## Playback Implementation

### Create Playback Engine

```swift
playerNode = AVAudioPlayerNode()
playbackEngine = AVAudioEngine()

playbackEngine.attach(playerNode)
playbackEngine.connect(playerNode, to: playbackEngine.outputNode, format: targetFormat)

try playbackEngine.start()
```

### Play 24kHz PCM Data

```swift
func playAudio(_ data: Data) {
    let frameCount = data.count / 2  // 16-bit = 2 bytes per frame

    guard let buffer = AVAudioPCMBuffer(
        pcmFormat: targetFormat,
        frameCapacity: AVAudioFrameCount(frameCount)
    ) else { return }

    buffer.frameLength = AVAudioFrameCount(frameCount)

    // Copy 16-bit PCM data into buffer
    data.withUnsafeBytes { ptr in
        let src = ptr.baseAddress?.assumingMemoryBound(to: Int16.self)
        memcpy(buffer.int16ChannelData[0], src, data.count)
    }

    playerNode.scheduleBuffer(buffer) {
        // Playback complete
    }

    if !playerNode.isPlaying {
        playerNode.play()
    }
}
```

## Audio Session Configuration

### iOS

```swift
import AVFoundation

func configureAudioSession() throws {
    let session = AVAudioSession.sharedInstance()

    try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth]
    )

    try session.setActive(true)
}
```

### macOS

No AVAudioSession needed - system handles routing automatically.

## Common Issues

### Issue: Audio Sounds Distorted/Crackling

**Cause**: Incorrect bit depth or channel interpretation.

**Fix**: Ensure 16-bit signed integer format:
```swift
mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
```

### Issue: Audio Plays at Wrong Speed/Pitch

**Cause**: Sample rate mismatch.

**Fix**: Always convert to 24kHz before sending to API.

### Issue: No Sound on Playback

**Cause**: Audio session not active (iOS) or format mismatch.

**Fix**:
```swift
try AVAudioSession.sharedInstance().setActive(true)
// Ensure playback engine is started
```

### Issue: Echo/Feedback

**Cause**: Microphone picking up speaker output.

**Fixes**:
- Use headphones
- Enable echo cancellation (AVAudioSession mode .voiceChat)
- Reduce speaker volume

## Bandwidth Calculation

24kHz 16-bit mono = 48,000 bits per second ≈ 6 KB/s

For 15-minute session: 6 KB/s × 900 s = 5.4 MB per direction

## Testing Audio Pipeline

```swift
// Test recording to file
func testRecording() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.pcm")

    audioManager.onAudioData = { data in
        try? data.append(to: url)
    }

    // Record for 5 seconds, then verify file size
    // Expected: 6 KB/s × 5 = 30 KB
}

// Test playback from file
func testPlayback() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.pcm")
    guard let data = try? Data(contentsOf: url) else { return }

    audioManager.playAudio(data)
}
```
