import WidgetKit
import SwiftUI

// MARK: - Widget Language Helper

/// Reads the user's language preference from shared UserDefaults
/// This allows the widget to respect the app's language setting
struct WidgetLanguageHelper {
    private static let languageKey = "app_language"

    static var effectiveLocale: Locale {
        guard let defaults = UserDefaults(suiteName: userDefaultsSuite),
              let savedLanguage = defaults.string(forKey: languageKey),
              let language = AppLanguage(rawValue: savedLanguage),
              let locale = language.locale else {
            return Locale.current
        }
        return locale
    }
}

// MARK: - Timeline Provider

struct ZabbixProvider: TimelineProvider {
    func placeholder(in context: Context) -> ZabbixEntry {
        ZabbixEntry(date: Date(), problemCount: 0, problems: [], aiSummary: "", isConfigured: true, widgetProblemCount: 6)
    }

    func getSnapshot(in context: Context, completion: @escaping (ZabbixEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZabbixEntry>) -> Void) {
        let entry = loadEntry()

        // Refresh every 5 minutes to reduce battery usage
        // The menu bar app triggers reloadAllTimelines() when data changes,
        // so the widget will still update promptly when problems change
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> ZabbixEntry {
        // Try to load from shared data
        let data = SharedDataManager.shared.loadData()
        let hasData = !data.serverURL.isEmpty

        if hasData {
            // Filter problems based on user's severity filter settings
            let filteredProblems = data.problems.filter { data.severityFilter.includes(severity: $0.severity) }

            // Sort by severity (highest first), then by timestamp (most recent first)
            let sortedProblems = filteredProblems.sorted { a, b in
                if a.severity != b.severity {
                    return a.severity > b.severity
                }
                return a.timestamp > b.timestamp
            }

            let problems = sortedProblems.map { p in
                WidgetProblem(id: p.eventid, name: p.name, severity: p.severity, timestamp: p.timestamp)
            }
            return ZabbixEntry(
                date: Date(),
                problemCount: data.totalProblemCount,  // Use the total count from shared data
                problems: problems,
                aiSummary: data.aiSummary,
                // Honour the real auth state so an expired Zabbix session surfaces
                // as "open the app" rather than silently frozen data.
                isConfigured: data.isAuthenticated,
                widgetProblemCount: data.widgetProblemCount
            )
        }

        // If no shared data, show "All Clear" as default (widget is working)
        // This helps debug - if you see "All Clear", widget works but data sharing doesn't
        return ZabbixEntry(
            date: Date(),
            problemCount: 0,
            problems: [],
            aiSummary: "",
            isConfigured: true,  // Always show as configured so we can see widget content
            widgetProblemCount: 6
        )
    }
}

// MARK: - Simple Problem struct for widget

struct WidgetProblem: Identifiable {
    let id: String
    let name: String
    let severity: Int
    let timestamp: Date

    var color: Color {
        switch severity {
        case 5: return .purple
        case 4: return .red
        case 3: return .orange
        case 2: return Color(red: 0.8, green: 0.6, blue: 0.0)  // Darker yellow/gold for better contrast
        case 1: return .blue
        default: return .gray
        }
    }

    var severityIcon: String {
        switch severity {
        case 5: return "exclamationmark.octagon.fill"  // Disaster
        case 4: return "exclamationmark.triangle.fill" // High
        case 3: return "exclamationmark.circle.fill"   // Average
        case 2: return "info.circle.fill"              // Warning
        case 1: return "info.circle"                   // Information
        default: return "questionmark.circle"          // Not Classified
        }
    }
}

// MARK: - Timeline Entry

struct ZabbixEntry: TimelineEntry {
    let date: Date
    let problemCount: Int
    let problems: [WidgetProblem]
    let aiSummary: String
    let isConfigured: Bool
    let widgetProblemCount: Int
}

// MARK: - Widget View

struct ZabbixWidgetEntryView: View {
    var entry: ZabbixEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                smallView
            }
        }
        .containerBackground(Color(nsColor: .windowBackgroundColor), for: .widget)
    }

    // MARK: - Small Widget

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZabbixIconView()
                Text("widget.zabbix")
                    .font(.headline)
            }

            Spacer()

            if !entry.isConfigured {
                VStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("widget.openAppToSetup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else if entry.problemCount == 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("status.allClear")
                        .font(.title3)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.problemCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(maxSeverityColor)
                    Text(entry.problemCount == 1 ? "widget.problem" : "widget.problems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Medium Widget

    var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                // Icon only - the title is dropped here so the summary column
                // on the right gets the width instead.
                ZabbixIconView()

                Spacer()

                if !entry.isConfigured {
                    Text("widget.openAppToSetup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if entry.problemCount == 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("status.allClear")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.problemCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(maxSeverityColor)
                        Text(entry.problemCount == 1 ? "widget.problem" : "widget.problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if entry.isConfigured && entry.problemCount > 0 {
                Divider()

                if !entry.aiSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("widget.aiSummary")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(verbatim: entry.aiSummary)
                            .font(.caption2)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    // Show problem list when AI is disabled
                    VStack(alignment: .leading, spacing: 4) {
                        Text("widget.activeProblems")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        ForEach(entry.problems.prefix(3)) { problem in
                            HStack(alignment: .top, spacing: 4) {
                                Circle()
                                    .fill(problem.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 4)
                                Text(verbatim: problem.name)
                                    .font(.caption2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else if entry.isConfigured && entry.problemCount == 0 {
                // All clear state for medium widget - no AI Summary heading
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("widget.allSystemsOperational")
                        .font(.caption2)
                    Text("widget.noProblemsDetected")
                        .font(.caption2)
                }
            }
        }
        .padding()
    }

    // MARK: - Large Widget

    var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZabbixIconView()
                Text("widget.zabbixMonitor")
                    .font(.headline)

                Spacer()

                if entry.isConfigured {
                    if entry.problemCount == 0 {
                        Label {
                            Text("status.allClear")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    } else {
                        Text("\(entry.problemCount) \(entry.problemCount == 1 ? String(localized: "widget.problem") : String(localized: "widget.problems"))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(maxSeverityColor.opacity(0.2))
                            .foregroundColor(maxSeverityColor)
                            .cornerRadius(8)
                    }
                }
            }

            Divider()

            if !entry.isConfigured {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gear")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("widget.openAppToSetup")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                if entry.problemCount == 0 {
                    // No problems - show large green check mark badge
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                            VStack(spacing: 4) {
                                Text("widget.allSystemsOperational")
                                    .font(.headline)
                                Text("widget.noProblemsDetected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    // Has problems - show AI summary if available, then problem list
                    if !entry.aiSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("widget.aiSummary")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Text(verbatim: entry.aiSummary)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                    }

                    // Show top problems sorted by severity (highest first), then by time (latest first)
                    // Show 6 when AI is disabled, 3 when AI summary is present
                    VStack(alignment: .leading, spacing: 6) {
                        Text("widget.topProblems")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        let sortedProblems = entry.problems.sorted { first, second in
                            if first.severity != second.severity {
                                return first.severity > second.severity
                            }
                            return first.timestamp > second.timestamp
                        }

                        let problemLimit = entry.aiSummary.isEmpty ? entry.widgetProblemCount : 3

                        ForEach(sortedProblems.prefix(problemLimit)) { problem in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: problem.severityIcon)
                                    .font(.system(size: 12))
                                    .foregroundColor(problem.color)
                                    .frame(width: 14)
                                    .padding(.top, 2)
                                Text(verbatim: problem.name)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }

                        if entry.problems.count > problemLimit {
                            Text(verbatim: "+ \(entry.problems.count - problemLimit) \(String(localized: "widget.more"))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding()
    }

    var maxSeverityColor: Color {
        // Find the highest severity problem and return its color
        guard let maxSeverity = entry.problems.map({ $0.severity }).max() else {
            return .blue
        }
        switch maxSeverity {
        case 5: return .purple
        case 4: return .red
        case 3: return .orange
        case 2: return Color(red: 0.8, green: 0.6, blue: 0.0)  // Darker yellow/gold for better contrast
        case 1: return .blue
        default: return .gray
        }
    }
}

// MARK: - Widget Configuration

struct ZabbixWidget: Widget {
    let kind: String = "ZabbixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZabbixProvider()) { entry in
            ZabbixWidgetEntryView(entry: entry)
                .environment(\.locale, WidgetLanguageHelper.effectiveLocale)
        }
        .configurationDisplayName(Text("widget.configName"))
        .description(Text("widget.configDescription"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ZabbixWidget()
} timeline: {
    ZabbixEntry(date: Date(), problemCount: 3, problems: [
        WidgetProblem(id: "1", name: "High CPU usage", severity: 4, timestamp: Date()),
        WidgetProblem(id: "2", name: "Disk space low", severity: 3, timestamp: Date().addingTimeInterval(-60)),
        WidgetProblem(id: "3", name: "Memory warning", severity: 2, timestamp: Date().addingTimeInterval(-120))
    ], aiSummary: "Server performance degraded - check CPU load and disk space on primary servers.", isConfigured: true, widgetProblemCount: 6)
}
