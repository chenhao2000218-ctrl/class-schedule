import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 请求通知权限
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }

    // 注册桌面小组件数据通道
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.example.classSchedule/widget",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "updateWidgetData",
           let args = call.arguments as? [String: Any],
           let appGroup = args["appGroup"] as? String,
           let key = args["key"] as? String,
           let value = args["value"] as? String {
          // 写入 App Group UserDefaults
          if let defaults = UserDefaults(suiteName: appGroup) {
            defaults.set(value.data(using: .utf8), forKey: key)
            defaults.synchronize()
          }
          result(nil)
        } else if call.method == "reloadWidgets",
                  let args = call.arguments as? [String: Any],
                  let kind = args["kind"] as? String {
          // 刷新指定 kind 的小组件
          WidgetCenter.shared.reloadTimelines(ofKind: kind)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
