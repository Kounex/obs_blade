package com.kounex.obsBlade

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.view.textclassifier.TextClassificationManager
import android.view.textclassifier.TextLanguage
import java.util.Locale
import java.util.concurrent.Executors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private var chatTts: ChatTts? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    chatTts = ChatTts(
      this,
      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kounex.obsBlade/tts"),
    )
  }

  override fun onDestroy() {
    chatTts?.shutdown()
    chatTts = null
    super.onDestroy()
  }
}

/**
 * Chat text-to-speech on the system engine. `speak` answers once the
 * utterance finished, was stopped or failed - the Dart queue waits for it
 * before reading the next message. Speaking before the engine is ready
 * waits for its init; an engine that failed to init answers right away.
 *
 * While a message is read, other apps' audio is lowered (transient audio
 * focus, "may duck") and gets it back afterwards. A failing `speak` (the
 * engine service died, e.g. updated in the background) restarts the
 * engine and retries that message once.
 *
 * Voice: the default language's best installed voice (offline first), or
 * the system TTS settings' voice when no language is set. With detection
 * on (Android 10+, on-device TextClassifier), a message clearly in another
 * language (3+ words or 12+ letters, 60%+ confidence) is read with that
 * language's best voice, preferring the phone's region; none installed,
 * or the default's own language → the default voice.
 */
class ChatTts(context: Context, channel: MethodChannel) : MethodChannel.MethodCallHandler {
  private val appContext = context.applicationContext
  private val main = Handler(Looper.getMainLooper())
  private val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  private val audioAttributes = AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_ASSISTANT)
    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
    .build()
  private var focusRequest: AudioFocusRequest? = null
  private var engine: TextToSpeech? = null
  private var initDone = false
  private var ready = false
  private val afterInit = mutableListOf<() -> Unit>()
  private val pending = HashMap<String, MethodChannel.Result>()
  private var rate = 1.0f

  /** 0 … 1, relative to the device volume */
  private var volume = 1.0f
  private var nextId = 0

  /** BCP 47 tag from the settings, null = the system TTS settings' voice */
  private var defaultLanguage: String? = null
  private var detect = false

  /** The user's voice per language (tag → voice name); missing / uninstalled = automatic */
  private var voicePicks: Map<String, String> = emptyMap()

  /** One-off voice for the next `speak` (a preview) */
  private var previewVoice: String? = null
  private var previewLanguage: String? = null

  private fun startSettings(intent: Intent): Boolean = try {
    appContext.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    true
  } catch (e: Exception) {
    false
  }

  /** Language detection blocks - never on the main thread */
  private val detector = Executors.newSingleThreadExecutor()

  private val listener = object : UtteranceProgressListener() {
    override fun onStart(utteranceId: String?) {}

    override fun onDone(utteranceId: String?) = finish(utteranceId)

    @Deprecated("Deprecated in Java")
    override fun onError(utteranceId: String?) = finish(utteranceId)

    override fun onError(utteranceId: String?, errorCode: Int) = finish(utteranceId)

    override fun onStop(utteranceId: String?, interrupted: Boolean) = finish(utteranceId)
  }

  init {
    channel.setMethodCallHandler(this)
    createEngine()
  }

  /** Bumped per engine - a replaced engine's late init callback is ignored */
  private var engineGeneration = 0

  private fun createEngine() {
    initDone = false
    ready = false
    engine?.shutdown()
    val generation = ++engineGeneration
    installedCache = null
    engine = TextToSpeech(appContext) { status ->
      main.post {
        if (generation != engineGeneration) return@post
        initDone = true
        ready = status == TextToSpeech.SUCCESS
        if (ready) {
          engine?.setOnUtteranceProgressListener(listener)
          engine?.setAudioAttributes(audioAttributes)
        }
        val queued = afterInit.toList()
        afterInit.clear()
        queued.forEach { it() }
      }
    }
  }

  private fun whenInitialized(action: () -> Unit) {
    if (initDone) action() else afterInit.add(action)
  }

  private fun finish(utteranceId: String?) {
    if (utteranceId == null) return
    main.post {
      pending.remove(utteranceId)?.success(null)
      if (pending.isEmpty()) releaseFocus()
    }
  }

  private fun finishAll() {
    val results = pending.values.toList()
    pending.clear()
    results.forEach { it.success(null) }
    releaseFocus()
  }

  private fun requestFocus() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val request = focusRequest ?: AudioFocusRequest
        .Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(audioAttributes)
        .setOnAudioFocusChangeListener { }
        .build()
        .also { focusRequest = it }
      audioManager.requestAudioFocus(request)
    } else {
      @Suppress("DEPRECATION")
      audioManager.requestAudioFocus(
        null,
        AudioManager.STREAM_MUSIC,
        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
      )
    }
  }

  private fun releaseFocus() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
    } else {
      @Suppress("DEPRECATION")
      audioManager.abandonAudioFocus(null)
    }
  }

  /** Detects (off the main thread when on) and then speaks */
  private fun speakDetecting(text: String, detectionText: String, result: MethodChannel.Result) {
    if (!detect || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      speak(text, null, result, retry = true)
      return
    }
    detector.execute {
      val language = detectLanguage(detectionText)
      main.post { speak(text, language, result, retry = true) }
    }
  }

  private fun detectLanguage(text: String): String? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
    val words = text.trim().split(Regex("\\s+")).count { it.isNotEmpty() }
    val letters = text.count { it.isLetter() }
    if (words < 3 && letters < 12) return null
    return try {
      val classifier = appContext
        .getSystemService(TextClassificationManager::class.java)
        ?.textClassifier ?: return null
      val detected = classifier.detectLanguage(TextLanguage.Request.Builder(text).build())
      if (detected.localeHypothesisCount == 0) return null
      val locale = detected.getLocale(0)
      if (detected.getConfidenceScore(locale) < 0.6f) null else locale.toLanguageTag()
    } catch (e: Exception) {
      null
    }
  }

  private fun baseCode(tag: String): String = Locale.forLanguageTag(tag).language

  /** The engine's voice list is an IPC round trip - read once, refreshed with [voices] and on engine restarts */
  @Volatile
  private var installedCache: List<Voice>? = null

  private fun loadInstalledVoices(): List<Voice> = try {
    (engine?.voices ?: emptySet())
      .filter { !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) }
  } catch (e: Exception) {
    emptyList()
  }

  private fun installedVoices(): List<Voice> =
    installedCache ?: loadInstalledVoices().also { installedCache = it }

  /** The user's pick for [tag] (exact, else one for the same language) if it's installed */
  private fun pickedVoice(tag: String, installed: List<Voice>): Voice? {
    val name = voicePicks[tag]
      ?: voicePicks.entries.firstOrNull { baseCode(it.key) == baseCode(tag) }?.value
      ?: return null
    return installed.firstOrNull { it.name == name }
  }

  /** The user's pick for [tag], else the best: exact locale, else the phone's region, else any region - quality first, offline on ties */
  private fun bestVoice(tag: String, installed: List<Voice> = installedVoices()): Voice? {
    pickedVoice(tag, installed)?.let { return it }
    val wanted = Locale.forLanguageTag(tag)
    val sameLanguage = installed.filter { it.locale.language == wanted.language }
    if (sameLanguage.isEmpty()) return null
    val region = wanted.country.ifEmpty { Locale.getDefault().country }
    val regional = sameLanguage.filter { it.locale.country == region }
    val pool = regional.ifEmpty { sameLanguage }
    return pool.sortedWith(
      compareByDescending<Voice> { it.quality }.thenBy { it.isNetworkConnectionRequired }
    ).firstOrNull()
  }

  /** The voice for one message - null keeps the engine's default voice */
  private fun voiceFor(detected: String?): Voice? {
    val defaultTag = defaultLanguage
      ?: (engine?.defaultVoice?.locale ?: Locale.getDefault()).toLanguageTag()

    // No language set and no pick for the phone's: the system settings' voice
    val fallback = if (defaultLanguage != null || pickedVoice(defaultTag, installedVoices()) != null) {
      bestVoice(defaultTag)
    } else {
      null
    }
    if (detected == null) return fallback
    if (baseCode(detected) == baseCode(defaultTag)) return fallback
    return bestVoice(detected) ?: fallback
  }

  /** [retry]: restart the engine and try once more if speaking fails */
  private fun speak(text: String, detected: String?, result: MethodChannel.Result, retry: Boolean) {
    whenInitialized {
      val tts = engine
      if (!ready || tts == null) {
        if (retry) {
          createEngine()
          speak(text, detected, result, retry = false)
        } else {
          result.success(null)
        }
        return@whenInitialized
      }
      val id = "chat-${nextId++}"
      pending[id] = result
      requestFocus()
      tts.setSpeechRate(rate)
      val previewId = previewVoice
      val previewTag = previewLanguage
      previewVoice = null
      previewLanguage = null
      val voice = when {
        previewId != null -> installedVoices().firstOrNull { it.name == previewId }
        previewTag != null -> bestVoice(previewTag)
        else -> voiceFor(detected)
      }
      if (voice != null) {
        tts.voice = voice
      } else {
        tts.defaultVoice?.let { tts.voice = it }
      }
      val capped = text.take(TextToSpeech.getMaxSpeechInputLength())
      val params = Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume) }
      if (tts.speak(capped, TextToSpeech.QUEUE_FLUSH, params, id) != TextToSpeech.SUCCESS) {
        pending.remove(id)
        if (retry) {
          createEngine()
          speak(text, detected, result, retry = false)
        } else {
          result.success(null)
          if (pending.isEmpty()) releaseFocus()
        }
      }
    }
  }

  /** Installed (downloaded) voices: id, language tag + display name, quality, network */
  /** Fresh list (also refreshes the cache) - call off the main thread */
  private fun voices(): List<Map<String, Any>> {
    val installed = loadInstalledVoices()
    installedCache = installed
    val bestByTag = HashMap<String, String>()
    return installed
      .map { voice ->
        mapOf(
          "id" to voice.name,
          "name" to voice.name,
          "language" to voice.locale.toLanguageTag(),
          "languageName" to voice.locale.displayName,
          "quality" to voice.quality,
          "network" to voice.isNetworkConnectionRequired,
          // The voice this bridge reads that language with
          "preferred" to (
            bestByTag.getOrPut(voice.locale.toLanguageTag()) {
              bestVoice(voice.locale.toLanguageTag(), installed)?.name ?: ""
            } == voice.name
          ),
        )
      }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "speak" -> {
        val text = call.argument<String>("text")
        if (text.isNullOrBlank()) {
          result.success(null)
          return
        }
        speakDetecting(text, call.argument<String>("detectionText") ?: text, result)
      }
      "setVolume" -> {
        volume = ((call.arguments as? Number)?.toFloat() ?: 1.0f).coerceIn(0.0f, 1.0f)
        result.success(null)
      }
      "setLanguage" -> {
        defaultLanguage = call.argument<String>("language")
        detect = call.argument<Boolean>("detect") ?: false
        voicePicks = call.argument<Map<String, String>>("voices") ?: emptyMap()
        result.success(null)
      }
      "preview" -> {
        // A short sample with one voice - interrupts whatever is read
        val text = call.argument<String>("text")
        if (text.isNullOrBlank()) {
          result.success(null)
          return
        }
        engine?.stop()
        finishAll()
        previewVoice = call.argument<String>("voiceId")
        previewLanguage = call.argument<String>("language")
        speak(text, null, result, retry = true)
      }
      "openTtsSettings" -> result.success(startSettings(Intent("com.android.settings.TTS_SETTINGS")))
      "installVoiceData" -> result.success(
        startSettings(
          Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA).apply {
            engine?.defaultEngine?.let { setPackage(it) }
          }
        )
      )
      "stop" -> {
        engine?.stop()
        finishAll()
        result.success(null)
      }
      "setRate" -> {
        // 1.0 = normal on Android
        rate = ((call.arguments as? Number)?.toFloat() ?: 1.0f).coerceIn(0.25f, 3.0f)
        result.success(null)
      }
      "voices" -> whenInitialized {
        detector.execute {
          val list = voices()
          main.post { result.success(list) }
        }
      }
      else -> result.notImplemented()
    }
  }

  fun shutdown() {
    detector.shutdownNow()
    finishAll()
    engine?.stop()
    engine?.shutdown()
    engine = null
  }
}
