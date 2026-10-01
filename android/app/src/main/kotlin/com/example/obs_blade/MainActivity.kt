package com.kounex.obsBlade

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
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
 * engine and retries that message once. The voice stays the one picked in
 * the system TTS settings.
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
  private var nextId = 0

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

  /** [retry]: restart the engine and try once more if speaking fails */
  private fun speak(text: String, result: MethodChannel.Result, retry: Boolean) {
    whenInitialized {
      val tts = engine
      if (!ready || tts == null) {
        if (retry) {
          createEngine()
          speak(text, result, retry = false)
        } else {
          result.success(null)
        }
        return@whenInitialized
      }
      val id = "chat-${nextId++}"
      pending[id] = result
      requestFocus()
      tts.setSpeechRate(rate)
      val capped = text.take(TextToSpeech.getMaxSpeechInputLength())
      if (tts.speak(capped, TextToSpeech.QUEUE_FLUSH, Bundle(), id) != TextToSpeech.SUCCESS) {
        pending.remove(id)
        if (retry) {
          createEngine()
          speak(text, result, retry = false)
        } else {
          result.success(null)
          if (pending.isEmpty()) releaseFocus()
        }
      }
    }
  }

  /** Installed (downloaded) voices: id, language tag + display name, quality, network */
  private fun voices(): List<Map<String, Any>> {
    val voices = try {
      engine?.voices ?: emptySet()
    } catch (e: Exception) {
      emptySet()
    }
    return voices
      .filter { !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) }
      .map { voice ->
        mapOf(
          "id" to voice.name,
          "name" to voice.name,
          "language" to voice.locale.toLanguageTag(),
          "languageName" to voice.locale.displayName,
          "quality" to voice.quality,
          "network" to voice.isNetworkConnectionRequired,
        )
      }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "speak" -> {
        val text = call.arguments as? String
        if (text.isNullOrBlank()) {
          result.success(null)
          return
        }
        speak(text, result, retry = true)
      }
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
      "voices" -> whenInitialized { result.success(voices()) }
      else -> result.notImplemented()
    }
  }

  fun shutdown() {
    finishAll()
    engine?.stop()
    engine?.shutdown()
    engine = null
  }
}
