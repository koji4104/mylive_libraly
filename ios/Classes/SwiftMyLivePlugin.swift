import AVFoundation
import Flutter
import Network
import UIKit
import HaishinKit

enum MyLiveError: Error {
    case invalidAVSession
}

public class SwiftMyLivePlugin: NSObject, FlutterPlugin {
    private let binaryMessenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private let registry: FlutterTextureRegistry
    private var flutterView: MyLiveView?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftMyLivePlugin(registrar: registrar)
        registrar.publish(instance)
    }

    public init(registrar: FlutterPluginRegistrar) {
        self.binaryMessenger = registrar.messenger()
        self.channel = FlutterMethodChannel(name: "com.koji4104.mylive_libraly/controller", binaryMessenger: binaryMessenger)
        self.registry = registrar.textures()
        super.init()
        registrar.addMethodCallDelegate(self, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            flutterView?.dispose()
            guard let args = call.arguments as? [String: Any],
                let mode = args["mode"] as? Int else {
                  result(FlutterError(code: "invalid_parameter", message: "Invalid mode", details: nil))
                  return
                }
            do {
                flutterView = try MyLiveView(binaryMessenger: binaryMessenger, textureRegistry: registry, mode: mode)
                if let previewTexture = flutterView?.textureId {
                    result(["textureId": previewTexture])
                } else {
                    result(FlutterError(code: "failed_to_create_live_stream", message: "Failed to create camera preview surface", details: nil))
                }
            } catch {
                result(FlutterError(code: "failed_to_create_live_stream", message: error.localizedDescription, details: nil))
            }
        case "dispose":
            flutterView?.dispose()
        case "setVideoConfig":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            guard let videoParameters = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_parameter", message: "Invalid video config", details: nil))
                return
            }
            flutterView.videoConfig = videoParameters.toVideoConfig()
            result(nil)
        case "setAudioConfig":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            guard let audioParameters = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_parameter", message: "Invalid audio config", details: nil))
                return
            }
            flutterView.audioConfig = audioParameters.toAudioConfig()
            result(nil)
        case "startPreview":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            flutterView.startPreview()
            result(nil)
        case "stopPreview":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            flutterView.stopPreview()
            result(nil)
        case "setUrl":
            if let args = call.arguments as? [String: Any] {
                let url = args["url"] as? String
                let key = args["key"] as? String
                guard let flutterView = flutterView else {
                    result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                    return
                }
                do {
                    try flutterView.setUrl(url:url,key:key)
                    result(nil)
                } catch {
                    result(FlutterError(code: "missing_live_stream", message: error.localizedDescription, details: nil))
                }
            }
        case "startStream":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            do {
                try flutterView.startStream()
                result(nil)
            } catch {
                result(FlutterError(code: "missing_live_stream", message: error.localizedDescription, details: nil))
            }
        case "stopStream":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            flutterView.stopStream()
            result(nil)
        case "isStreaming":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            result(["isStreaming": flutterView.isStreaming])
        case "getCameraPos":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            result(["pos": flutterView.cameraPos])
        case "setCameraPos":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                 let cameraPos = args["pos"] as? String else {
                result(FlutterError(code: "invalid_parameter", message: "Invalid camera position", details: nil))
                return
            }
            flutterView.cameraPos = cameraPos
            result(nil)
        case "setMute":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                 let isMuted = args["mute"] as? Bool else {
                result(FlutterError(code: "invalid_parameter", message: "Invalid isMuted", details: nil))
                return
            }
            flutterView.isMuted = isMuted
            result(nil)
        case "getCurrentFps":
            guard let flutterView = flutterView else {
                result(FlutterError(code: "missing_live_stream", message: "Live stream must exist at this point", details: nil))
                return
            }
            result(["fps": flutterView.getCurrentFps()])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension Dictionary where Key == String {
    func toAudioConfig() -> MyLiveAudioConfig {
        return MyLiveAudioConfig(bitrate: self["bitrate"] as! Int)
    }

    func toVideoConfig() -> MyLiveVideoConfig {
        return MyLiveVideoConfig(bitrate: self["bitrate"] as! Int,
                           width: self["width"] as! Int,
                           height: self["height"] as! Int,
                           fps: self["fps"] as! Float64)
    }
}
