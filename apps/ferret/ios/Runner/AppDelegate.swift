import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // A notice button that doesn't open the app runs in a background engine
    // that only needs the notification plugin: it hands the tap to the app.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      if let registrar = registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin") {
        FlutterLocalNotificationsPlugin.register(with: registrar)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FerretShortcuts") {
      ShortcutsBridge.shared.attach(messenger: registrar.messenger())
    }
  }
}
