package com.wallpapersync.app

import android.app.WallpaperManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val EVENT_CHANNEL = "com.wallpapersync.app/auth_deep_link"
    private val METHOD_CHANNEL = "com.wallpapersync.app/auth_deep_link_method"
    private val WALLPAPER_CHANNEL = "com.wallpapersync.app/wallpaper"
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

        // MethodChannel for querying pending tokens on resume
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
                else -> result.notImplemented()
            }
        }

        // Dedicated native WallpaperManager channel (crash-free, stream-based, background thread)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val target = call.argument<String>("location") ?: "both"

                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath is required", null)
                        return@setMethodCallHandler
                    }

                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    thread {
                        try {
                            val wallpaperManager = WallpaperManager.getInstance(applicationContext)

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                when (target) {
                                    "home" -> {
                                        FileInputStream(file).use { stream ->
                                            wallpaperManager.setStream(stream, null, true, WallpaperManager.FLAG_SYSTEM)
                                        }
                                    }
                                    "lock" -> {
                                        FileInputStream(file).use { stream ->
                                            wallpaperManager.setStream(stream, null, true, WallpaperManager.FLAG_LOCK)
                                        }
                                    }
                                    else -> {
                                        // Set Home screen first
                                        FileInputStream(file).use { stream ->
                                            wallpaperManager.setStream(stream, null, true, WallpaperManager.FLAG_SYSTEM)
                                        }
                                        // Then try setting Lock screen separately (some OEMs reject combined flags)
                                        try {
                                            FileInputStream(file).use { stream ->
                                                wallpaperManager.setStream(stream, null, true, WallpaperManager.FLAG_LOCK)
                                            }
                                        } catch (lockEx: Exception) {
                                            // Some OEM skins restrict lock screen modification; home screen succeeded
                                            lockEx.printStackTrace()
                                        }
                                    }
                                }
                            } else {
                                FileInputStream(file).use { stream ->
                                    wallpaperManager.setStream(stream)
                                }
                            }

                            runOnUiThread {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            runOnUiThread {
                                result.error("SET_WALLPAPER_FAILED", e.localizedMessage ?: "Failed to set wallpaper", null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

