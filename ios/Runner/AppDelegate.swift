import AVFoundation
import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManageSubscriptions") {
      ManageSubscriptions.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ChatTts") {
      ChatTts.register(messenger: registrar.messenger())
    }
  }
}

/// Chat text-to-speech on the system voices. `speak` answers once the
/// utterance finished or was stopped - the Dart queue waits for it before
/// reading the next message. The audio session is playback (speaks with
/// the silent switch on) mixing with other apps and lowering them while a
/// message is read; it's released after each one so they return to full
/// volume between messages.
final class ChatTts: NSObject, AVSpeechSynthesizerDelegate {
  private static var shared: ChatTts?

  private let synthesizer = AVSpeechSynthesizer()
  private var pending: [ObjectIdentifier: FlutterResult] = [:]
  private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

  static func register(messenger: FlutterBinaryMessenger) {
    let tts = ChatTts()
    shared = tts
    let channel = FlutterMethodChannel(
      name: "com.kounex.obsBlade/tts",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in tts.handle(call, result) }
  }

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      guard let text = call.arguments as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(nil)
        return
      }
      activateSession()
      let utterance = AVSpeechUtterance(string: text)
      utterance.rate = rate
      pending[ObjectIdentifier(utterance)] = result
      synthesizer.speak(utterance)
    case "stop":
      synthesizer.stopSpeaking(at: .immediate)
      let results = pending.values
      pending.removeAll()
      results.forEach { $0(nil) }
      releaseSession()
      result(nil)
    case "setRate":
      /// Multiplier, 1.0 = the system default rate
      let multiplier = (call.arguments as? NSNumber)?.floatValue ?? 1.0
      rate = min(
        max(AVSpeechUtteranceDefaultSpeechRate * multiplier, AVSpeechUtteranceMinimumSpeechRate),
        AVSpeechUtteranceMaximumSpeechRate
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func activateSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playback,
      mode: .voicePrompt,
      options: [.mixWithOthers, .duckOthers]
    )
    try? session.setActive(true)
  }

  private func releaseSession() {
    try? AVAudioSession.sharedInstance().setActive(
      false,
      options: .notifyOthersOnDeactivation
    )
  }

  private func finish(_ utterance: AVSpeechUtterance) {
    pending.removeValue(forKey: ObjectIdentifier(utterance))?(nil)
    if pending.isEmpty && !synthesizer.isSpeaking { releaseSession() }
  }

  /// Flutter results must be answered on the main thread
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.finish(utterance) }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.finish(utterance) }
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
