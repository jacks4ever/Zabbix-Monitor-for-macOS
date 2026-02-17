import SwiftUI

// MARK: - Host Icon Manager

class HostIconManager: ObservableObject {
    static let shared = HostIconManager()

    private let userDefaultsKey = "customHostIcons"
    @Published private(set) var customIcons: [String: String] = [:]

    struct IconOption: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let category: String
    }

    struct IconCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        var options: [IconOption]
    }

    static let iconCategories: [IconCategory] = [
        IconCategory(name: "Appliances", icon: "refrigerator.fill", options: [
            IconOption(name: "Dishwasher", icon: "dishwasher.fill", color: .gray, category: "Appliances"),
            IconOption(name: "Dryer", icon: "dryer.fill", color: .gray, category: "Appliances"),
            IconOption(name: "Microwave", icon: "microwave.fill", color: .gray, category: "Appliances"),
            IconOption(name: "Oven", icon: "oven.fill", color: .gray, category: "Appliances"),
            IconOption(name: "Refrigerator", icon: "refrigerator.fill", color: .gray, category: "Appliances"),
            IconOption(name: "Washer", icon: "washer.fill", color: .gray, category: "Appliances"),
        ]),
        IconCategory(name: "Climate", icon: "thermometer.medium", options: [
            IconOption(name: "Air Conditioner", icon: "air.conditioner.horizontal.fill", color: .blue, category: "Climate"),
            IconOption(name: "Fan", icon: "fan.fill", color: .gray, category: "Climate"),
            IconOption(name: "Heater", icon: "heater.vertical.fill", color: .orange, category: "Climate"),
            IconOption(name: "Thermostat", icon: "thermometer.medium", color: .orange, category: "Climate"),
        ]),
        IconCategory(name: "Computers", icon: "desktopcomputer", options: [
            IconOption(name: "Desktop", icon: "desktopcomputer", color: .gray, category: "Computers"),
            IconOption(name: "Laptop", icon: "laptopcomputer", color: .gray, category: "Computers"),
        ]),
        IconCategory(name: "Entertainment", icon: "tv.fill", options: [
            IconOption(name: "Apple TV", icon: "appletv.fill", color: .purple, category: "Entertainment"),
            IconOption(name: "Game Console", icon: "gamecontroller.fill", color: .green, category: "Entertainment"),
            IconOption(name: "Speaker", icon: "hifispeaker.fill", color: .purple, category: "Entertainment"),
            IconOption(name: "TV", icon: "tv.fill", color: .purple, category: "Entertainment"),
        ]),
        IconCategory(name: "Infrastructure", icon: "server.rack", options: [
            IconOption(name: "Cloud", icon: "cloud.fill", color: .blue, category: "Infrastructure"),
            IconOption(name: "Container", icon: "shippingbox.fill", color: .indigo, category: "Infrastructure"),
            IconOption(name: "Database", icon: "cylinder.fill", color: .indigo, category: "Infrastructure"),
            IconOption(name: "Server", icon: "server.rack", color: .indigo, category: "Infrastructure"),
            IconOption(name: "Virtual Machine", icon: "cube.transparent", color: .indigo, category: "Infrastructure"),
        ]),
        IconCategory(name: "Lighting", icon: "lightbulb.fill", options: [
            IconOption(name: "Holiday/Festive", icon: "sparkles", color: .yellow, category: "Lighting"),
            IconOption(name: "Light", icon: "lightbulb.fill", color: .yellow, category: "Lighting"),
            IconOption(name: "String Lights", icon: "party.popper.fill", color: .orange, category: "Lighting"),
        ]),
        IconCategory(name: "Mobile", icon: "iphone", options: [
            IconOption(name: "Phone", icon: "iphone", color: .blue, category: "Mobile"),
            IconOption(name: "Tablet", icon: "ipad", color: .blue, category: "Mobile"),
            IconOption(name: "Watch", icon: "applewatch", color: .blue, category: "Mobile"),
        ]),
        IconCategory(name: "Networking", icon: "wifi.router.fill", options: [
            IconOption(name: "Access Point", icon: "wifi", color: .blue, category: "Networking"),
            IconOption(name: "Firewall", icon: "flame.fill", color: .orange, category: "Networking"),
            IconOption(name: "NAS", icon: "externaldrive.fill", color: .blue, category: "Networking"),
            IconOption(name: "Printer", icon: "printer.fill", color: .gray, category: "Networking"),
            IconOption(name: "Router", icon: "wifi.router.fill", color: .blue, category: "Networking"),
            IconOption(name: "Switch", icon: "rectangle.connected.to.line.below", color: .blue, category: "Networking"),
        ]),
        IconCategory(name: "Power", icon: "battery.100.bolt", options: [
            IconOption(name: "Solar", icon: "sun.max.fill", color: .mint, category: "Power"),
            IconOption(name: "UPS/Battery", icon: "battery.100.bolt", color: .mint, category: "Power"),
        ]),
        IconCategory(name: "Security", icon: "shield.fill", options: [
            IconOption(name: "Alarm", icon: "shield.fill", color: .red, category: "Security"),
            IconOption(name: "Camera", icon: "video.fill", color: .red, category: "Security"),
            IconOption(name: "Doorbell", icon: "video.doorbell.fill", color: .red, category: "Security"),
            IconOption(name: "Lock", icon: "lock.fill", color: .red, category: "Security"),
            IconOption(name: "Sensor", icon: "sensor.fill", color: .red, category: "Security"),
        ]),
        IconCategory(name: "Smart Home", icon: "house.fill", options: [
            IconOption(name: "Blinds", icon: "blinds.vertical.closed", color: .gray, category: "Smart Home"),
            IconOption(name: "Garage", icon: "door.garage.closed", color: .gray, category: "Smart Home"),
            IconOption(name: "Home Assistant", icon: "house.fill", color: .cyan, category: "Smart Home"),
            IconOption(name: "Smart Display", icon: "tv.fill", color: .cyan, category: "Smart Home"),
            IconOption(name: "Smart Plug", icon: "powerplug.fill", color: .gray, category: "Smart Home"),
            IconOption(name: "Smart Speaker", icon: "homepod.fill", color: .cyan, category: "Smart Home"),
            IconOption(name: "Sprinkler", icon: "sprinkler.and.droplets.fill", color: .green, category: "Smart Home"),
        ]),
        IconCategory(name: "Vehicles", icon: "car.fill", options: [
            IconOption(name: "Car", icon: "car.fill", color: .gray, category: "Vehicles"),
            IconOption(name: "EV Charger", icon: "ev.charger.fill", color: .green, category: "Vehicles"),
        ]),
    ]

    private init() {
        // Load custom icons using _customIcons to bypass didSet during initialization
        if let data = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] {
            _customIcons = Published(initialValue: data)
        }
    }

    func setIcon(for hostId: String, icon: String, color: String) {
        customIcons[hostId] = "\(icon)|\(color)"
        UserDefaults.standard.set(customIcons, forKey: userDefaultsKey)
        objectWillChange.send()
    }

    func removeCustomIcon(for hostId: String) {
        customIcons.removeValue(forKey: hostId)
        UserDefaults.standard.set(customIcons, forKey: userDefaultsKey)
        objectWillChange.send()
    }

    func getCustomIcon(for hostId: String) -> (icon: String, color: Color)? {
        guard let value = customIcons[hostId] else { return nil }
        let parts = value.split(separator: "|")
        guard parts.count == 2 else { return nil }
        let icon = String(parts[0])
        let colorName = String(parts[1])
        return (icon, colorFromName(colorName))
    }

    func hasCustomIcon(for hostId: String) -> Bool {
        customIcons[hostId] != nil
    }

    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "gray": return .gray
        default: return .green
        }
    }

    static func colorName(for color: Color) -> String {
        switch color {
        case .blue: return "blue"
        case .cyan: return "cyan"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .red: return "red"
        case .purple: return "purple"
        case .green: return "green"
        case .indigo: return "indigo"
        case .mint: return "mint"
        case .gray: return "gray"
        default: return "green"
        }
    }
}

struct ZabbixStatusView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var selectedTab = 0  // 0 = Hosts tab by default (now first)
    
    /// Build Zabbix web UI URL from API URL
    private func buildZabbixWebURL(path: String) -> URL? {
        guard let apiURL = URL(string: client.serverURL) else { return nil }
        
        // Remove /api_jsonrpc.php from the URL
        var baseURL = apiURL.deletingLastPathComponent().absoluteString
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        
        return URL(string: "\(baseURL)/\(path)")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
                .environmentObject(client)

            if client.isAuthenticated {
                // Tab selector (Hosts first, Services second)
                Picker("", selection: $selectedTab) {
                    Text("tab.hosts").tag(0)
                    Text("tab.problems").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Content
                if client.isLoading && client.problems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("status.loading")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if let error = client.error {
                    ErrorView(message: error) {
                        Task { await client.refreshData() }
                    }
                } else {
                    if selectedTab == 0 {
                        HostsListView()
                            .environmentObject(client)
                    } else {
                        ProblemsListView()
                            .environmentObject(client)
                    }
                }

                // Footer
                FooterView()
                    .environmentObject(client)
            } else {
                LoginView()
                    .environmentObject(client)
            }
        }
        .background(Color(nsColor: NSColor(white: 0.1, alpha: 1.0)))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var isHoveringClose = false

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            ZStack {
                Image("ZabbixIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("title.zabbixMonitor")
                    .font(.headline)

                if client.isAuthenticated {
                    Text(connectionStatus)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if client.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }

            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isHoveringClose ? .primary : .tertiary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringClose = hovering
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var connectionStatus: String {
        if let url = URL(string: client.serverURL) {
            if let host = url.host {
                // Include port if present and not default (80/443)
                if let port = url.port, port != 80 && port != 443 {
                    return "\(host):\(port)"
                }
                return host
            }
        }
        return String(localized: "status.connected")
    }
}

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var password = ""
    @State private var showPassword = false
    @State private var testResult: String?
    @State private var testSuccess = false
    @State private var isLoggingIn = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 20)

                // Icon
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 4) {
                    Text("title.connectToZabbix")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("subtitle.enterCredentials")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Form
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("label.serverUrl")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("https://zabbix.example.com/api_jsonrpc.php", text: $client.serverURL)
                            .textFieldStyle(.plain)
                            .padding(10)
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
                            .padding(10)
                            .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("label.password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Group {
                                if showPassword {
                                    TextField(String(localized: "label.password"), text: $password)
                                } else {
                                    SecureField(String(localized: "label.password"), text: $password)
                                }
                            }
                            .textFieldStyle(.plain)

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Status messages
                if let result = testResult {
                    HStack(spacing: 6) {
                        Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(testSuccess ? .green : .red)
                        Text(result)
                            .font(.caption)
                            .foregroundColor(testSuccess ? .green : .red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(testSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }

                if let error = client.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                }

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        Task {
                            let result = await client.testConnection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                testSuccess = result.success
                                testResult = result.message
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("button.test")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        isLoggingIn = true
                        Task {
                            await client.authenticate(password: password)
                            isLoggingIn = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isLoggingIn {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text("button.login")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(client.username.isEmpty || password.isEmpty || client.serverURL.isEmpty || isLoggingIn)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Problems List View

struct ProblemsListView: View {
    @EnvironmentObject var client: ZabbixAPIClient

    var body: some View {
        if sortedProblems.isEmpty {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.1))
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 4) {
                    Text("status.allClear")
                        .font(.headline)
                    Text("status.noActiveProblems")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(sortedProblems) { problem in
                        ProblemRowView(problem: problem)
                            .environmentObject(client)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    /// Problems filtered by severity and sorted according to user preference
    private var sortedProblems: [ZabbixProblem] {
        let filtered = client.problems.filter { problem in
            let severity = Int(problem.severity) ?? 0
            return client.severityFilter.includes(severity: severity)
        }

        switch client.problemSortOrder {
        case .criticality:
            return filtered.sorted { a, b in
                let severityA = Int(a.severity) ?? 0
                let severityB = Int(b.severity) ?? 0
                if severityA != severityB {
                    return severityA > severityB
                }
                return a.timestamp > b.timestamp
            }
        case .latest:
            return filtered.sorted { a, b in
                a.timestamp > b.timestamp
            }
        case .alphabetical:
            return filtered.sorted { a, b in
                a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }
}

struct ProblemRowView: View {
    let problem: ZabbixProblem
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var showAcknowledge = false
    @State private var isHovering = false
    @State private var acknowledgementWindow: NSWindow?

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(severityColor.gradient)
                .frame(width: 10, height: 10)
                .shadow(color: severityColor.opacity(0.4), radius: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(problem.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.white)
                
                Text(problem.hostname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if problem.isAcknowledged {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 12))
            }

            Text(problem.timestamp, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? .white.opacity(0.06) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            openProblemInZabbix()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            if !problem.isAcknowledged {
                Button {
                    showAcknowledgeWindow()
                } label: {
                    Label(String(localized: "button.acknowledge"), systemImage: "checkmark.circle")
                }
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(problem.name, forType: .string)
            } label: {
                Label(String(localized: "menu.copyName"), systemImage: "doc.on.doc")
            }
        }
    }

    var severityColor: Color {
        switch problem.severityLevel {
        case .notClassified: return .gray
        case .information: return .blue
        case .warning: return .yellow
        case .average: return .orange
        case .high: return .red
        case .disaster: return .black
        }
    }

    private func openProblemInZabbix() {
        guard let apiURL = URL(string: client.serverURL) else { return }
        
        // Remove /api_jsonrpc.php from the URL
        var baseURL = apiURL.deletingLastPathComponent().absoluteString
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        
        // Build event detail URL: tr_events.php?triggerid={objectid}&eventid={eventid}
        if let url = URL(string: "\(baseURL)/tr_events.php?triggerid=\(problem.objectid)&eventid=\(problem.eventid)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showAcknowledgeWindow() {
        let contentView = AcknowledgeSheet(problem: problem)
            .environmentObject(client)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = ""
        window.level = .popUpMenu  // Higher than floating, same level as menu bar items
        window.center()
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        acknowledgementWindow = window
    }
}

struct AcknowledgeSheet: View {
    let problem: ZabbixProblem
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var acknowledgementTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                }

                Text("title.acknowledgeProblem")
                    .font(.headline)
            }

            // Problem name
            Text(problem.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Message field
            VStack(alignment: .leading, spacing: 6) {
                Text("label.messageOptional")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(String(localized: "placeholder.addNote"), text: $message)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Buttons
            HStack(spacing: 12) {
                Button(String(localized: "button.cancel")) {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    isSubmitting = true
                    // Capture references for detached task
                    let apiClient = client
                    let eventId = problem.eventid
                    let ackMessage = message.isEmpty ? "Acknowledged via ZabbixMenuBar" : message

                    // Use detached task to ensure acknowledgment completes even if view closes
                    acknowledgementTask = Task.detached {
                        do {
                            print("Starting acknowledgment for event: \(eventId)")
                            try await apiClient.acknowledgeProblem(
                                eventId: eventId,
                                message: ackMessage
                            )
                            print("Acknowledgment completed successfully")
                        } catch {
                            print("Acknowledgment error: \(error)")
                        }

                        await MainActor.run {
                            isSubmitting = false
                            closeWindow()
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        }
                        Text("button.acknowledge")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(.ultraThinMaterial)
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}

// MARK: - Hosts List View

enum HostSortType: String {
    case alphabetical
    case problems
}

struct HostsListView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var searchText = ""
    @State private var sortType: HostSortType = .problems
    @State private var sortAscending: Bool = false  // Default: highest severity first

    var filteredHosts: [ZabbixHost] {
        var hosts: [ZabbixHost]
        if searchText.isEmpty {
            hosts = client.hosts
        } else {
            hosts = client.hosts.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.host.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortType {
        case .alphabetical:
            return hosts.sorted { host1, host2 in
                let result = host1.name.localizedCaseInsensitiveCompare(host2.name) == .orderedAscending
                return sortAscending ? result : !result
            }
        case .problems:
            return hosts.sorted { host1, host2 in
                let severity1 = maxSeverity(for: host1)
                let severity2 = maxSeverity(for: host2)
                if severity1 != severity2 {
                    return sortAscending ? severity1 < severity2 : severity1 > severity2
                }
                // Secondary sort by problem count
                let count1 = problemCount(for: host1)
                let count2 = problemCount(for: host2)
                if count1 != count2 {
                    return sortAscending ? count1 < count2 : count1 > count2
                }
                return host1.name.localizedCaseInsensitiveCompare(host2.name) == .orderedAscending
            }
        }
    }

    private func problemCount(for host: ZabbixHost) -> Int {
        client.problems.filter { problem in
            problem.hostid == host.hostid
        }.count
    }

    private func maxSeverity(for host: ZabbixHost) -> Int {
        client.problems.filter { problem in
            problem.hostid == host.hostid
        }.map { Int($0.severity) ?? 0 }.max() ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and sort row
            HStack(spacing: 8) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)

                    TextField(String(localized: "placeholder.search"), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )

                // Sort buttons
                HStack(spacing: 0) {
                    Button {
                        if sortType == .alphabetical {
                            sortAscending.toggle()
                        } else {
                            sortType = .alphabetical
                            sortAscending = true
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("sort.aToZ")
                                .font(.caption)
                                .fontWeight(sortType == .alphabetical ? .semibold : .regular)
                            if sortType == .alphabetical {
                                Image(systemName: sortAscending ? "chevron.down" : "chevron.up")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .foregroundColor(sortType == .alphabetical ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(sortType == .alphabetical ? Color.accentColor : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if sortType == .problems {
                            sortAscending.toggle()
                        } else {
                            sortType = .problems
                            sortAscending = false  // Default to highest severity first
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("tab.problems")
                                .font(.caption)
                                .fontWeight(sortType == .problems ? .semibold : .regular)
                            if sortType == .problems {
                                Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .foregroundColor(sortType == .problems ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(sortType == .problems ? Color.accentColor : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            if filteredHosts.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.secondary.opacity(0.1))
                            .frame(width: 56, height: 56)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }

                    Text("status.noHostsFound")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredHosts) { host in
                            HostRowView(host: host)
                                .environmentObject(client)
                                .id(host.hostid)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct HostRowView: View {
    let host: ZabbixHost
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var isHovering = false
    @State private var showProblemsPopover = false
    @State private var isHoveringPopover = false
    @ObservedObject private var iconManager = HostIconManager.shared

    /// Count of active problems for this host
    private var problemCount: Int {
        client.problems.filter { problem in
            problem.hostid == host.hostid
        }.count
    }
    
    /// Count problems by severity for this host
    private var severityCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for problem in client.problems where problem.hostid == host.hostid {
            let severity = Int(problem.severity) ?? 0
            counts[severity, default: 0] += 1
        }
        return counts
    }

    /// Color based on severity
    private func colorForSeverityInt(_ severity: Int) -> Color {
        switch severity {
        case 5: return .black  // Disaster - black
        case 4: return .red  // High - red
        case 3: return .orange  // Average - orange
        case 2: return .yellow  // Warning - yellow
        case 1: return .blue  // Information - blue
        default: return .gray  // Not classified - gray
        }
    }

    /// List of problems for this host, sorted by severity (highest first)
    private var problemsForHost: [ZabbixProblem] {
        client.problems
            .filter { problem in
                problem.hostid == host.hostid
            }
            .sorted { (Int($0.severity) ?? 0) > (Int($1.severity) ?? 0) }
    }
    
    /// Color for a given severity level
    private func colorForSeverity(_ severity: SeverityLevel) -> Color {
        switch severity {
        case .disaster: return .black
        case .high: return .red
        case .average: return .orange
        case .warning: return .yellow
        case .information: return .blue
        case .notClassified: return .gray
        }
    }
    
    /// Problem list content (shared between scrollable and non-scrollable views)
    private var problemListContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(problemsForHost, id: \.eventid) { problem in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForSeverity(problem.severityLevel))
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(problem.name)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(problem.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.05))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    openProblemInZabbix(problem)
                    showProblemsPopover = false
                }
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(host.isEnabled ? vibrantIconColor.opacity(0.35) : .secondary.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: displayIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(host.isEnabled ? vibrantIconColor : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(host.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(host.host)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if problemCount > 0 {
                // Show one badge per severity (only if count > 0)
                HStack(spacing: 4) {
                    ForEach([5, 4, 3, 2, 1, 0], id: \.self) { severity in
                        if let count = severityCounts[severity], count > 0 {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(colorForSeverityInt(severity))
                                    .frame(width: 6, height: 6)
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(colorForSeverityInt(severity).opacity(0.3))
                            )
                        }
                    }
                }
                .popover(isPresented: $showProblemsPopover, arrowEdge: .trailing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(host.name) - \(problemCount) problem\(problemCount > 1 ? "s" : "")")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))

                        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
                        let maxPopoverHeight = screenHeight * 0.7
                        let estimatedContentHeight = CGFloat(problemsForHost.count) * 60.0 // ~60px per problem
                        let needsScroll = estimatedContentHeight > maxPopoverHeight
                        
                        Group {
                            if needsScroll {
                                ScrollView {
                                    problemListContent
                                }
                                .frame(maxHeight: maxPopoverHeight)
                            } else {
                                problemListContent
                            }
                        }
                    }
                    .padding(12)
                    .frame(minWidth: 250, maxWidth: 350)
                    .background(Color(nsColor: NSColor(white: 0.15, alpha: 1.0)))
                    .environment(\.colorScheme, .dark)
                    .onHover { hovering in
                        isHoveringPopover = hovering
                    }
                }
                .onHover { hovering in
                    if hovering {
                        showProblemsPopover = true
                    } else {
                        // Delay closing to allow moving to popover
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if !isHoveringPopover {
                                showProblemsPopover = false
                            }
                        }
                    }
                }
            } else {
                Text("OK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? .white.opacity(0.06) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            openHostInZabbix()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            ForEach(HostIconManager.iconCategories) { category in
                Menu {
                    ForEach(category.options) { option in
                        Button {
                            iconManager.setIcon(
                                for: host.hostid,
                                icon: option.icon,
                                color: HostIconManager.colorName(for: option.color)
                            )
                        } label: {
                            Label(option.name, systemImage: option.icon)
                        }
                    }
                } label: {
                    Label(category.name, systemImage: category.icon)
                }
            }

            if iconManager.hasCustomIcon(for: host.hostid) {
                Divider()
                Button(String(localized: "button.resetToAuto")) {
                    iconManager.removeCustomIcon(for: host.hostid)
                }
            }
        }
    }

    private func openHostInZabbix() {
        guard let apiURL = URL(string: client.serverURL) else { return }
        
        // Remove /api_jsonrpc.php from the URL
        var baseURL = apiURL.deletingLastPathComponent().absoluteString
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        
        // Build problems page URL with host filter
        // Reset groupids and triggerids to 0 to clear those filters
        // filter_show=1 shows recent problems
        // show_suppressed=1 shows suppressed problems
        let urlString = "\(baseURL)/zabbix.php?action=problem.view&filter_set=1&groupids[]=0&hostids[]=\(host.hostid)&triggerids[]=0&filter_show=1&show_suppressed=1"
        
        print("Opening URL: \(urlString)")
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openProblemInZabbix(_ problem: ZabbixProblem) {
        guard let apiURL = URL(string: client.serverURL) else { return }
        
        // Remove /api_jsonrpc.php from the URL
        var baseURL = apiURL.deletingLastPathComponent().absoluteURL.absoluteString
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        
        // Build event detail URL: tr_events.php?triggerid={objectid}&eventid={eventid}
        if let url = URL(string: "\(baseURL)/tr_events.php?triggerid=\(problem.objectid)&eventid=\(problem.eventid)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// The icon to display (custom or auto-detected)
    private var displayIcon: String {
        if let custom = iconManager.getCustomIcon(for: host.hostid) {
            return custom.icon
        }
        return hostIcon
    }

    /// The color to display (custom or auto-detected)
    private var displayIconColor: Color {
        if let custom = iconManager.getCustomIcon(for: host.hostid) {
            return custom.color
        }
        return iconColor
    }

    /// Determines the appropriate SF Symbol icon based on host name keywords
    private var hostIcon: String {
        let name = host.name.lowercased()

        // Phones & Mobile Devices (check early to avoid false matches with "cam" in camera)
        if name.contains("iphone") || name.contains("android") || name.contains("phone") || name.contains("pixel") || name.contains("galaxy") || name.contains("samsung") {
            return "iphone"
        }
        if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        }
        if name.contains("watch") || name.contains("fitbit") || name.contains("garmin") {
            return "applewatch"
        }

        // Amazon Devices (check "show" before "echo" since Show devices have screens)
        if name.contains("show") || name.contains("fire tv") || name.contains("firetv") {
            return "tv.fill"
        }
        if name.contains("echo") || name.contains("alexa") {
            return "homepod.fill"
        }

        // Lighting
        if name.contains("christmas") || name.contains("xmas") || name.contains("holiday") || name.contains("festive") {
            return "sparkles"
        }
        if name.contains("string light") || name.contains("fairy light") || name.contains("party") {
            return "party.popper.fill"
        }
        if name.contains("light") || name.contains("lamp") || name.contains("bulb") || name.contains("hue") {
            return "lightbulb.fill"
        }
        // Appliances
        if name.contains("washer") || name.contains("washing") || name.contains("laundry") {
            return "washer.fill"
        }
        if name.contains("dryer") {
            return "dryer.fill"
        }
        if name.contains("dishwasher") {
            return "dishwasher.fill"
        }
        if name.contains("fridge") || name.contains("refrigerator") {
            return "refrigerator.fill"
        }
        if name.contains("oven") || name.contains("stove") || name.contains("range") {
            return "oven.fill"
        }
        if name.contains("microwave") {
            return "microwave.fill"
        }
        // Climate
        if name.contains("thermostat") || name.contains("hvac") || name.contains("climate") || name.contains("nest") || name.contains("ecobee") {
            return "thermometer.medium"
        }
        if name.contains("air conditioner") || name.contains("cooling") {
            return "air.conditioner.horizontal.fill"
        }
        if name.contains("heater") || name.contains("heating") || name.contains("furnace") {
            return "heater.vertical.fill"
        }
        if name.contains("fan") {
            return "fan.fill"
        }
        // Security (camera check is more specific now)
        if name.contains("doorbell") || name.contains("ring") {
            return "video.doorbell.fill"
        }
        if name.contains("camera") || name.contains("webcam") || name.contains("cam ") || name.hasSuffix("cam") {
            return "video.fill"
        }
        if name.contains("lock") || name.contains("door") && !name.contains("doorbell") {
            return "lock.fill"
        }
        if name.contains("alarm") || name.contains("security") {
            return "shield.fill"
        }
        if name.contains("sensor") || name.contains("motion") {
            return "sensor.fill"
        }
        // Entertainment
        if name.contains("tv") || name.contains("television") || name.contains("roku") {
            return "tv.fill"
        }
        if name.contains("speaker") || name.contains("sonos") || name.contains("homepod") {
            return "hifispeaker.fill"
        }
        if name.contains("apple tv") || name.contains("appletv") {
            return "appletv.fill"
        }
        // Networking
        if name.contains("firewall") || name.contains("firewalla") {
            return "flame.fill"
        }
        if name.contains("router") || name.contains("gateway") || name.contains("eero") || name.contains("orbi") || name.contains("unifi") {
            return "wifi.router.fill"
        }
        if name.contains("eap") || name.contains("access point") || name.contains("ap ") || name.hasSuffix(" ap") {
            return "wifi"
        }
        if name.contains("switch") && !name.contains("light") && !name.contains("nintendo") {
            return "rectangle.connected.to.line.below"
        }
        if name.contains("nas") || name.contains("synology") || name.contains("qnap") || name.contains("storage") {
            return "externaldrive.fill"
        }
        if name.contains("printer") {
            return "printer.fill"
        }
        // Computers
        if name.contains("imac") || name.contains("macbook") || name.contains("mac mini") || name.contains("mac pro") || name.contains("mac studio") {
            return "desktopcomputer"
        }
        if name.contains("laptop") || name.contains("notebook") || name.contains("chromebook") {
            return "laptopcomputer"
        }
        // Gaming
        if name.contains("playstation") || name.contains("ps5") || name.contains("ps4") || name.contains("xbox") || name.contains("nintendo") {
            return "gamecontroller.fill"
        }
        // Smart Home
        if name.contains("home assistant") || name.contains("homeassistant") || name.contains("hass") || name.contains("nabu") {
            return "house.fill"
        }
        if name.contains("plug") || name.contains("outlet") || name.contains("socket") {
            return "powerplug.fill"
        }
        if name.contains("blind") || name.contains("shade") || name.contains("curtain") {
            return "blinds.vertical.closed"
        }
        if name.contains("garage") {
            return "door.garage.closed"
        }
        if name.contains("sprinkler") || name.contains("irrigation") {
            return "sprinkler.and.droplets.fill"
        }
        // Vehicles
        if name.contains("car") || name.contains("tesla") || name.contains("vehicle") {
            return "car.fill"
        }
        if name.contains("charger") || name.contains("ev") {
            return "ev.charger.fill"
        }
        // Servers & Infrastructure
        if name.contains("vm ") || name.hasSuffix(" vm") || name.contains("virtual machine") || name.contains("hyperv") || name.contains("hyper-v") {
            return "cube.transparent"
        }
        if name.contains("server") || name.contains("esxi") || name.contains("proxmox") || name.contains("vmware") {
            return "server.rack"
        }
        if name.contains("database") || name.contains("mysql") || name.contains("postgres") || name.contains("sql") {
            return "cylinder.fill"
        }
        if name.contains("docker") || name.contains("container") || name.contains("kubernetes") || name.contains("k8s") {
            return "shippingbox.fill"
        }
        if name.contains("cloud") || name.contains("aws") || name.contains("azure") {
            return "cloud.fill"
        }
        // Power
        if name.contains("ups") || name.contains("battery") || name.contains("power") {
            return "battery.100.bolt"
        }
        if name.contains("solar") || name.contains("inverter") {
            return "sun.max.fill"
        }
        // Default
        return "server.rack"
    }

    /// Color for the icon based on device type
    private var iconColor: Color {
        let name = host.name.lowercased()

        // Mobile devices
        if name.contains("iphone") || name.contains("android") || name.contains("phone") || name.contains("pixel") || name.contains("galaxy") {
            return .blue
        }
        if name.contains("ipad") || name.contains("tablet") {
            return .blue
        }
        // Amazon devices
        if name.contains("echo") || name.contains("alexa") || name.contains("show") {
            return .cyan
        }
        // Home Automation
        if name.contains("home assistant") || name.contains("homeassistant") || name.contains("hass") || name.contains("nabu") {
            return .cyan
        }
        // Lighting
        if name.contains("christmas") || name.contains("xmas") || name.contains("holiday") || name.contains("festive") {
            return .yellow
        }
        if name.contains("string light") || name.contains("fairy light") || name.contains("party") {
            return .orange
        }
        if name.contains("light") || name.contains("lamp") || name.contains("bulb") || name.contains("hue") {
            return .yellow
        }
        // Security
        if name.contains("camera") || name.contains("security") || name.contains("alarm") || name.contains("lock") || name.contains("ring") {
            return .red
        }
        // Climate
        if name.contains("thermostat") || name.contains("climate") || name.contains("hvac") || name.contains("nest") || name.contains("ecobee") {
            return .orange
        }
        // Entertainment
        if name.contains("speaker") || name.contains("tv") || name.contains("appletv") || name.contains("roku") || name.contains("sonos") || name.contains("homepod") {
            return .purple
        }
        // Gaming
        if name.contains("playstation") || name.contains("xbox") || name.contains("nintendo") || name.contains("ps5") || name.contains("ps4") {
            return .green
        }
        // Networking
        if name.contains("firewall") || name.contains("firewalla") {
            return .orange
        }
        if name.contains("router") || name.contains("switch") || name.contains("network") || name.contains("eero") || name.contains("unifi") || name.contains("eap") || name.contains("access point") {
            return .blue
        }
        // Servers & Storage
        if name.contains("vm ") || name.hasSuffix(" vm") || name.contains("virtual machine") || name.contains("hyperv") || name.contains("hyper-v") {
            return .indigo
        }
        if name.contains("server") || name.contains("nas") || name.contains("database") || name.contains("synology") || name.contains("qnap") {
            return .indigo
        }
        // Power
        if name.contains("solar") || name.contains("power") || name.contains("ups") {
            return .mint
        }
        return .green
    }

    /// Vibrant version of icon color for better visibility in dark mode
    private var vibrantIconColor: Color {
        let baseColor = displayIconColor

        // Return brighter, more saturated versions of each color
        switch baseColor {
        case .blue:
            return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .cyan:
            return Color(red: 0.2, green: 0.9, blue: 1.0)
        case .yellow:
            return Color(red: 1.0, green: 0.9, blue: 0.3)
        case .orange:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .red:
            return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .purple:
            return Color(red: 0.75, green: 0.45, blue: 1.0)
        case .green:
            return Color(red: 0.3, green: 0.95, blue: 0.5)
        case .indigo:
            return Color(red: 0.5, green: 0.5, blue: 1.0)
        case .mint:
            return Color(red: 0.3, green: 1.0, blue: 0.8)
        case .gray:
            return Color(white: 0.7)
        default:
            return Color(red: 0.3, green: 0.95, blue: 0.5)
        }
    }
}

// MARK: - Footer View

struct FooterView: View {
    @EnvironmentObject var client: ZabbixAPIClient
    @State private var isHoveringRefresh = false
    @State private var isHoveringMenu = false

    var body: some View {
        HStack(spacing: 12) {
            if let lastRefresh = client.lastRefresh {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(lastRefresh, style: .relative)
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                Task { await client.refreshData() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isHoveringRefresh ? .primary : .secondary)
                    .rotationEffect(.degrees(client.isLoading ? 360 : 0))
                    .animation(client.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: client.isLoading)
            }
            .buttonStyle(.plain)
            .disabled(client.isLoading)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringRefresh = hovering
                }
            }

            Menu {
                SettingsLink {
                    Label("menu.settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button {
                    client.logout()
                } label: {
                    Label("menu.logout", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Divider()

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("menu.quit", systemImage: "power")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isHoveringMenu ? .primary : .secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringMenu = hovering
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.orange.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("error.connectionError")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                retryAction()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("button.retry")
                }
                .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
    }
}

#Preview {
    ZabbixStatusView()
        .environmentObject(ZabbixAPIClient())
        .frame(width: 400, height: 500)
}
