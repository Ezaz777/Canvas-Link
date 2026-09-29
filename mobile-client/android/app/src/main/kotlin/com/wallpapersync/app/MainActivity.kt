package com.wallpapersync.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val EVENT_CHANNEL = "com.wallpapersync.app/auth_deep_link"
    private val METHOD_CHANNEL = "com.wallpapersync.app/auth_deep_link_method"
    private var eventSink: EventChannel.EventSink? = null
    private var lastTokenLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.dataString?.let {
            if (it.startsWith("canvaslink://") || it.startsWith("wallpapersync://")) {
                lastTokenLink = it
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.dataString?.let { link ->
            if (link.startsWith("canvaslink://") || link.startsWith("wallpapersync://")) {
                lastTokenLink = link
                eventSink?.success(link)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel for real-time deep links
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    lastTokenLink?.let {
                        events?.success(it)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // MethodChannel for querying pending tokens and launching native in-app Chrome Custom Tabs
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLatestToken" -> {
                    val token = lastTokenLink
                    result.success(token)
                }
                "clearLatestToken" -> {
                    lastTokenLink = null
                    result.success(true)
                }
                "openCustomTab" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val customTabsIntent = CustomTabsIntent.Builder()
                                .setShowTitle(true)
                                .build()
                            customTabsIntent.launchUrl(this@MainActivity, Uri.parse(url))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CUSTOM_TAB_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
