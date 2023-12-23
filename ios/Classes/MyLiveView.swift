import Foundation
import AVFoundation

class MyLiveView: NSObject {
    private let previewTexture: PreviewTexture
    private let controller: MyLiveController
    
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    
    init(binaryMessenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry, mode: Int) throws {
        previewTexture = PreviewTexture(registry: textureRegistry)
        controller = try MyLiveController(preview: previewTexture, initialAudioConfig: nil, initialVideoConfig: nil, initialCamera: nil, mode: mode)
        eventChannel = FlutterEventChannel(name: "com.koji4104.mylive_libraly/events", binaryMessenger: binaryMessenger)
        
        super.init()
        controller.delegate = self
        eventChannel.setStreamHandler(self)
    }

    var textureId: Int64 {
        previewTexture.textureId
    }

    var videoConfig: MyLiveVideoConfig {
        get {
            controller.videoConfig
        }
        set {
            self.eventSink?(["type": "videoSizeChanged", "width": Double(newValue.width), "height": Double(newValue.height)])
            controller.videoConfig = newValue
        }
    }
    
    var audioConfig: MyLiveAudioConfig {
        get {
            controller.audioConfig
        }
        set {
            controller.audioConfig = newValue
        }
    }
    
    var isMuted: Bool {
       get {
           controller.isMuted
       }
       set {
           controller.isMuted = newValue
       }
   }
    
    var cameraPos: String {
        get {
            if (controller.cameraPos == AVCaptureDevice.Position.back) {
                return "back"
            } else if (controller.cameraPos == AVCaptureDevice.Position.front) {
                return "front"
            } else {
                return "other"
            }
        }
        set {
            if (newValue == "back") {
                controller.cameraPos = AVCaptureDevice.Position.back
            } else if (newValue == "front") {
                controller.cameraPos = AVCaptureDevice.Position.front
            }
        }
    }
    
    func dispose() {
        //isStreaming = false
        controller.stopStream()
        controller.stopPreview()
        previewTexture.dispose()
    }

    func setUrl(url: String?, key: String?) {
        controller.setUrl(url: url, key: key)
    }

    func startPreview() {
        controller.startPreview()
    }
  
    func stopPreview() {
        controller.stopPreview()
    }

    func startStream() throws {
        try controller.startStream()
        //isStreaming = true
    }

    func stopStream() {
        //isStreaming = false
        controller.stopStream()
    }

    func getCurrentFps() -> Int {
        return controller.getCurrentFps()
    }

    func isStreaming() -> Bool {
        return controller.isStreaming()
    }
}

extension MyLiveView: FlutterStreamHandler {
    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
       return nil
   }
   func onCancel(withArguments _: Any?) -> FlutterError? {
       eventSink = nil
       return nil
   }
}

extension MyLiveView: MyLiveDelegate {
    /// Called when the connection to the rtmp server is successful
    func connectionSuccess() {
        //self.isStreaming = true
        self.eventSink?(["type": "connected"])
    }

    /// Called when the connection to the rtmp server failed
    func connectionFailed(_ code: String) {
        //self.isStreaming = false
        self.eventSink?(["type": "connectionFailed", "message": "Failed to connect"])
    }

    /// Called when the connection to the rtmp server is closed
    func disconnection() {
        //self.isStreaming = false
        self.eventSink?(["type": "disconnected"])
    }

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error) {
        print("audio error: \(error)")
    }

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error) {
        print("video error: \(error)")
    }
}
