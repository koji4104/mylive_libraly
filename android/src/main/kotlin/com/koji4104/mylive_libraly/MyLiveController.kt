package com.koji4104.mylive_libraly

import android.Manifest
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Size
import android.view.Surface
import androidx.annotation.RequiresPermission
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import io.github.thibaultbee.streampack.data.AudioConfig as SpAudioConfig
import io.github.thibaultbee.streampack.data.VideoConfig as SpVideoConfig
import io.github.thibaultbee.streampack.error.StreamPackError
import io.github.thibaultbee.streampack.ext.rtmp.streamers.CameraRtmpLiveStreamer
import io.github.thibaultbee.streampack.listeners.OnConnectionListener
import io.github.thibaultbee.streampack.listeners.OnErrorListener
import io.github.thibaultbee.streampack.utils.*
import kotlinx.coroutines.runBlocking
import io.github.thibaultbee.streampack.ext.srt.streamers.CameraSrtLiveStreamer

class MyLiveController(
    private val context: Context,
    textureRegistry: TextureRegistry,
    messenger: BinaryMessenger,
    var mode: Int
) :
    OnConnectionListener, OnErrorListener {
    private val flutterTexture = textureRegistry.createSurfaceTexture()
    val textureId: Long
        get() = flutterTexture.id()

    private val srtStreamer = CameraSrtLiveStreamer(
            context = context,
            initialOnConnectionListener = this,
            initialOnErrorListener = this
        );

    private val rtmpStreamer = CameraRtmpLiveStreamer(
            context = context,
            initialOnConnectionListener = this,
            initialOnErrorListener = this
        );

    var url: String? = null
    var key: String? = null

    val isSrt: Boolean
        get() = if (mode==0) true else false

    val streamer
        get() = srtStreamer

    var _isPreviewing = false
    var _isStreaming = false

    fun isStreaming(): Boolean {
        if (isSrt) return srtStreamer.isConnected
        return rtmpStreamer.isConnected
    }

    private var eventSink: EventChannel.EventSink? = null
    private val eventChannel = EventChannel(messenger, "com.koji4104.mylive_libraly/events")

    init {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink?.endOfStream()
                eventSink = null
            }
        })
    }

    var videoConfig = SpVideoConfig()
        set(value) {
            if (_isStreaming) {
                throw UnsupportedOperationException("You have to stop streaming first")
            }
            eventSink?.success(
                mapOf(
                    "type" to "videoSizeChanged",
                    "width" to value.resolution.width.toDouble(),
                    "height" to value.resolution.height.toDouble() // Dart size fields are in doubleart size fields are in double
                )
            )

            val wasPreviewing = _isPreviewing
            if (wasPreviewing) {
                stopPreview()
            }

            if (isSrt) srtStreamer.configure(value)
            else rtmpStreamer.configure(value)

            field = value
            if (wasPreviewing) {
                startPreview()
            }
        }

    var audioConfig = SpAudioConfig()
        set(value) {
            if (_isStreaming) {
                throw UnsupportedOperationException("You have to stop streaming first")
            }
            if (isSrt) srtStreamer.configure(value)
            else rtmpStreamer.configure(value)
            field = value
        }

    var isMuted: Boolean
        get() = srtStreamer.settings.audio.isMuted
        set(value) {
            if (isSrt) srtStreamer.settings.audio.isMuted = value
            else rtmpStreamer.settings.audio.isMuted = value
        }

    var camera: String
        get() = if (isSrt) srtStreamer.camera else rtmpStreamer.camera
        set(value) {
            if (isSrt) srtStreamer.camera = value
            else rtmpStreamer.camera = value
        }

    var cameraPos: String
        get() =
            if (isSrt) {
                when {
                    context.isBackCamera(srtStreamer.camera) -> "back"
                    context.isFrontCamera(srtStreamer.camera) -> "front"
                    context.isExternalCamera(srtStreamer.camera) -> "other"
                    else -> throw IllegalArgumentException("Invalid camera position for camera ${streamer.camera}")
                }
            } else {
                when {
                    context.isBackCamera(rtmpStreamer.camera) -> "back"
                    context.isFrontCamera(rtmpStreamer.camera) -> "front"
                    context.isExternalCamera(rtmpStreamer.camera) -> "other"
                    else -> throw IllegalArgumentException("Invalid camera position for camera ${streamer.camera}")
                }
            }

        set(value) {
            val cameraList = when (value) {
                "back" -> context.getBackCameraList()
                "front" -> context.getFrontCameraList()
                "other" -> context.getExternalCameraList()
                else -> throw IllegalArgumentException("Invalid camera position: $value")
            }
            if (isSrt) srtStreamer.camera = cameraList[0]
            else rtmpStreamer.camera = cameraList[0]
        }

    fun dispose() {
        if (isSrt) {
            srtStreamer.stopPreview()
            srtStreamer.stopStream()
            srtStreamer.disconnect()
            flutterTexture.release()
        } else {
            rtmpStreamer.stopPreview()
            rtmpStreamer.stopStream()
            rtmpStreamer.disconnect()
            flutterTexture.release()
        }
    }

    fun startStream() {
        if (isSrt) {
            runBlocking {
                try {
                    if(!key.isNullOrEmpty()) srtStreamer.passPhrase = key!!
                    srtStreamer.startStream(url!!)
                    _isStreaming = true
                } catch (e: Exception) {
                    srtStreamer.disconnect()
                }
            }
        } else {
            runBlocking {
                try {
                    var url1 = url!!
                    if (!key.isNullOrEmpty()) url1 += "/" + key!!
                    rtmpStreamer.startStream(url1)
                    _isStreaming = true
                } catch (e: Exception) {
                    rtmpStreamer.disconnect()
                }
            }
        }
    }

    fun stopStream() {
        _isStreaming = false
        if (isSrt) {
            srtStreamer.stopStream()
            srtStreamer.disconnect()
        } else {
            rtmpStreamer.stopStream()
            rtmpStreamer.disconnect()
        }
    }

    @RequiresPermission(Manifest.permission.CAMERA)
    fun startPreview() {
        if (isSrt) srtStreamer.startPreview(getSurface(videoConfig.resolution))
        else rtmpStreamer.startPreview(getSurface(videoConfig.resolution))
        _isPreviewing = true
    }

    fun stopPreview() {
        if (isSrt) srtStreamer.stopPreview()
        else rtmpStreamer.stopPreview()
        _isPreviewing = false
    }

    fun getCurrentFps(): Int {
        return 0
    }

    private fun getSurface(resolution: Size): Surface {
        val surfaceTexture = flutterTexture.surfaceTexture().apply {
            setDefaultBufferSize(
                resolution.width,
                resolution.height
            )
        }
        return Surface(surfaceTexture)
    }

    override fun onSuccess() {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(mapOf("type" to "connected"))
        }
    }

    override fun onLost(message: String) {
        _isStreaming = false
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(mapOf("type" to "disconnected", "message" to message))
        }
    }

    override fun onFailed(message: String) {
        _isStreaming = false
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(mapOf("type" to "failed", "message" to message))
        }
    }

    override fun onError(error: StreamPackError) {
        _isStreaming = false
        Handler(Looper.getMainLooper()).post {
            eventSink?.error(error::class.java.name, error.message, error)
        }
    }

    companion object {
        private const val TAG = "MyLiveView"
    }
}