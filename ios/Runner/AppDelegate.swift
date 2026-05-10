import Flutter
import UIKit
import WidgetKit

/// Id App Group — musi być ten sam w Runner i w rozszerzeniu widgetu (Capabilities).
private let kAppGroupId = "group.com.worktimer.workTimer"

/// Zgodność z `TimerServiceBridge` / Android (MainActivity).
private enum WidgetDefaultsKey {
  static let selectedWorkspaceId = "wt_selectedWorkspaceId"
  static let selectedWorkspaceName = "wt_selectedWorkspaceName"
  static let runState = "wt_runState"
  static let startTimestampMs = "wt_startTimestampMs"
  static let elapsedSeconds = "wt_elapsedSeconds"
  static let pausedAccumulatedSeconds = "wt_pausedAccumulatedSeconds"
  static let resumeAtMs = "wt_resumeAtMs"
  static let lastUpdatedAtMs = "wt_lastUpdatedAtMs"
  static let workspacesJson = "wt_workspacesJson"
  static let nextSessionMode = "wt_nextSessionMode"

  /// Spójny zapis pod `getNativeTimerSnapshot` na iOS (Flutter hydrata głównie z cache).
  static let mirrorRunState = "wt_mirror_runState"
  static let mirrorElapsedSeconds = "wt_mirror_elapsedSeconds"
  static let mirrorWorkspaceId = "wt_mirror_workspaceId"
  static let mirrorWorkspaceName = "wt_mirror_workspaceName"
  static let mirrorSessionMode = "wt_mirror_sessionMode"
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var serviceChannel: FlutterMethodChannel?
  private var deeplinkChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    DispatchQueue.main.async { [weak self] in self?.wireChannels() }
    return ok
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    deeplinkChannel?.invokeMethod("onOpenUrl", arguments: url.absoluteString)
    return true
  }

  private func wireChannels() {
    guard serviceChannel == nil else { return }
    guard let controller = window?.rootViewController as? FlutterViewController else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.wireChannels() }
      return
    }

    let messenger = controller.binaryMessenger

    let service = FlutterMethodChannel(
      name: "work_timer/service_control",
      binaryMessenger: messenger
    )
    service.setMethodCallHandler { [weak self] call, result in
      self?.handleServiceCall(call: call, result: result)
    }
    serviceChannel = service

    let deeplink = FlutterMethodChannel(
      name: "work_timer/deeplink",
      binaryMessenger: messenger
    )
    deeplinkChannel = deeplink
  }

  private func handleServiceCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play", "pause", "stop":
      // Stan timera jest w Flutterze; Android uruchamia ForegroundService — na iOS nic.
      reloadTimelinesIfAvailable()
      result(true)

    case "sync":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }
      persistSyncPayload(args)
      reloadTimelinesIfAvailable()
      result(true)

    case "syncWidgetWorkspaces":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }
      let json = args["workspacesJson"] as? String ?? "[]"
      let selectedId = args["selectedWorkspaceId"] as? String ?? "default"
      persistWorkspacesJson(json, selectedId: selectedId)
      reloadTimelinesIfAvailable()
      result(true)

    case "getNativeTimerSnapshot":
      result(readMirrorSnapshot())

    case "getWidgetWorkspaceSelection":
      let defs = sharedDefaults()
      result([
        "activeWorkspaceId": defs?.string(forKey: WidgetDefaultsKey.selectedWorkspaceId) ?? "default",
        "workspaceName": defs?.string(forKey: WidgetDefaultsKey.selectedWorkspaceName) ?? "",
      ])

    case "reloadWidgets":
      reloadTimelinesIfAvailable()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: kAppGroupId)
  }

  private func persistSyncPayload(_ args: [String: Any]) {
    let defs = sharedDefaults()
    let runState = args["runState"] as? String ?? "idle"
    let elapsed = args["elapsedSeconds"] as? Int ?? 0
    let workspaceId = args["workspaceId"] as? String ?? "default"
    let workspaceName = args["workspaceName"] as? String ?? "Default"
    let nextMode = args["nextSessionMode"] as? String ?? "office"

    let sessionStartMs = int64(from: args, key: "sessionStartMs")
    let resumeAtMs = int64(from: args, key: "resumeAtMs")
    let pausedAccumulated = args["pausedAccumulatedSeconds"] as? Int ?? 0

    let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

    defs?.set(workspaceId, forKey: WidgetDefaultsKey.selectedWorkspaceId)
    defs?.set(workspaceName, forKey: WidgetDefaultsKey.selectedWorkspaceName)
    defs?.set(runState, forKey: WidgetDefaultsKey.runState)
    if let s = sessionStartMs {
      defs?.set(s, forKey: WidgetDefaultsKey.startTimestampMs)
    } else {
      defs?.removeObject(forKey: WidgetDefaultsKey.startTimestampMs)
    }
    defs?.set(elapsed, forKey: WidgetDefaultsKey.elapsedSeconds)
    defs?.set(pausedAccumulated, forKey: WidgetDefaultsKey.pausedAccumulatedSeconds)
    if let r = resumeAtMs {
      defs?.set(r, forKey: WidgetDefaultsKey.resumeAtMs)
    } else {
      defs?.removeObject(forKey: WidgetDefaultsKey.resumeAtMs)
    }
    defs?.set(nextMode, forKey: WidgetDefaultsKey.nextSessionMode)
    defs?.set(nowMs, forKey: WidgetDefaultsKey.lastUpdatedAtMs)

    defs?.set(runState, forKey: WidgetDefaultsKey.mirrorRunState)
    defs?.set(elapsed, forKey: WidgetDefaultsKey.mirrorElapsedSeconds)
    defs?.set(workspaceId, forKey: WidgetDefaultsKey.mirrorWorkspaceId)
    defs?.set(workspaceName, forKey: WidgetDefaultsKey.mirrorWorkspaceName)
    defs?.set(nextMode, forKey: WidgetDefaultsKey.mirrorSessionMode)
  }

  private func persistWorkspacesJson(_ json: String, selectedId: String) {
    let defs = sharedDefaults()
    defs?.set(json, forKey: WidgetDefaultsKey.workspacesJson)
    defs?.set(selectedId, forKey: WidgetDefaultsKey.selectedWorkspaceId)
    if let name = resolveWorkspaceName(json: json, id: selectedId) {
      defs?.set(name, forKey: WidgetDefaultsKey.selectedWorkspaceName)
    }
  }

  private func resolveWorkspaceName(json: String, id: String) -> String? {
    guard let data = json.data(using: .utf8),
          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return nil }
    for o in arr {
      if (o["id"] as? String) == id {
        return o["name"] as? String
      }
    }
    return nil
  }

  private func readMirrorSnapshot() -> [String: Any] {
    let defs = sharedDefaults()
    return [
      "runState": defs?.string(forKey: WidgetDefaultsKey.mirrorRunState) ?? "idle",
      "elapsedSeconds": defs?.integer(forKey: WidgetDefaultsKey.mirrorElapsedSeconds) ?? 0,
      "workspaceId": defs?.string(forKey: WidgetDefaultsKey.mirrorWorkspaceId) ?? "default",
      "workspaceName": defs?.string(forKey: WidgetDefaultsKey.mirrorWorkspaceName) ?? "",
      "sessionMode": defs?.string(forKey: WidgetDefaultsKey.mirrorSessionMode) ?? "office",
    ]
  }

  private func reloadTimelinesIfAvailable() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private func int64(from args: [String: Any], key: String) -> Int64? {
    if let v = args[key] as? Int64 { return v }
    if let v = args[key] as? Int { return Int64(v) }
    if let n = args[key] as? NSNumber { return n.int64Value }
    return nil
  }
}
