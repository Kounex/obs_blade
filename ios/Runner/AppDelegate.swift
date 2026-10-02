import AVFoundation
import Flutter
import NaturalLanguage
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
/// the current message and answers `speak` with false until it's over
/// (or the session can't be activated) - the Dart queue keeps the message
/// and tries again, so nothing is read over a call.
///
/// Voice: the best installed one (premium > enhanced > default) for the
/// default language (the setting, else the phone's) - iOS alone would use
/// the "compact" voice. With detection on, a message clearly in another
/// language (3+ words or 12+ letters, 60%+ confidence) is read with that
/// language's best voice, preferring the phone's region; no voice for it,
/// or the default's own language → the default voice.
final class ChatTts: NSObject, AVSpeechSynthesizerDelegate {
  private static var shared: ChatTts?

  private let synthesizer = AVSpeechSynthesizer()
  private var pending: [ObjectIdentifier: FlutterResult] = [:]
  private var rate: Float = AVSpeechUtteranceDefaultSpeechRate

  /// 0 … 1, relative to the device volume
  private var volume: Float = 1.0

  /// Best voice per language code, rebuilt when the installed voices change
  private var bestVoices: [String: AVSpeechSynthesisVoice?] = [:]

  /// BCP 47 tag from the settings, nil = the phone's language
  private var defaultLanguage: String?
  private var detect = false

  /// An audio interruption began and hasn't ended - `speak` answers false
  private var interrupted = false

  /// The app went to the background during the interruption - its "ended"
  /// may never arrive then, coming back clears it
  private var backgroundedWhileInterrupted = false

  /// The user's voice per language (tag → identifier); a missing or
  /// uninstalled pick means the automatic best voice
  private var voicePicks: [String: String] = [:]

  private var fallbackLanguage: String {
    defaultLanguage ?? AVSpeechSynthesisVoice.currentLanguageCode()
  }

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
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
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
      let args = call.arguments as? [String: Any]
      guard let text = args?["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(nil)
        return
      }
      /// The audio is taken - the Dart queue keeps the message
      guard !interrupted, activateSession() else {
        result(false)
        return
      }
      let utterance = AVSpeechUtterance(string: text)
      utterance.rate = rate
      utterance.volume = volume
      if let voice = voice(for: (args?["detectionText"] as? String) ?? text) {
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
    case "setVolume":
      let value = (call.arguments as? NSNumber)?.floatValue ?? 1.0
      volume = min(max(value, 0.0), 1.0)
      result(nil)
    case "setLanguage":
      let args = call.arguments as? [String: Any]
      defaultLanguage = args?["language"] as? String
      detect = (args?["detect"] as? Bool) ?? false
      voicePicks = (args?["voices"] as? [String: String]) ?? [:]
      bestVoices.removeAll()
      result(nil)
    case "preview":
      /// A short sample with one voice - interrupts whatever is read
      let args = call.arguments as? [String: Any]
      guard let text = args?["text"] as? String else {
        result(nil)
        return
      }
      stopAll()
      guard !interrupted, activateSession() else {
        result(nil)
        return
      }
      let utterance = AVSpeechUtterance(string: text)
      utterance.rate = rate
      utterance.volume = volume
      if let id = args?["voiceId"] as? String,
        let voice = AVSpeechSynthesisVoice(identifier: id)
      {
        utterance.voice = voice
      } else if let language = args?["language"] as? String,
        let voice = bestVoice(for: language)
      {
        utterance.voice = voice
      }
      pending[ObjectIdentifier(utterance)] = result
      synthesizer.speak(utterance)
    case "voices":
      listVoices(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// [answer]: what the stopped `speak` calls get - false = cut off by an
  /// interruption, read it again later
  private func stopAll(answer: Any? = nil) {
    let results = pending.values
    pending.removeAll()
    synthesizer.stopSpeaking(at: .immediate)
    results.forEach { $0(answer) }
    releaseSession()
  }

  /// The system's voice list is expensive to read (every call rebuilds
  /// it) - read once, refreshed when the installed voices change
  private var usableCache: [AVSpeechSynthesisVoice]?

  /// Voices that read chat sensibly - no novelty ("Bad News", "Bells")
  /// and no Personal Voice (needs its own authorization)
  private static func loadUsableVoices() -> [AVSpeechSynthesisVoice] {
    AVSpeechSynthesisVoice.speechVoices().filter { voice in
      if #available(iOS 17.0, *) {
        return !voice.voiceTraits.contains(.isNoveltyVoice)
          && !voice.voiceTraits.contains(.isPersonalVoice)
      }
      return true
    }
  }

  private func usableVoices() -> [AVSpeechSynthesisVoice] {
    if let cached = usableCache { return cached }
    let voices = ChatTts.loadUsableVoices()
    usableCache = voices
    return voices
  }

  /// The user's pick for [language] when it's installed, else the best of
  /// [voices] - premium (3) > enhanced (2) > default (1), raw values so it
  /// also compiles against iOS 15. A pick for another region of the
  /// language only counts when [language] has no voices of its own (a
  /// detected `es`, a default region without voices) - the picker shows
  /// one row per installed region, so that's the pick it shows. Several of
  /// them: the first by tag, never dictionary order. Pure: runs off the
  /// main thread too
  private static func best(
    for language: String,
    in voices: [AVSpeechSynthesisVoice],
    picks: [String: String]
  ) -> AVSpeechSynthesisVoice? {
    let exact = voices.filter { $0.language == language }
    let pickId = picks[language]
      ?? (exact.isEmpty
        ? picks.keys.sorted().first { baseCode($0) == baseCode(language) }.flatMap { picks[$0] }
        : nil)
    if let id = pickId, let picked = voices.first(where: { $0.identifier == id }) {
      return picked
    }
    let prefix = language.split(separator: "-").first.map(String.init) ?? language
    let candidates = exact.isEmpty
      ? voices.filter { $0.language.hasPrefix(prefix + "-") }
      : exact
    return candidates.max { rank($0) < rank($1) }
  }

  private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
    if let cached = bestVoices[language] { return cached }
    let best = ChatTts.best(for: language, in: usableVoices(), picks: voicePicks)
    bestVoices[language] = best
    return best
  }

  /// Quality first; on a tie (most phones only have compact voices) Siri's
  /// voices > Apple's regular ones > Eloquence (Eddy, Grandpa, … - robotic,
  /// yet not flagged as novelty)
  private static func rank(_ voice: AVSpeechSynthesisVoice) -> (Int, Int) {
    let id = voice.identifier.lowercased()
    let family = id.contains("siri") ? 2 : id.contains("eloquence") ? 0 : 1
    return (voice.quality.rawValue, family)
  }

  private static func baseCode(_ language: String) -> String {
    (language.split(separator: "-").first.map(String.init) ?? language).lowercased()
  }

  /// The voice for one message: the default language's best voice, or -
  /// with detection on - the detected language's when it's a different
  /// language and installed
  private func voice(for text: String) -> AVSpeechSynthesisVoice? {
    let fallback = bestVoice(for: fallbackLanguage)
    guard detect, let detected = detectLanguage(text),
      ChatTts.baseCode(detected) != ChatTts.baseCode(fallbackLanguage)
    else { return fallback }
    return bestVoice(forDetected: detected) ?? fallback
  }

  /// Language code of [text] when it's long and clear enough - chat lines
  /// are short, guessing on "lol" would switch voices at random
  private func detectLanguage(_ text: String) -> String? {
    let words = text.split(whereSeparator: { $0.isWhitespace }).count
    let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
    guard words >= 3 || letters >= 12 else { return nil }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    guard let (language, confidence) = recognizer.languageHypotheses(withMaximum: 1).first,
      confidence >= 0.6
    else { return nil }
    return language.rawValue
  }

  /// Best voice for a detected language (`es`, `zh-Hans`, …): the phone's
  /// region first (`es-` + region), then any region by quality
  private func bestVoice(forDetected detected: String) -> AVSpeechSynthesisVoice? {
    let mapped = ["zh-Hans": "zh-CN", "zh-Hant": "zh-TW"][detected] ?? detected
    if mapped.contains("-") { return bestVoice(for: mapped) }
    if let region = Locale.current.regionCode {
      let regional = "\(mapped)-\(region)"
      if usableVoices().contains(where: { $0.language == regional }) {
        return bestVoice(for: regional)
      }
    }
    return bestVoice(for: mapped)
  }

  /// One entry per installed voice: identifier, name, language (BCP 47),
  /// the language's name in the phone's language, quality, whether it's
  /// the one this bridge reads that language with, and whether it reads
  /// the default language. Built on a background queue (the system list
  /// takes a while), answered on main - the Dart side drops an answer
  /// that a newer request overtook
  private func listVoices(_ result: @escaping FlutterResult) {
    let picks = voicePicks
    let defaultTag = fallbackLanguage
    DispatchQueue.global(qos: .userInitiated).async {
      let voices = ChatTts.loadUsableVoices()
      let defaultId = ChatTts.best(for: defaultTag, in: voices, picks: picks)?.identifier
      /// Language → identifier of its voice ("" = none), resolved once each
      var bestByLanguage: [String: String] = [:]
      var names: [String: String] = [:]
      let list: [[String: Any]] = voices.map { voice in
        let language = voice.language
        if bestByLanguage[language] == nil {
          bestByLanguage[language] =
            ChatTts.best(for: language, in: voices, picks: picks)?.identifier ?? ""
        }
        if names[language] == nil {
          names[language] = Locale.current.localizedString(forIdentifier: language)
            ?? language
        }
        return [
          "id": voice.identifier,
          "name": voice.name,
          "language": language,
          "languageName": names[language] ?? language,
          "quality": voice.quality.rawValue,
          "preferred": bestByLanguage[language] == voice.identifier,
          "default": voice.identifier == defaultId,
        ]
      }
      DispatchQueue.main.async {
        self.usableCache = voices
        self.bestVoices.removeAll()
        result(list)
      }
    }
  }

  @objc private func voicesChanged() {
    DispatchQueue.main.async {
      self.usableCache = nil
      self.bestVoices.removeAll()
    }
  }

  @objc private func audioInterrupted(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: raw)
    else { return }
    DispatchQueue.main.async {
      switch type {
      case .began:
        /// Also posted for a session that wasn't active (another app's
        /// audio) - only a real interruption blocks reading
        if #available(iOS 14.5, *),
          let reasonRaw = notification.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt,
          AVAudioSession.InterruptionReason(rawValue: reasonRaw) == .appWasSuspended
        {
          return
        }
        self.interrupted = true
        self.backgroundedWhileInterrupted = false
        self.stopAll(answer: false)
      case .ended:
        self.interrupted = false
      @unknown default:
        break
      }
    }
  }

  @objc private func didEnterBackground() {
    if interrupted { backgroundedWhileInterrupted = true }
  }

  @objc private func didBecomeActive() {
    if backgroundedWhileInterrupted {
      backgroundedWhileInterrupted = false
      interrupted = false
    }
  }

  /// False when the session can't be activated (the audio is taken)
  private func activateSession() -> Bool {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playback,
      mode: .voicePrompt,
      options: [.mixWithOthers, .duckOthers]
    )
    do {
      try session.setActive(true)
      return true
    } catch {
      return false
    }
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
