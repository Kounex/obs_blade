import UIKit
import Flutter
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManageSubscriptions") {
      ManageSubscriptions.register(messenger: registrar.messenger())
    }
  }
}

/// StoreKit's in-app manage-subscriptions sheet - unlike the App Store web
/// page it also lists sandbox / TestFlight subscriptions. Answers true once
/// the sheet was shown and dismissed, false when it can't show (the Dart
/// side falls back to the web page then)
enum ManageSubscriptions {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.kounex.obsBlade/subscriptions",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "showManageSubscriptions" else {
        result(FlutterMethodNotImplemented)
        return
      }

      /// Not supported for the iPad app on Apple silicon Macs
      if ProcessInfo.processInfo.isiOSAppOnMac {
        result(false)
        return
      }
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive })
      else {
        result(false)
        return
      }
      Task { @MainActor in
        do {
          try await AppStore.showManageSubscriptions(in: scene)
          result(true)
        } catch {
          result(false)
        }
      }
    }
  }
}
