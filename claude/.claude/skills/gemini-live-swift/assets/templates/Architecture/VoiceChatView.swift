import SwiftUI

// MARK: - Voice Chat View

struct VoiceChatView: View {
    @StateObject private var viewModel = VoiceChatViewModel()
    @State private var showSettings = false
    @State private var configuration = SessionConfiguration(
        apiKey: "",
        modelName: "gemini-2.5-flash-native-audio-preview-12-2025",
        voiceName: "Puck",
        enableTranscription: true
    )

    var body: some View {
        VStack(spacing: 20) {
            // Header
            header

            // Messages
            messagesView

            // Audio Level
            audioLevelView

            // Controls
            controlButtons

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showSettings) {
            SettingsView(configuration: $configuration) {
                viewModel.setConfiguration(configuration)
                viewModel.connect()
            }
        }
        .onAppear {
            viewModel.setupBindings()
        }
    }

    private var header: some View {
        HStack {
            statusIndicator

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
            }
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(viewModel.connectionState.displayText)
                .font(.subheadline)
        }
    }

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .disconnected:
            return .red
        case .connecting:
            return .orange
        case .connected, .setupComplete:
            return .green
        case .error:
            return .red
        }
    }

    private var messagesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 250)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var audioLevelView: some View {
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
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.toggleRecording()
            } label: {
                Label(
                    viewModel.isRecording ? "Stop" : "Start Recording",
                    systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.connectionState.isConnected)

            Button {
                viewModel.clearMessages()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)

            if viewModel.connectionState.isConnected {
                Button {
                    viewModel.disconnect()
                } label: {
                    Text("Disconnect")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: VoiceMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer(minLength: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(roleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundStyle(textColor)
                    .cornerRadius(16)
            }
            .frame(maxWidth: 250, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 60)
            }
        }
    }

    private var roleText: String {
        message.role == .user ? "You" : "Gemini"
    }

    private var bubbleColor: Color {
        message.role == .user ? Color.blue : Color(.systemGray5)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var configuration: SessionConfiguration
    let onConnect: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("API Configuration") {
                    SecureField("Google AI API Key", text: $configuration.apiKey)

                    Picker("Model", selection: $configuration.modelName) {
                        Text("Gemini 2.5 Flash (Dec 2025)").tag("gemini-2.5-flash-native-audio-preview-12-2025")
                        Text("Gemini 2.5 Flash (Sep 2025)").tag("gemini-2.5-flash-native-audio-preview-09-2025")
                    }
                }

                Section("Voice") {
                    Picker("Voice", selection: $configuration.voiceName) {
                        Text("Puck (Default)").tag("Puck")
                        Text("Leda").tag("Leda")
                        Text("Zephyr").tag("Zephyr")
                        Text("Kore").tag("Kore")
                        Text("Orus").tag("Orus")
                    }
                }

                Section("Options") {
                    Toggle("Enable Transcription", isOn: $configuration.enableTranscription)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        onConnect()
                        dismiss()
                    }
                    .disabled(configuration.apiKey.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceChatView()
}
