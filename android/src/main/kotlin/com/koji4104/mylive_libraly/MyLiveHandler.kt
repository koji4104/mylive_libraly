package com.koji4104.mylive_libraly

import android.Manifest
import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import kotlin.reflect.KFunction1
import android.util.Size
import android.media.AudioFormat
import io.github.thibaultbee.streampack.data.AudioConfig as SpAudioConfig
import io.github.thibaultbee.streampack.data.VideoConfig as SpVideoConfig

class MyLiveHandler(
    private val activity: Activity,
    private val messenger: BinaryMessenger,
    private val permissionsRegistry: KFunction1<PluginRegistry.RequestPermissionsResultListener, Unit>,
    private val textureRegistry: TextureRegistry
) : MethodChannel.MethodCallHandler {
    private val methodChannel = MethodChannel(messenger, "com.koji4104.mylive_libraly/controller")
    private var controller: MyLiveController? = null

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "create" -> {
                var mode: Int = 0
                try {
                    if(call.argument<String>("mode")!=null)
                        mode = call.argument<String>("mode") as Int
                    controller?.dispose()
                } catch (e: Exception) {
                    //result.error("failed_to_create_dispose", e.message, null)
                }
                try {
                    controller = MyLiveController(
                        activity.applicationContext, textureRegistry, messenger, mode
                    )
                    result.success(mapOf("textureId" to controller!!.textureId))
                } catch (e: Exception) {
                    result.error("failed_to_create_controller", e.message, null)
                }
            }
            "dispose" -> {
                controller!!.dispose()
                controller = null
            }
            "setVideoConfig" -> {
                try {
                   var bitrate = call.argument<String>("bitrate") as Int
                   var fps = call.argument<String>("fps") as Int
                   var h = call.argument<String>("height") as Int
                   var resolution = when (h) {
                       360 -> Size(640, 360)
                       480 -> Size(858, 480)
                       720 -> Size(1280, 720)
                       1080 -> Size(1920, 1080)
                       2160 -> Size(4096, 2160)
                       else -> Size(1280, 720)
                   }
                   var videoConfig = SpVideoConfig(
                       startBitrate = bitrate,
                       fps = fps,
                       resolution = resolution
                   )
                   controller!!.videoConfig = videoConfig
                   result.success(null)
                } catch (e: Exception) {
                    result.error("failed_to_set_video_config", e.message, null)
                }
            }
            "setAudioConfig" -> {
                try {
                    var bitrate = call.argument<String>("bitrate") as Int
                    var sampleRate = call.argument<String>("sampleRate") as Int
                    val audioConfig = SpAudioConfig(
                        startBitrate = bitrate,
                        sampleRate = sampleRate,
                        channelConfig = AudioFormat.CHANNEL_IN_STEREO,
                        enableNoiseSuppressor = false,
                        enableEchoCanceler = false
                    )
                    controller!!.audioConfig = audioConfig
                    result.success(null)
                } catch (e: Exception) {
                    result.error("failed_to_set_audio_config", e.message, null)
                }
            }
            "setUrl" -> {
                try {
                    var url = call.argument<String>("url")
                    if(url!=null) controller!!.url = url
                    var key = call.argument<String>("key")
                    if(key!=null) controller!!.key = key
                    result.success(null)
                } catch (e: Exception) {
                    result.error("setUrl", e.message, null)
                }
            }
            "startPreview" -> {
                try {
                    controller!!.startPreview()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("failed_to_start_preview", e.message, null)
                }
            }
            "stopPreview" -> {
                try {
                    controller!!.stopPreview()
                } catch (e: Exception) {
                }
                result.success(null)
            }
            "startStream" -> {
                try {
                    controller!!.startStream()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("failed_to_startStream", e.message, null)
                }
            }
            "stopStream" -> {
                controller!!.stopStream()
                result.success(null)
            }
            "isStreaming" -> {
                result.success(mapOf("isStreaming" to controller!!.isStreaming()))
            }
            "getCameraPos" -> {
                try {
                    result.success(mapOf("pos" to controller!!.cameraPos))
                } catch (e: Exception) {
                    result.error("failed_to_get_camera_pos", e.message, null)
                }
            }
            "setCameraPos" -> {
                val cameraPos = try {
                    ((call.arguments as Map<*, *>)["pos"] as String)
                } catch (e: Exception) {
                    result.error("invalid_parameter", "Invalid camera position", e)
                    return
                }
                controller!!.cameraPos = cameraPos
                result.success(null)
            }
            "setMute" -> {
                val isMuted = try {
                    ((call.arguments as Map<*, *>)["mute"] as Boolean)
                } catch (e: Exception) {
                    result.error("invalid_parameter", "Invalid isMuted", e)
                    return
                }
                controller!!.isMuted = isMuted
                result.success(null)
            }
            "getVideoSize" -> {
                val videoSize = controller!!.videoConfig.resolution
                result.success(
                    mapOf(
                        "width" to videoSize.width.toDouble(),
                        "height" to videoSize.height.toDouble()
                    )
                )
            }
            "getCurrentFps" -> {
                result.success(mapOf("fps" to controller!!.getCurrentFps()))
            }
            else -> result.error("not_found_method", call.method.toString(), "")
        }
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    companion object {
        private const val TAG = "MyLiveHandler"
    }
}
