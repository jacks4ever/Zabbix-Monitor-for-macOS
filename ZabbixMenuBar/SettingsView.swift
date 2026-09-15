import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some View {
        TabView {
            ConnectionSettingsView()
                .environmentObject(client)
                .tabItem {
                    Label("tab.connection", systemImage: "network")
                }

            FiltersSettingsView()
                .environmentObject(client)
                .tabItem {
                    Label("tab.filters", systemImage: "line.3.horizontal.decrease.circle")
                }

            SecuritySettingsView()
                .environmentObject(client)
                .tabItem {
                    Label("tab.security", systemImage: "lock.shield")
                }

            AISettingsView()
                .environmentObject(client)
                .tabItem {
                    Label("tab.ai", systemImage: "brain")
                }

            LanguageSettingsView()
                .environmentObject(client)
                .tabItem {
                    Label("tab.language", systemImage: "globe")
                }

            AboutView()
                .tabItem {
                    Label("tab.about", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 520)
        .environment(\.locale, languageManager.effectiveLocale)
        .onAppear {
            // Make settings window appear on top of other windows
            if let window = NSApp.windows.first(where: { $0.title.contains("Settings") || $0.identifier?.rawValue.contains("Settings") == true }) {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }
}

// MARK: - Glass Card Container

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Custom Toggle Style (workaround for macOS tint bug)

struct ColoredToggleStyle: ToggleStyle {
    var onColor: Color = .blue
    var offColor: Color = Color(nsColor: .separatorColor)

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 44, height: 24)

                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    .frame(width: 20, height: 20)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let titleKey: LocalizedStringKey
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(titleKey)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

// MARK: - Connection Settings

struct ConnectionSettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 16) {
            // Server Configuration
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(titleKey: "section.server", icon: "server.rack")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("label.serverUrl")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("https://your-zabbix-server/api_jsonrpc.php", text: $client.serverURL)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(8)
                            .frame(height: 36)
                            .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("label.username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField(String(localized: "label.username"), text: $client.username)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(8)
                            .frame(height: 36)
                            .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }
                }
            }

            // Preferences
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(titleKey: "section.preferences", icon: "gearshape")

                    HStack {
                        Text("label.refreshInterval")
                        Spacer()
                        Picker("", selection: $client.refreshInterval) {
                            Text("interval.5seconds").tag(5.0)
                            Text("interval.10seconds").tag(10.0)
                            Text("interval.15seconds").tag(15.0)
                            Text("interval.30seconds").tag(30.0)
                            Text("interval.1minute").tag(60.0)
                            Text("interval.5minutes").tag(300.0)
                            Text("interval.manualOnly").tag(0.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }

                    Divider().opacity(0.5)

                    HStack {
                        Text("label.sortProblemsBy")
                        Spacer()
                        Picker("", selection: $client.problemSortOrder) {
                            ForEach(ProblemSortOrder.allCases, id: \.self) { order in
                                Text(order.localizedName).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }
            }

            // Test Connection
            GlassCard {
                HStack {
                    if let result = testResult {
                        HStack(spacing: 6) {
                            Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testSuccess ? .green : .red)
                            Text(result)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    Spacer()

                    Button {
                        isTesting = true
                        Task {
                            let result = await client.testConnection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                testSuccess = result.success
                                testResult = result.message
                            }
                            isTesting = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("button.testConnection")
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(isTesting)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Filters Settings

struct FiltersSettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient

    var body: some View {
        VStack(spacing: 16) {
            // Menu Bar Severity Filters
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(titleKey: "section.menuBarSeverity", icon: "menubar.rectangle")

                    HStack(spacing: 8) {
                        SeverityToggle(labelKey: "severity.disaster", color: .purple, isOn: $client.severityFilter.disaster)
                        SeverityToggle(labelKey: "severity.high", color: .red, isOn: $client.severityFilter.high)
                        SeverityToggle(labelKey: "severity.average", color: .orange, isOn: $client.severityFilter.average)
                    }
                    HStack(spacing: 8) {
                        SeverityToggle(labelKey: "severity.warning", color: .yellow, isOn: $client.severityFilter.warning)
                        SeverityToggle(labelKey: "severity.info", color: .blue, isOn: $client.severityFilter.information)
                        SeverityToggle(labelKey: "severity.notClassified", color: .gray, isOn: $client.severityFilter.notClassified)
                    }
                }
            }

            // Widget Severity Filters
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(titleKey: "section.widgetSeverity", icon: "widget.small")

                    HStack(spacing: 8) {
                        SeverityToggle(labelKey: "severity.disaster", color: .purple, isOn: $client.widgetSeverityFilter.disaster)
                        SeverityToggle(labelKey: "severity.high", color: .red, isOn: $client.widgetSeverityFilter.high)
                        SeverityToggle(labelKey: "severity.average", color: .orange, isOn: $client.widgetSeverityFilter.average)
                    }
                    HStack(spacing: 8) {
                        SeverityToggle(labelKey: "severity.warning", color: .yellow, isOn: $client.widgetSeverityFilter.warning)
                        SeverityToggle(labelKey: "severity.info", color: .blue, isOn: $client.widgetSeverityFilter.information)
                        SeverityToggle(labelKey: "severity.notClassified", color: .gray, isOn: $client.widgetSeverityFilter.notClassified)
                    }
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Severity Toggle

struct SeverityToggle: View {
    let labelKey: LocalizedStringKey
    let color: Color
    @Binding var isOn: Bool
    @State private var isHovering = false

    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() } }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 10, height: 10)
                    .shadow(color: color.opacity(0.4), radius: isOn ? 4 : 0)
                Text(labelKey)
                    .font(.subheadline)
                Spacer()
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundColor(isOn ? .accentColor : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? .white.opacity(0.08) : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // SSL Settings
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(titleKey: "section.sslCertificate", icon: "lock")

                        Toggle(isOn: $client.allowSelfSignedCerts) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("toggle.allowSelfSigned")
                                    .font(.body)
                                Text("toggle.allowSelfSignedDescription")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(ColoredToggleStyle(onColor: .blue))
                    }
                }

                // Authentication Status
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(titleKey: "section.authentication", icon: "person.badge.key")

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(client.isAuthenticated ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: client.isAuthenticated ? "checkmark.shield.fill" : "xmark.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(client.isAuthenticated ? .green : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.isAuthenticated ? "status.authenticated" : "status.notAuthenticated")
                                    .font(.headline)
                                    .foregroundColor(client.isAuthenticated ? .primary : .secondary)
                                Text(client.isAuthenticated ? "status.credentialsStored" : "status.connectToAuthenticate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        if client.isAuthenticated {
                            Divider().opacity(0.5)

                            Button(role: .destructive) {
                                client.logout()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("button.clearCredentials")
                                }
                                .font(.subheadline.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
        }
    }
}

// MARK: - AI Settings

struct AISettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isTesting = false
    @State private var customPromptText = ""

    /// Custom binding that defers writes to avoid "Publishing changes from within view updates"
    private var aiProviderBinding: Binding<AIProvider> {
        Binding(
            get: { client.aiProvider },
            set: { newValue in
                // Defer the write to next run loop to avoid publishing during view update
                DispatchQueue.main.async {
                    client.aiProvider = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            // Provider Selection
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(titleKey: "section.aiProvider", icon: "brain")

                    Picker("", selection: aiProviderBinding) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            Text(provider.localizedName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if client.aiProvider == .disabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                Text("ai.disabledMessage")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("label.widgetProblemCount")
                                    .font(.caption)
                                Spacer()
                                Picker("", selection: $client.widgetProblemCount) {
                                    Text("3").tag(3)
                                    Text("4").tag(4)
                                    Text("5").tag(5)
                                    Text("6").tag(6)
                                    Text("7").tag(7)
                                    Text("8").tag(8)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 60)
                            }
                        }
                        .padding(8)
                        .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Provider Settings
            if client.aiProvider == .ollama {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(titleKey: "section.ollamaConfig", icon: "server.rack")

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.serverUrl")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("http://localhost:11434", text: $client.ollamaURL)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.model")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("mistral:7b", text: $client.ollamaModel)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }
                            .frame(width: 120)
                        }
                    }
                }
            }

            if client.aiProvider == .openai {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(titleKey: "section.openaiConfig", icon: "key")

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.apiKey")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                SecureField("sk-...", text: $client.openAIAPIKey)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.model")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("gpt-4o-mini", text: $client.openAIModel)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }
                            .frame(width: 120)
                        }
                    }
                }
            }

            if client.aiProvider == .anthropic {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(titleKey: "section.anthropicConfig", icon: "key")

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.apiKey")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                SecureField("sk-ant-...", text: $client.anthropicAPIKey)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("label.model")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("claude-3-5-haiku-latest", text: $client.anthropicModel)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                    .padding(6)
                                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }
                            .frame(width: 160)
                        }
                    }
                }
            }

            // Custom Prompt
            if client.aiProvider != .disabled {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionHeader(titleKey: "section.customPrompt", icon: "text.bubble")
                            Spacer()
                            Button {
                                let defaultPrompt = ZabbixAPIClient.defaultAIPrompt
                                customPromptText = defaultPrompt
                                client.customAIPrompt = defaultPrompt
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("button.resetToDefault")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        TextEditor(text: $customPromptText)
                            .font(.system(.caption2, design: .monospaced))
                            .frame(height: 80)
                            .padding(4)
                            .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                            .onChange(of: customPromptText) { _, newValue in
                                // Defer the write to avoid cursor position issues
                                DispatchQueue.main.async {
                                    client.customAIPrompt = newValue
                                }
                            }
                            .onAppear {
                                // Initialize local state from client
                                customPromptText = client.customAIPrompt
                            }

                        HStack(spacing: 6) {
                            Text("label.availablePlaceholders")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(verbatim: "{PROBLEM_LIST}")
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            Text(verbatim: "{SEVERITY_COUNTS}")
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            Text(verbatim: "{PROBLEM_COUNT}")
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            // Test AI
            if client.aiProvider != .disabled {
                GlassCard {
                    HStack {
                        if let result = testResult {
                            HStack(spacing: 6) {
                                Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(testSuccess ? .green : .red)
                                Text(result)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        Spacer()

                        Button {
                            isTesting = true
                            Task {
                                let result = await client.testAIProvider()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    testSuccess = result.success
                                    testResult = result.message
                                }
                                isTesting = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isTesting {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("button.testAI")
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(isTesting)
                    }
                }
            }
        }
        .padding(20)
        .onChange(of: client.aiProvider) { _, _ in
            testResult = nil
        }
    }
}

// MARK: - Language Settings

struct LanguageSettingsView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(titleKey: "section.appLanguage", icon: "globe")

                    ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                        LanguageRow(
                            language: language,
                            isSelected: languageManager.selectedLanguage == language
                        ) {
                            languageManager.selectedLanguage = language
                            // Update AI prompt to new language if it's still a default prompt
                            client.updatePromptForLanguageChange()
                        }
                    }
                }
            }

            GlassCard {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("language.followsSystemSettings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.displayName)
                    .font(.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? .white.opacity(0.08) : (isSelected ? .accentColor.opacity(0.1) : .clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Icon and Title
            VStack(spacing: 12) {
                ZabbixIconView(size: 80, glyph: .filled(.white))

                Text("about.title")
                    .font(.title)
                    .fontWeight(.bold)

                Text("about.version")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 24)

            // Features
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("about.features")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        FeatureRow(icon: "bell.fill", textKey: "feature.realTimeMonitoring")
                        FeatureRow(icon: "server.rack", textKey: "feature.hostOverview")
                        FeatureRow(icon: "brain", textKey: "feature.aiSummaries")
                        FeatureRow(icon: "square.grid.2x2", textKey: "feature.desktopWidget")
                        FeatureRow(icon: "slider.horizontal.3", textKey: "feature.severityFilters")
                        FeatureRow(icon: "checkmark.circle", textKey: "feature.acknowledge")
                        FeatureRow(icon: "lock.shield", textKey: "feature.secureStorage")
                        FeatureRow(icon: "arrow.clockwise", textKey: "feature.autoRefresh")
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Text("about.madeWith")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let textKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(textKey)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ZabbixAPIClient())
}
