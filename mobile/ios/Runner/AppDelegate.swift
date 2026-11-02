import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // With the UIScene lifecycle the window and engine don't exist yet in
  // didFinishLaunching, so plugins and channels are registered here instead.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "am.sure.mobile/widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      WidgetBridge.handle(call, result: result)
    }
  }
}

/// Writes the files the home screen widget reads from the shared App Group.
/// Keep the group-name lookup in sync with SureWidgetStore in the widget target.
enum WidgetBridge {
  private static let baseGroup = "group.com.google.ios.youtube"
  private static let originalAppBundleID = "com.google.ios.youtube"
  private static let configFile = "sure-widget-config.json"
  private static let snapshotFile = "sure-widget-snapshot.json"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(containerURL() != nil)

    case "update":
      guard let args = call.arguments as? [String: Any], let dir = containerURL() else {
        result(false)
        return
      }
      if let config = args["config"] {
        write(config, to: dir.appendingPathComponent(configFile))
      }
      if let snapshot = args["snapshot"] {
        write(snapshot, to: dir.appendingPathComponent(snapshotFile))
      }
      WidgetCenter.shared.reloadAllTimelines()
      result(true)

    case "clear":
      if let dir = containerURL() {
        for name in [configFile, snapshotFile] {
          try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
        }
      }
      WidgetCenter.shared.reloadAllTimelines()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func write(_ object: Any, to url: URL) {
    guard JSONSerialization.isValidJSONObject(object),
          let data = try? JSONSerialization.data(withJSONObject: object) else { return }
    try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  /// Sideloading tools rename the App Group when re-signing, so try each likely
  /// name and use the one the system granted.
  static func containerURL() -> URL? {
    var groups: [String] = []
    let info = Bundle.main.infoDictionary ?? [:]
    if let alt = info["ALTAppGroups"] as? [String] { groups += alt }
    if let configured = info["SureAppGroup"] as? String { groups.append(configured) }
    groups.append(baseGroup)

    let appID = Bundle.main.bundleIdentifier ?? originalAppBundleID
    if appID.hasPrefix(originalAppBundleID + ".") {
      groups.append(baseGroup + appID.dropFirst(originalAppBundleID.count))
    }
    groups.append("group." + appID)

    for group in groups {
      if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
        return url
      }
    }
    return nil
  }
}
