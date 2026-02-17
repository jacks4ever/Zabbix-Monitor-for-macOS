import Foundation
import Security
import SwiftUI
import WidgetKit
import Combine
import UserNotifications

// MARK: - Zabbix API Models

struct ZabbixProblem: Identifiable, Codable {
    let eventid: String
    let objectid: String
    let name: String
    let severity: String
    let clock: String
    let acknowledged: String
    let hostid: String
    let hostname: String

    var id: String { eventid }

    var severityLevel: SeverityLevel {
        SeverityLevel(rawValue: Int(severity) ?? 0) ?? .notClassified
    }

    var timestamp: Date {
        Date(timeIntervalSince1970: Double(clock) ?? 0)
    }

    var isAcknowledged: Bool {
        acknowledged == "1"
    }
}

enum SeverityLevel: Int, CaseIterable {
    case notClassified = 0
    case information = 1
    case warning = 2
    case average = 3
    case high = 4
    case disaster = 5

    var name: String {
        switch self {
        case .notClassified: return "Not Classified"
        case .information: return "Information"
        case .warning: return "Warning"
        case .average: return "Average"
        case .high: return "High"
        case .disaster: return "Disaster"
        }
    }

    var color: String {
        switch self {
        case .notClassified: return "gray"
        case .information: return "blue"
        case .warning: return "yellow"
        case .average: return "orange"
        case .high: return "red"
        case .disaster: return "black"
        }
    }
}

struct ZabbixHost: Identifiable, Codable {
    let hostid: String
    let host: String
    let name: String
    let status: String

    var id: String { hostid }

    var isEnabled: Bool {
        status == "0"
    }
}

// Simplified host structure for trigger.get API (no status field)
struct ZabbixTriggerHost: Codable {
    let hostid: String
    let host: String
    let name: String
}

struct ZabbixTrigger: Codable {
    let triggerid: String
    let description: String
    let priority: String
    let lastchange: String
    let value: String
}

struct ZabbixEvent: Codable {
    let eventid: String
    let acknowledged: String
}

struct ZabbixTriggerWithEvent: Codable {
    let triggerid: String
    let description: String
    let priority: String
    let lastchange: String
    let value: String
    let lastEvent: ZabbixEvent?
    let hosts: [ZabbixTriggerHost]?
}

// MARK: - API Response Types

struct ZabbixAPIResponse<T: Decodable>: Decodable {
    let jsonrpc: String
    let result: T?
    let error: ZabbixAPIError?
    let id: Int
}

struct ZabbixAPIError: Decodable, Error {
    let code: Int
    let message: String
    let data: String?

    var localizedDescription: String {
        if let data = data {
            return "\(message): \(data)"
        }
        return message
    }
}

struct AcknowledgeResult: Decodable {
    let eventids: [Int]?
}

// MARK: - Problem Sort Order

enum ProblemSortOrder: String, CaseIterable, Codable {
    case criticality = "criticality"
    case latest = "latest"
    case alphabetical = "alphabetical"

    var displayName: String {
        switch self {
        case .criticality: return "Criticality"
        case .latest: return "Latest"
        case .alphabetical: return "Alphabetical"
        }
    }

    var localizedName: String {
        switch self {
        case .criticality: return String(localized: "sort.criticality")
        case .latest: return String(localized: "sort.latest")
        case .alphabetical: return String(localized: "sort.alphabetical")
        }
    }
}

// MARK: - Severity Filter

struct SeverityFilter: Codable, Equatable {
    var disaster: Bool = true
    var high: Bool = true
    var average: Bool = true
    var warning: Bool = true
    var information: Bool = true
    var notClassified: Bool = false

    /// Returns array of severity levels that are enabled
    var enabledLevels: Set<Int> {
        var levels = Set<Int>()
        if disaster { levels.insert(5) }
        if high { levels.insert(4) }
        if average { levels.insert(3) }
        if warning { levels.insert(2) }
        if information { levels.insert(1) }
        if notClassified { levels.insert(0) }
        return levels
    }

    /// Check if a severity level is enabled
    func includes(severity: Int) -> Bool {
        enabledLevels.contains(severity)
    }
}

// MARK: - AI Provider Types

enum AIProvider: String, CaseIterable, Codable {
    case disabled = "disabled"
    case ollama = "ollama"
    case openai = "openai"
    case anthropic = "anthropic"

    var displayName: String {
        switch self {
        case .disabled: return "Disabled"
        case .ollama: return "Ollama (Local)"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .disabled: return "ai.disabled"
        case .ollama: return "ai.ollamaLocal"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .disabled, .ollama: return false
        case .openai, .anthropic: return true
        }
    }
}

// MARK: - Ollama API Models

struct OllamaRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions?
}

struct OllamaOptions: Encodable {
    let num_predict: Int  // Max tokens to generate
}

struct OllamaResponse: Decodable {
    let response: String
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
}

struct OpenAIMessage: Encodable {
    let role: String
    let content: String
}

struct OpenAIResponse: Decodable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Decodable {
    let message: OpenAIMessageResponse
}

struct OpenAIMessageResponse: Decodable {
    let content: String
}

// MARK: - Anthropic API Models

struct AnthropicRequest: Encodable {
    let model: String
    let max_tokens: Int
    let messages: [AnthropicMessage]
}

struct AnthropicMessage: Encodable {
    let role: String
    let content: String
}

struct AnthropicResponse: Decodable {
    let content: [AnthropicContent]
}

struct AnthropicContent: Decodable {
    let text: String
}

// MARK: - Session Delegate for Self-Signed Certs

class ZabbixSessionDelegate: NSObject, URLSessionDelegate {
    let allowSelfSigned: Bool

    init(allowSelfSigned: Bool = true) {
        self.allowSelfSigned = allowSelfSigned
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           allowSelfSigned {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static let service = "com.zabbixmenubar.credentials"

    static func save(token: String, for server: String) throws {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }

    static func getToken(for server: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func deleteToken(for server: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: server
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Zabbix API Client

@MainActor
class ZabbixAPIClient: ObservableObject {
    @Published var problems: [ZabbixProblem] = []
    @Published var hosts: [ZabbixHost] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isAuthenticated = false
    @Published var lastRefresh: Date?
    @Published var severityCounts: [Int: Int] = [:]  // Count of problems per severity level

    /// Pause auto-refresh (e.g., when context menu is open)
    var pauseRefresh = false
    
    // Notification tracking
    private var previousProblems: Set<String> = []  // Track eventids we've already seen
    private var notificationBuffer: [String: [ZabbixProblem]] = [:]  // hostid -> problems
    private var notificationWorkItem: DispatchWorkItem?

    // Configuration - simple @Published without didSet
    @Published var serverURL: String = ""
    @Published var username: String = ""
    @Published var refreshInterval: TimeInterval = 300  // 5 minutes - better for battery
    @Published var allowSelfSignedCerts: Bool = true
    @Published var problemSortOrder: ProblemSortOrder = .criticality
    @Published var severityFilter: SeverityFilter = SeverityFilter()
    @Published var widgetSeverityFilter: WidgetSeverityFilter = WidgetSeverityFilter()

    // AI Configuration - simple @Published without didSet
    @Published var aiProvider: AIProvider = .ollama
    @Published var ollamaURL: String = ""
    @Published var ollamaModel: String = ""
    @Published var openAIAPIKey: String = ""
    @Published var openAIModel: String = ""
    @Published var anthropicAPIKey: String = ""
    @Published var anthropicModel: String = ""
    @Published var customAIPrompt: String = ""
    @Published var widgetProblemCount: Int = 6
    @Published var aiSummary: String = ""

    // Combine cancellables for persistence subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Default AI prompt - localized based on app's selected language setting
    static var defaultAIPrompt: String {
        let language = LanguageManager.shared.selectedLanguage
        return localizedString("ai.defaultPrompt", for: language)
    }

    /// Get the default prompt for a specific language
    static func defaultAIPrompt(for language: AppLanguage) -> String {
        return localizedString("ai.defaultPrompt", for: language)
    }

    /// Get a localized string for a specific language by loading from the appropriate .lproj bundle
    private static func localizedString(_ key: String, for language: AppLanguage) -> String {
        // For system default, use the standard localization
        guard language != .system else {
            return String(localized: String.LocalizationValue(key))
        }

        // Get the language code
        let languageCode = language.rawValue

        // Try to find the appropriate .lproj bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        }

        // Fallback to default localization
        return String(localized: String.LocalizationValue(key))
    }

    /// Get all default prompts in all supported languages
    static var allDefaultPrompts: Set<String> {
        var prompts = Set<String>()
        for language in AppLanguage.allCases {
            prompts.insert(localizedString("ai.defaultPrompt", for: language))
        }
        return prompts
    }

    /// Check if a prompt is one of the default prompts (in any language)
    static func isDefaultPrompt(_ prompt: String) -> Bool {
        allDefaultPrompts.contains(prompt)
    }

    /// Update the AI prompt to the current language's default (if it was a default prompt)
    func updatePromptForLanguageChange() {
        if ZabbixAPIClient.isDefaultPrompt(customAIPrompt) {
            customAIPrompt = ZabbixAPIClient.defaultAIPrompt
        }
    }

    private var authToken: String?
    private var lastProblemSignature: String = "" // Track problem IDs + filter to detect changes
    private var session: URLSession!
    private var sessionDelegate: ZabbixSessionDelegate!
    private var refreshTimer: Timer?

    init() {
        // Load saved values from UserDefaults
        let savedRefreshInterval = UserDefaults.standard.double(forKey: "zabbix_refresh_interval")
        let savedSortOrder = UserDefaults.standard.string(forKey: "problem_sort_order") ?? "criticality"
        let savedProvider = UserDefaults.standard.string(forKey: "ai_provider") ?? "ollama"
        let savedProblemCount = UserDefaults.standard.integer(forKey: "widget_problem_count")

        // Connection settings
        serverURL = UserDefaults.standard.string(forKey: "zabbix_server_url") ?? "https://192.168.46.183:2443/api_jsonrpc.php"
        username = UserDefaults.standard.string(forKey: "zabbix_username") ?? ""
        // Default to 300 seconds (5 min) for better battery life
        // Migrate users from old 60-second default to new 300-second default
        if savedRefreshInterval == 0 || savedRefreshInterval == 60 {
            refreshInterval = 300
        } else {
            refreshInterval = savedRefreshInterval
        }
        allowSelfSignedCerts = UserDefaults.standard.object(forKey: "zabbix_allow_self_signed") as? Bool ?? true
        problemSortOrder = ProblemSortOrder(rawValue: savedSortOrder) ?? .criticality

        // Severity Filter (menu bar app)
        if let filterData = UserDefaults.standard.data(forKey: "severity_filter"),
           let savedFilter = try? JSONDecoder().decode(SeverityFilter.self, from: filterData) {
            severityFilter = savedFilter
        }

        // Widget Severity Filter
        if let filterData = UserDefaults.standard.data(forKey: "widget_severity_filter"),
           let savedFilter = try? JSONDecoder().decode(WidgetSeverityFilter.self, from: filterData) {
            widgetSeverityFilter = savedFilter
        }

        // AI Configuration
        aiProvider = AIProvider(rawValue: savedProvider) ?? .ollama
        ollamaURL = UserDefaults.standard.string(forKey: "ollama_url") ?? "http://192.168.200.246:11434"
        ollamaModel = UserDefaults.standard.string(forKey: "ollama_model") ?? "mistral:7b"
        openAIAPIKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        openAIModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
        anthropicAPIKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        anthropicModel = UserDefaults.standard.string(forKey: "anthropic_model") ?? "claude-3-5-haiku-latest"

        // Load custom AI prompt and migrate old prompts that don't have placeholders
        let savedPrompt = UserDefaults.standard.string(forKey: "custom_ai_prompt") ?? ZabbixAPIClient.defaultAIPrompt
        if !savedPrompt.contains("{PROBLEM_LIST}") {
            // Old prompt format without placeholders - use current default
            customAIPrompt = ZabbixAPIClient.defaultAIPrompt
            UserDefaults.standard.set(ZabbixAPIClient.defaultAIPrompt, forKey: "custom_ai_prompt")
        } else {
            customAIPrompt = savedPrompt
        }

        widgetProblemCount = savedProblemCount > 0 ? savedProblemCount : 6
        
        // Load previously seen problem eventids for notification tracking
        if let data = UserDefaults.standard.data(forKey: "previous_problem_eventids"),
           let eventids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            previousProblems = eventids
        }

        setupSession()
        setupPersistenceSubscriptions()

        // Try to restore cached token
        if let cachedToken = KeychainHelper.getToken(for: serverURL) {
            self.authToken = cachedToken
            self.isAuthenticated = true
            Task {
                await refreshData()
            }
            // Defer timer setup to ensure run loop is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startAutoRefresh()
            }
        }
    }

    /// Set up Combine subscriptions for persisting changes to UserDefaults
    /// This approach avoids "Publishing changes from within view updates" warnings
    /// by using dropFirst() to skip initial values and removeDuplicates() to prevent loops
    private func setupPersistenceSubscriptions() {
        // Simple string/value persistence
        $serverURL
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "zabbix_server_url") }
            .store(in: &cancellables)

        $username
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "zabbix_username") }
            .store(in: &cancellables)

        $refreshInterval
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "zabbix_refresh_interval")
                self?.setupRefreshTimer()
            }
            .store(in: &cancellables)

        $allowSelfSignedCerts
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "zabbix_allow_self_signed")
                self?.setupSession()
            }
            .store(in: &cancellables)

        $problemSortOrder
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0.rawValue, forKey: "problem_sort_order") }
            .store(in: &cancellables)

        $severityFilter
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                if let data = try? JSONEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: "severity_filter")
                }
            }
            .store(in: &cancellables)

        $widgetSeverityFilter
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: "widget_severity_filter")
                }
                self?.saveDataForWidget()
            }
            .store(in: &cancellables)

        // AI Configuration persistence
        $aiProvider
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                UserDefaults.standard.set(value.rawValue, forKey: "ai_provider")
                self?.onAIProviderChanged()
            }
            .store(in: &cancellables)

        $ollamaURL
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "ollama_url") }
            .store(in: &cancellables)

        $ollamaModel
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "ollama_model") }
            .store(in: &cancellables)

        $openAIAPIKey
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "openai_api_key") }
            .store(in: &cancellables)

        $openAIModel
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "openai_model") }
            .store(in: &cancellables)

        $anthropicAPIKey
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "anthropic_api_key") }
            .store(in: &cancellables)

        $anthropicModel
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "anthropic_model") }
            .store(in: &cancellables)

        $customAIPrompt
            .dropFirst()
            .removeDuplicates()
            .sink { UserDefaults.standard.set($0, forKey: "custom_ai_prompt") }
            .store(in: &cancellables)

        $widgetProblemCount
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "widget_problem_count")
                self?.saveDataForWidget()
                // Note: Widget reload is now handled by saveDataForWidget() with change detection
            }
            .store(in: &cancellables)
    }

    private func setupSession() {
        sessionDelegate = ZabbixSessionDelegate(allowSelfSigned: allowSelfSignedCerts)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        // Disable caching to ensure fresh data on every request
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
    }

    private func setupRefreshTimer() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setupRefreshTimer()
            }
            return
        }

        refreshTimer?.invalidate()
        refreshTimer = nil
        guard refreshInterval > 0 else { return }

        // Create timer with .default mode for better energy efficiency
        // Using .default instead of .common allows macOS to coalesce timers
        // and throttle when the app is not actively in use, saving battery
        let timer = Timer(timeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.pauseRefresh else { return }
                await self.refreshData()
            }
        }
        RunLoop.main.add(timer, forMode: .default)
        refreshTimer = timer
    }

    func startAutoRefresh() {
        setupRefreshTimer()
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - API Methods

    func authenticate(password: String) async {
        isLoading = true
        error = nil

        do {
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "user.login",
                "params": [
                    "username": username,
                    "password": password
                ],
                "id": 1
            ]

            let response: ZabbixAPIResponse<String> = try await performRequest(payload: payload)

            if let token = response.result {
                authToken = token
                isAuthenticated = true
                try? KeychainHelper.save(token: token, for: serverURL)
                await refreshData()
                startAutoRefresh()
            } else if let apiError = response.error {
                throw apiError
            }
        } catch let apiError as ZabbixAPIError {
            error = apiError.localizedDescription
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    func logout() {
        guard authToken != nil else { return }

        Task {
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "user.logout",
                "params": [],
                "id": 1
            ]
            _ = try? await performRequest(payload: payload, useAuth: true) as ZabbixAPIResponse<Bool>
        }

        authToken = nil
        isAuthenticated = false
        problems = []
        hosts = []
        KeychainHelper.deleteToken(for: serverURL)
        stopAutoRefresh()
    }

    func refreshData() async {
        guard isAuthenticated else { return }

        isLoading = true
        error = nil

        do {
            async let problemsResult = fetchProblems()
            async let hostsResult = fetchHosts()

            let newProblems = try await problemsResult
            hosts = try await hostsResult
            problems = newProblems
            lastRefresh = Date()
            
            // Calculate severity counts for menu bar display
            var counts: [Int: Int] = [:]
            for problem in newProblems {
                let severity = Int(problem.severity) ?? 0
                counts[severity, default: 0] += 1
            }
            severityCounts = counts
            
            // Detect new problems for notifications
            detectNewProblems(newProblems)

            // Save to shared storage for widget
            saveDataForWidget()
        } catch let apiError as ZabbixAPIError {
            error = apiError.localizedDescription
            print("❌ ZabbixAPIError in refreshData: \(apiError)")
            // Token might be expired
            if apiError.code == -32602 || apiError.message.contains("Session") {
                isAuthenticated = false
                authToken = nil
                KeychainHelper.deleteToken(for: serverURL)
            }
        } catch {
            print("❌ Error in refreshData: \(error)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }
    
    // MARK: - Notification System
    
    /// Detect new problems and add them to notification buffer
    private func detectNewProblems(_ newProblems: [ZabbixProblem]) {
        let currentEventIds = Set(newProblems.map { $0.eventid })
        let newEventIds = currentEventIds.subtracting(previousProblems)
        
        // If there are new problems, add them to the buffer grouped by host
        if !newEventIds.isEmpty {
            for problem in newProblems where newEventIds.contains(problem.eventid) {
                notificationBuffer[problem.hostid, default: []].append(problem)
            }
            
            // Cancel any pending notification work
            notificationWorkItem?.cancel()
            
            // Schedule notification send after 10 seconds
            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor [weak self] in
                    self?.sendGroupedNotifications()
                }
            }
            notificationWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: workItem)
        }
        
        // Update previousProblems with current state
        previousProblems = currentEventIds
        
        // Save to UserDefaults for persistence
        if let data = try? JSONEncoder().encode(previousProblems) {
            UserDefaults.standard.set(data, forKey: "previous_problem_eventids")
        }
    }
    
    /// Send grouped notifications after 10-second delay
    private func sendGroupedNotifications() {
        guard !notificationBuffer.isEmpty else { return }
        
        for (hostid, problems) in notificationBuffer {
            // Get hostname from the first problem (they all have the same host)
            guard let hostname = problems.first?.hostname else { continue }
            
            // Group problems by severity
            var severityGroups: [Int: Int] = [:]
            for problem in problems {
                let severity = Int(problem.severity) ?? 0
                severityGroups[severity, default: 0] += 1
            }
            
            // Build notification content
            let content = UNMutableNotificationContent()
            content.sound = .default
            
            if problems.count == 1 {
                // Single problem
                let problem = problems[0]
                let severityName = problem.severityLevel.name
                content.title = "Zabbix Alert - \(hostname)"
                content.body = "\(severityName): \(problem.name)"
            } else {
                // Multiple problems
                content.title = "Zabbix Alert - \(hostname)"
                let severityText = severityGroups
                    .sorted { $0.key > $1.key }  // Sort by severity (highest first)
                    .map { "\(SeverityLevel(rawValue: $0.key)?.name ?? "Unknown") (\($0.value))" }
                    .joined(separator: ", ")
                content.body = "\(problems.count) new problems: \(severityText)"
            }
            
            // Add user info to open Zabbix when clicked
            content.userInfo = ["hostid": hostid, "serverURL": serverURL]
            
            // Send notification
            let request = UNNotificationRequest(
                identifier: "zabbix-\(hostid)-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil  // Send immediately
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Notification error: \(error)")
                }
            }
        }
        
        // Clear the buffer
        notificationBuffer.removeAll()
    }

    private func saveDataForWidget() {
        // Filter problems by widget severity filter
        let filteredProblems = problems.filter { problem in
            widgetSeverityFilter.includes(severity: Int(problem.severity) ?? 0)
        }

        // Convert to shared problems format
        let sharedProblems = filteredProblems.map { problem in
            SharedProblem(
                eventid: problem.eventid,
                name: problem.name,
                severity: Int(problem.severity) ?? 0,
                timestamp: problem.timestamp,
                isAcknowledged: problem.isAcknowledged
            )
        }

        // Create a signature from unique problem names + filter settings to detect new problems
        // Using names (not IDs) ensures we only regenerate AI summary when there's a genuinely new problem,
        // not when the same problem is re-reported with a new event ID
        let uniqueProblemNames = Set(filteredProblems.map { $0.name }).sorted().joined(separator: "|")
        let filterSignature = "\(widgetSeverityFilter.enabledLevels.sorted())"
        let currentSignature = "\(uniqueProblemNames)|\(filterSignature)"

        // Regenerate AI summary if problems or filter changed
        if currentSignature != lastProblemSignature {
            lastProblemSignature = currentSignature

            Task {
                await generateAISummary(for: Array(sharedProblems))
            }
        } else {
            // Still save data to update timestamp, but use existing AI summary
            // Count only unacknowledged problems from the filtered set
            let unacknowledgedCount = sharedProblems.filter { !$0.isAcknowledged }.count
            let sharedData = SharedZabbixData(
                problems: Array(sharedProblems),
                totalProblemCount: unacknowledgedCount,
                lastUpdate: lastRefresh ?? Date(),
                serverURL: serverURL,
                isAuthenticated: isAuthenticated,
                aiSummary: aiSummary,
                severityFilter: widgetSeverityFilter,
                widgetProblemCount: widgetProblemCount
            )
            SharedDataManager.shared.saveData(sharedData)
        }
    }

    private func generateAISummary(for problems: [SharedProblem]) async {
        // Use the filtered problems passed in (already filtered by widget severity)
        let sharedProblems = problems

        // If AI is disabled, clear the summary so widget shows raw problems
        if aiProvider == .disabled {
            aiSummary = ""
            // Count only unacknowledged problems that match the widget severity filter
            let unacknowledgedCount = sharedProblems.filter { !$0.isAcknowledged }.count
            let sharedData = SharedZabbixData(
                problems: Array(sharedProblems),
                totalProblemCount: unacknowledgedCount,
                lastUpdate: lastRefresh ?? Date(),
                serverURL: serverURL,
                isAuthenticated: isAuthenticated,
                aiSummary: "",
                severityFilter: widgetSeverityFilter,
                widgetProblemCount: widgetProblemCount
            )
            SharedDataManager.shared.saveData(sharedData)
            return
        }

        // If no problems, set a default message
        if problems.isEmpty {
            aiSummary = "All systems operational - no critical issues detected."
            let sharedData = SharedZabbixData(
                problems: [],
                totalProblemCount: 0,
                lastUpdate: lastRefresh ?? Date(),
                serverURL: serverURL,
                isAuthenticated: isAuthenticated,
                aiSummary: aiSummary,
                severityFilter: widgetSeverityFilter,
                widgetProblemCount: widgetProblemCount
            )
            SharedDataManager.shared.saveData(sharedData)
            return
        }

        // Build a list of all problem names for theme analysis
        let problemNames = problems.map { $0.name }

        // Group problems by severity for context
        var severityCounts: [String: Int] = [:]
        for p in problems {
            severityCounts[p.severityName, default: 0] += 1
        }
        let countSummary = severityCounts.map { "\($0.value) \($0.key)" }.joined(separator: ", ")

        // Send all problem names to the AI for theme detection
        let problemList = problemNames.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        // Build prompt: custom prompt + problem list + severity breakdown
        // Support legacy prompts with placeholders, or append data for new prompts
        var prompt = customAIPrompt

        // Check if prompt uses old placeholder format
        if prompt.contains("{PROBLEM_LIST}") {
            prompt = prompt
                .replacingOccurrences(of: "{PROBLEM_LIST}", with: problemList)
                .replacingOccurrences(of: "{SEVERITY_COUNTS}", with: countSummary)
                .replacingOccurrences(of: "{PROBLEM_COUNT}", with: "\(problems.count)")
        } else {
            // New format: append problem list and severity counts
            prompt = "\(prompt)\n\n\(problemList)\n\nSeverity breakdown: \(countSummary)"
        }

        do {
            let summary = try await callAIProvider(prompt: prompt)
            var trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            // Hard limit of 370 characters for UI display
            if trimmedSummary.count > 370 {
                trimmedSummary = String(trimmedSummary.prefix(367)) + "..."
            }
            aiSummary = trimmedSummary
        } catch {
            aiSummary = "Unable to generate summary"
        }

        // Always save shared data (with or without AI summary)
        // Count only unacknowledged problems from the filtered set
        let unacknowledgedCount = sharedProblems.filter { !$0.isAcknowledged }.count
        let sharedData = SharedZabbixData(
            problems: Array(sharedProblems),
            totalProblemCount: unacknowledgedCount,
            lastUpdate: lastRefresh ?? Date(),
            serverURL: serverURL,
            isAuthenticated: isAuthenticated,
            aiSummary: aiSummary,
            severityFilter: widgetSeverityFilter,
            widgetProblemCount: widgetProblemCount
        )
        SharedDataManager.shared.saveData(sharedData)
    }

    private func onAIProviderChanged() {
        // Reset the problem signature to force regeneration
        lastProblemSignature = ""

        // If AI is disabled, immediately clear the summary
        if aiProvider == .disabled {
            aiSummary = ""
        }

        // Trigger a widget data refresh with the new AI setting
        saveDataForWidget()
    }

    // MARK: - AI Provider Methods

    private func callAIProvider(prompt: String) async throws -> String {
        switch aiProvider {
        case .disabled:
            return ""
        case .ollama:
            return try await callOllama(prompt: prompt)
        case .openai:
            return try await callOpenAI(prompt: prompt)
        case .anthropic:
            return try await callAnthropic(prompt: prompt)
        }
    }

    private func callOllama(prompt: String) async throws -> String {
        guard let url = URL(string: "\(ollamaURL)/api/generate") else {
            throw NSError(domain: "OllamaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Ollama URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let ollamaRequest = OllamaRequest(model: ollamaModel, prompt: prompt, stream: false, options: OllamaOptions(num_predict: 80))
        request.httpBody = try JSONEncoder().encode(ollamaRequest)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OllamaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ollama request failed"])
        }

        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard !openAIAPIKey.isEmpty else {
            throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let openAIRequest = OpenAIRequest(
            model: openAIModel,
            messages: [OpenAIMessage(role: "user", content: prompt)],
            max_tokens: 80
        )
        request.httpBody = try JSONEncoder().encode(openAIRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI error: \(errorMessage)"])
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return openAIResponse.choices.first?.message.content ?? ""
    }

    private func callAnthropic(prompt: String) async throws -> String {
        guard !anthropicAPIKey.isEmpty else {
            throw NSError(domain: "AnthropicError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Anthropic API key not configured"])
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw NSError(domain: "AnthropicError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Anthropic URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let anthropicRequest = AnthropicRequest(
            model: anthropicModel,
            max_tokens: 80,
            messages: [AnthropicMessage(role: "user", content: prompt)]
        )
        request.httpBody = try JSONEncoder().encode(anthropicRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AnthropicError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AnthropicError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Anthropic error: \(errorMessage)"])
        }

        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return anthropicResponse.content.first?.text ?? ""
    }

    func testAIProvider() async -> (success: Bool, message: String) {
        let testPrompt = "Say 'Hello' in exactly one word."

        do {
            let response = try await callAIProvider(prompt: testPrompt)
            if response.isEmpty {
                return (false, "Empty response from AI provider")
            }
            return (true, "Connected successfully")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func fetchProblems() async throws -> [ZabbixProblem] {
        guard authToken != nil else { return [] }

        // Use trigger.get with filter for triggers currently in PROBLEM state (value=1)
        // This is more reliable than problem.get for getting current active problems
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "trigger.get",
            "params": [
                "output": ["triggerid", "description", "priority", "lastchange", "value"],
                "filter": [
                    "value": 1  // Only triggers currently in PROBLEM state
                ],
                "selectLastEvent": ["eventid", "acknowledged"],  // Get the actual event ID
                "selectHosts": ["hostid", "host", "name"],  // Get host info
                "sortfield": "lastchange",
                "sortorder": "DESC",
                "limit": 50,
                "skipDependent": true,
                "monitored": true,
                "active": true,
                "expandDescription": true
            ],
            "id": 2
        ]

        let response: ZabbixAPIResponse<[ZabbixTriggerWithEvent]> = try await performRequest(payload: payload, useAuth: true)

        if let triggers = response.result {
            // Convert triggers to problems format
            let problems = triggers.compactMap { trigger -> ZabbixProblem? in
                // Use the actual event ID from lastEvent, not the trigger ID
                guard let lastEvent = trigger.lastEvent else {
                    print("⚠️ Trigger \(trigger.triggerid) has no lastEvent")
                    return nil
                }
                
                // Check if hosts array exists and has at least one host
                guard let hosts = trigger.hosts, !hosts.isEmpty, let firstHost = hosts.first else {
                    print("⚠️ Trigger \(trigger.triggerid) has no hosts - description: \(trigger.description)")
                    return nil
                }

                return ZabbixProblem(
                    eventid: lastEvent.eventid,
                    objectid: trigger.triggerid,
                    name: trigger.description,
                    severity: trigger.priority,
                    clock: trigger.lastchange,
                    acknowledged: lastEvent.acknowledged,
                    hostid: firstHost.hostid,
                    hostname: firstHost.name
                )
            }
            print("✅ Successfully fetched \(problems.count) problems from \(triggers.count) triggers")
            return problems
        } else if let apiError = response.error {
            print("❌ Zabbix API Error: \(apiError.localizedDescription)")
            throw apiError
        }
        return []
    }

    private func fetchHosts() async throws -> [ZabbixHost] {
        guard authToken != nil else { return [] }

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "host.get",
            "params": [
                "output": ["hostid", "host", "name", "status"],
                "sortfield": "name"
            ],
            "id": 3
        ]

        let response: ZabbixAPIResponse<[ZabbixHost]> = try await performRequest(payload: payload, useAuth: true)

        if let hosts = response.result {
            return hosts
        } else if let apiError = response.error {
            throw apiError
        }
        return []
    }

    func acknowledgeProblem(eventId: String, message: String = "Acknowledged via ZabbixMenuBar") async throws {
        guard authToken != nil else { return }

        // Action flags: 1=close, 2=acknowledge, 4=message, 8=change severity
        // We want to acknowledge (2) and add message (4) = 6
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "event.acknowledge",
            "params": [
                "eventids": [eventId],  // Must be an array
                "action": 6,  // 2 (acknowledge) + 4 (message)
                "message": message
            ],
            "id": 4
        ]

        let response: ZabbixAPIResponse<AcknowledgeResult> = try await performRequest(payload: payload, useAuth: true)

        if let apiError = response.error {
            print("Zabbix API Error: \(apiError.localizedDescription)")
            throw apiError
        }

        if let result = response.result {
            print("Acknowledgment successful: \(result)")
        }

        print("Refreshing data after acknowledgment...")
        await refreshData()
        print("Data refreshed. New problem count: \(problems.count), Unacknowledged: \(problems.filter { !$0.isAcknowledged }.count)")
    }

    // MARK: - Network Helper

    private func performRequest<T: Decodable>(payload: [String: Any], useAuth: Bool = false) async throws -> T {
        guard let url = URL(string: serverURL) else {
            throw NSError(domain: "ZabbixAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json-rpc", forHTTPHeaderField: "Content-Type")
        // Disable caching at the request level
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        // Zabbix 6.4+ uses Authorization header instead of auth parameter in body
        if useAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ZabbixAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ZabbixAPIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Test Connection

    func testConnection() async -> (success: Bool, message: String) {
        do {
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "apiinfo.version",
                "params": [],
                "id": 1
            ]

            let response: ZabbixAPIResponse<String> = try await performRequest(payload: payload)

            if let version = response.result {
                return (true, "Connected to Zabbix API v\(version)")
            } else if let apiError = response.error {
                return (false, apiError.localizedDescription)
            }
            return (false, "Unknown error")
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
