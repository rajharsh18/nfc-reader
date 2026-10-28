package com.gatekey.nfc_reader

import android.content.ComponentName
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        HceStore.clear(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                HceEvents.attach { event -> events.success(event) }
            }

            override fun onCancel(arguments: Any?) {
                HceEvents.attach(null)
            }
        })
        MethodChannel(messenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supported" -> result.success(canEmulate())
                    "start" -> {
                        val payload = call.argument<String>("payload").orEmpty()
                        if (!canEmulate() || payload.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        HceStore.write(this, payload)
                        preferService()
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(true)
                    }
                    "stop" -> {
                        HceStore.clear(this)
                        clearPreferred()
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        if (HceStore.read(this) != null) preferService()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        HceEvents.attach(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun canEmulate(): Boolean {
        return packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)
    }

    private fun preferService() {
        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return
        val service = ComponentName(this, GateKeyApduService::class.java)
        CardEmulation.getInstance(adapter).setPreferredService(this, service)
    }

    private fun clearPreferred() {
        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return
        CardEmulation.getInstance(adapter).unsetPreferredService(this)
    }

    companion object {
        private const val CHANNEL = "com.gatekey.nfc_reader/hce"
        private const val EVENT_CHANNEL = "com.gatekey.nfc_reader/hce_events"
    }
}

internal object HceEvents {
    const val SELECTED = "selected"
    const val READ = "read"
    const val LEFT = "left"

    private val main = Handler(Looper.getMainLooper())
    private var sink: ((String) -> Unit)? = null

    fun attach(listener: ((String) -> Unit)?) {
        sink = listener
    }

    fun emit(event: String) {
        main.post { sink?.invoke(event) }
    }
}
