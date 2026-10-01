package com.kounex.obsBlade

import android.content.Context
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
 */
class ChatTts(context: Context, channel: MethodChannel) : MethodChannel.MethodCallHandler {
  private val main = Handler(Looper.getMainLooper())
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
    engine = TextToSpeech(context.applicationContext) { status ->
      main.post {
        initDone = true
        ready = status == TextToSpeech.SUCCESS
        if (ready) engine?.setOnUtteranceProgressListener(listener)
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
    main.post { pending.remove(utteranceId)?.success(null) }
  }

  private fun finishAll() {
    val results = pending.values.toList()
    pending.clear()
    results.forEach { it.success(null) }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "speak" -> {
        val text = call.arguments as? String
        if (text.isNullOrBlank()) {
          result.success(null)
          return
        }
        whenInitialized {
          val tts = engine
          if (!ready || tts == null) {
            result.success(null)
            return@whenInitialized
          }
          val id = "chat-${nextId++}"
          pending[id] = result
          tts.setSpeechRate(rate)
          if (tts.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), id) != TextToSpeech.SUCCESS) {
            pending.remove(id)?.success(null)
          }
        }
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
