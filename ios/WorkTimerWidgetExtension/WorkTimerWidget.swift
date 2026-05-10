import SwiftUI
import WidgetKit

/// Musi być zgodne z `AppDelegate.swift` (Runner) — ta sama grupa App Group.
private let kAppGroupId = "group.com.worktimer.workTimer"

@available(iOS 14.0, *)
private enum WtKey {
  static let runState = "wt_runState"
  static let workspaceName = "wt_selectedWorkspaceName"
  static let workspaceId = "wt_selectedWorkspaceId"
  static let elapsedSeconds = "wt_elapsedSeconds"
  static let resumeAtMs = "wt_resumeAtMs"
  static let pausedAccumulatedSeconds = "wt_pausedAccumulatedSeconds"
}

@available(iOS 14.0, *)
struct WorkTimerEntry: TimelineEntry {
  let date: Date
  let runState: String
  let workspaceName: String
  let workspaceId: String
  let elapsedSeconds: Int
  let resumeAt: Date?
  let pausedAccumulatedSeconds: Int
}

@available(iOS 14.0, *)
struct WorkTimerTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> WorkTimerEntry {
    WorkTimerEntry(
      date: Date(),
      runState: "idle",
      workspaceName: "—",
      workspaceId: "default",
      elapsedSeconds: 0,
      resumeAt: nil,
      pausedAccumulatedSeconds: 0,
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (WorkTimerEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WorkTimerEntry>) -> Void) {
    let entry = loadEntry()
    let next: Date
    if entry.runState == "running" {
      next = Date().addingTimeInterval(15)
    } else {
      next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
    }
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> WorkTimerEntry {
    let defs = UserDefaults(suiteName: kAppGroupId)
    let runState = defs?.string(forKey: WtKey.runState) ?? "idle"
    let name = defs?.string(forKey: WtKey.workspaceName) ?? "—"
    let wid = defs?.string(forKey: WtKey.workspaceId) ?? "default"
    let elapsed = defs?.integer(forKey: WtKey.elapsedSeconds) ?? 0
    let resumeMs = readInt64(defs, WtKey.resumeAtMs)
    let resumeAt = resumeMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000.0) }
    let pausedAcc = defs?.integer(forKey: WtKey.pausedAccumulatedSeconds) ?? 0
    return WorkTimerEntry(
      date: Date(),
      runState: runState,
      workspaceName: name,
      workspaceId: wid,
      elapsedSeconds: elapsed,
      resumeAt: resumeAt,
      pausedAccumulatedSeconds: pausedAcc,
    )
  }

  private func readInt64(_ defs: UserDefaults?, _ key: String) -> Int64? {
    guard let defs else { return nil }
    if let n = defs.object(forKey: key) as? NSNumber {
      return n.int64Value
    }
    return nil
  }
}

@available(iOS 14.0, *)
struct WorkTimerWidgetEntryView: View {
  var entry: WorkTimerEntry

  private var displayTotalSeconds: Int {
    if entry.runState == "running", let r = entry.resumeAt {
      let extra = Int(Date().timeIntervalSince(r))
      return entry.pausedAccumulatedSeconds + max(0, extra)
    }
    return entry.elapsedSeconds
  }

  private var statusText: String {
    switch entry.runState {
    case "running":
      return "Running"
    case "paused":
      return "Paused"
    default:
      return "Idle"
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(entry.workspaceName)
        .font(.headline)
        .lineLimit(2)
        .widgetURL(URL(string: "worktimer://workspaces"))
      Text(statusText)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(formatHms(displayTotalSeconds))
        .font(.title2)
        .monospacedDigit()
    }
    .padding()
  }

  private func formatHms(_ total: Int) -> String {
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    return String(format: "%d:%02d:%02d", h, m, s)
  }
}

@available(iOS 14.0, *)
struct WorkTimerLiveWidget: Widget {
  let kind: String = "WorkTimerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WorkTimerTimelineProvider()) { entry in
      WorkTimerWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Work Timer")
    .description("Workspace i stan timera.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@available(iOS 14.0, *)
@main
struct WorkTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    WorkTimerLiveWidget()
  }
}
