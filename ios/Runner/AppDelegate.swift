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
/// volume between messages. An audio interruption (phone call, Siri) stops
/// the current message so the queue never waits on it.
///
/// Voice: the best installed one (premium > enhanced > default) for the
/// phone's language - iOS alone would use the default ("compact") voice.
final class ChatTts: NSObject, AVSpeechSynthesizerDelegate {
  private static var shared: ChatTts?

  private let synthesizer = AVSpeechSynthesizer()
  private var pending: [ObjectIdentifier: FlutterResult] = [:]
  private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

  /// Best voice per language code, rebuilt when the installed voices change
  private var bestVoices: [String: AVSpeechSynthesisVoice?] = [:]

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
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(audioInterrupted(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
    if #available(iOS 17.0, *) {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(voicesChanged),
        name: AVSpeechSynthesizer.availableVoicesDidChangeNotification,
        object: nil
      )
    }
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
      if let voice = bestVoice(for: AVSpeechSynthesisVoice.currentLanguageCode()) {
        utterance.voice = voice
      }
      pending[ObjectIdentifier(utterance)] = result
      synthesizer.speak(utterance)
    case "stop":
      stopAll()
      result(nil)
    case "setRate":
      /// Multiplier, 1.0 = the system default rate
      let multiplier = (call.arguments as? NSNumber)?.floatValue ?? 1.0
      rate = min(
        max(AVSpeechUtteranceDefaultSpeechRate * multiplier, AVSpeechUtteranceMinimumSpeechRate),
        AVSpeechUtteranceMaximumSpeechRate
      )
      result(nil)
    case "voices":
      result(installedVoices())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func stopAll() {
    synthesizer.stopSpeaking(at: .immediate)
    let results = pending.values
    pending.removeAll()
    results.forEach { $0(nil) }
    releaseSession()
  }

  /// Voices that read chat sensibly - no novelty ("Bad News", "Bells")
  /// and no Personal Voice (needs its own authorization)
  private func usableVoices() -> [AVSpeechSynthesisVoice] {
    AVSpeechSynthesisVoice.speechVoices().filter { voice in
      if #available(iOS 17.0, *) {
        return !voice.voiceTraits.contains(.isNoveltyVoice)
          && !voice.voiceTraits.contains(.isPersonalVoice)
      }
      return true
    }
  }

  /// premium (3) > enhanced (2) > default (1) - raw values, so it also
  /// compiles against iOS 15 where `.premium` doesn't exist yet
  private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
    if let cached = bestVoices[language] { return cached }
    let voices = usableVoices()
    let exact = voices.filter { $0.language == language }
    let prefix = language.split(separator: "-").first.map(String.init) ?? language
    let candidates = exact.isEmpty
      ? voices.filter { $0.language.hasPrefix(prefix + "-") }
      : exact
    let best = candidates.max { $0.quality.rawValue < $1.quality.rawValue }
    bestVoices[language] = best
    return best
  }

  /// One entry per installed voice: identifier, name, language (BCP 47),
  /// the language's name in the phone's language, quality
  private func installedVoices() -> [[String: Any]] {
    usableVoices().map { voice in
      [
        "id": voice.identifier,
        "name": voice.name,
        "language": voice.language,
        "languageName": Locale.current.localizedString(forIdentifier: voice.language)
          ?? voice.language,
        "quality": voice.quality.rawValue,
      ]
    }
  }

  @objc private func voicesChanged() {
    DispatchQueue.main.async { self.bestVoices.removeAll() }
  }

  @objc private func audioInterrupted(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      AVAudioSession.InterruptionType(rawValue: raw) == .began
    else { return }
    DispatchQueue.main.async { self.stopAll() }
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
