import SwiftUI
import ServiceManagement
import UserNotifications

@main
struct ZabbixMenuBarApp: App {
    @StateObject private var zabbixClient = ZabbixAPIClient()
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var menuBarID = UUID()

    init() {
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
        
        // Ensure login item is registered with the correct app name
        registerLoginItem()
    }

    var body: some Scene {
        MenuBarExtra {
            ZabbixStatusView()
                .environmentObject(zabbixClient)
                .frame(width: 400, height: 500)
                .environment(\.colorScheme, .dark)
                .environment(\.locale, languageManager.effectiveLocale)
                .onChange(of: zabbixClient.severityCounts) {
                    // Force menu bar icon refresh when counts change
                    menuBarID = UUID()
                }
                .onChange(of: zabbixClient.problems.count) {
                    menuBarID = UUID()
                }
                .onChange(of: zabbixClient.hosts.count) {
                    menuBarID = UUID()
                }
        } label: {
            MenuBarStatusView(client: zabbixClient)
                .id(menuBarID)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(zabbixClient)
                .environment(\.locale, languageManager.effectiveLocale)
        }
    }
}

struct MenuBarStatusView: View {
    @ObservedObject var client: ZabbixAPIClient
    
    private var totalProblems: Int { client.problems.count }
    private var totalHosts: Int { client.hosts.count }
    private var severityCounts: [Int: Int] { client.severityCounts }
    private var hasError: Bool { client.error != nil }
    
    var body: some View {
        let _ = print("MenuBar update - Problems: \(totalProblems), Counts: \(severityCounts)")
        
        return Text(menuBarText)
            .font(.system(size: 12))
    }
    
    private var menuBarText: String {
        if hasError {
            return "⚠️"
        } else if totalProblems == 0 {
            return "✅ \(totalHosts)"
        } else {
            var text = ""
            // Disaster (5) - ⚫ black circle
            if let count = severityCounts[5], count > 0 {
                text += "⚫\(count) "
            }
            // High (4) - 🔴 red circle
            if let count = severityCounts[4], count > 0 {
                text += "🔴\(count) "
            }
            // Average (3) - 🟠 orange circle
            if let count = severityCounts[3], count > 0 {
                text += "🟠\(count) "
            }
            // Warning (2) - 🟡 yellow circle
            if let count = severityCounts[2], count > 0 {
                text += "🟡\(count) "
            }
            // Information (1) - 🔵 blue circle
            if let count = severityCounts[1], count > 0 {
                text += "🔵\(count) "
            }
            // Not classified (0) - ⚪ white circle
            if let count = severityCounts[0], count > 0 {
                text += "⚪\(count) "
            }
            return text.trimmingCharacters(in: .whitespaces)
        }
    }
    


}

// MARK: - Login Item Management

private func registerLoginItem() {
    // Check if there's a migration needed from old login item name
    let script = """
    tell application "System Events"
        set loginItemNames to name of every login item
        if loginItemNames contains "ZabbixMenuBar" then
            delete login item "ZabbixMenuBar"
        end if

        -- Check if current app is already registered
        if loginItemNames does not contain "Zabbix Monitor" then
            make login item at end with properties {path:"/Applications/Zabbix Monitor.app", hidden:false}
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(&error)
        if let error = error {
            print("Login item registration warning: \(error)")
        }
    }
}
