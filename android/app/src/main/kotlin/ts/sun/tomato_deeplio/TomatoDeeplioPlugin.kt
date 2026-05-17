package ts.sun.tomato_deeplio

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * TomatoDeeplioPlugin
 *
 * Handles:
 * - App Links (Android 12+ verified links)
 * - Custom URI scheme deep links
 * - Initial link extraction (cold start)
 * - Foreground link stream (EventChannel)
 * - Deferred link token persistence (SharedPreferences)
 */
class TomatoDeeplioPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "tomato_deeplio"
        private const val EVENT_CHANNEL = "tomato_deeplio/events"
        private const val PREFS_NAME = "tomato_deeplio_prefs"
        private const val KEY_DEFERRED_TOKEN = "deferred_token"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null

    // Holds the initial link URL until Dart side requests it
    private var initialLink: String? = null
    // Holds a pending link received while the app is running
    private var pendingLink: String? = null

    // ── FlutterPlugin ──────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ── ActivityAware ──────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Extract the initial link from the launch intent
        initialLink = extractLink(binding.activity.intent)
        binding.addOnNewIntentListener { intent ->
            handleNewIntent(intent)
            true
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ── MethodCallHandler ──────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInitialLink" -> {
                result.success(initialLink)
                // Clear after first read so it is not replayed
                initialLink = null
            }
            "storeDeferredToken" -> {
                val token = call.argument<String>("token")
                if (token != null) {
                    prefs().edit().putString(KEY_DEFERRED_TOKEN, token).apply()
                }
                result.success(null)
            }
            "getDeferredToken" -> {
                result.success(prefs().getString(KEY_DEFERRED_TOKEN, null))
            }
            "clearDeferredToken" -> {
                prefs().edit().remove(KEY_DEFERRED_TOKEN).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ── EventChannel.StreamHandler ─────────────────────────────────────────

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
        // Flush any link that arrived before the stream was ready
        pendingLink?.let { link ->
            sink?.success(link)
            pendingLink = null
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ── Private helpers ────────────────────────────────────────────────────

    private fun handleNewIntent(intent: Intent) {
        val link = extractLink(intent) ?: return
        if (eventSink != null) {
            eventSink?.success(link)
        } else {
            pendingLink = link
        }
    }

    private fun extractLink(intent: Intent?): String? {
        if (intent == null) return null
        val action = intent.action
        val data: Uri? = intent.data

        return when {
            // App Link / Universal Link (HTTPS)
            action == Intent.ACTION_VIEW && data != null -> data.toString()
            // Custom URI scheme
            action == Intent.ACTION_VIEW && data != null -> data.toString()
            else -> null
        }
    }

    private fun prefs(): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
