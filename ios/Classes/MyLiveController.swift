import AVFoundation
import Foundation
import HaishinKit
import UIKit
import VideoToolbox

public class MyLiveController {
    var mode = 0
    var isSrt: Bool { get { return mode == 0 }}

    public var srtStream: SRTStream!
    public var srtConnection = SRTConnection()

    public var rtmpStream: RTMPStream!
    public var rtmpConnection = RTMPConnection()

    public var url: String? = ""
    public var key: String? = ""

    private var isAudioConfigured = false
    private var isVideoConfigured = false

    public weak var delegate: MyLiveDelegate?

    public init(
        initialAudioConfig: MyLiveAudioConfig? = MyLiveAudioConfig(),
        initialVideoConfig: MyLiveVideoConfig? = MyLiveVideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ),
        mode: Int
    ) throws {
        self.mode = mode
        let session = AVAudioSession.sharedInstance()

        // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        if isSrt {
            self.srtConnection = .init()
            self.srtStream = SRTStream(self.srtConnection)
            self.srtStream.videoSettings = VideoCodecSettings(videoSize: .init(width: 1_280, height: 720))
        } else {
            self.rtmpStream = RTMPStream(connection: self.rtmpConnection)
            self.rtmpStream.videoSettings = VideoCodecSettings(videoSize: .init(width: 1_280, height: 720))
        }

        if isSrt {
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                self.srtStream.videoOrientation = orientation
            }
        } else {
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                self.rtmpStream.videoOrientation = orientation
            }
        }

        if let initialCamera = initialCamera {
            self.attachCamera(initialCamera)
        }
        if let initialVideoConfig = initialVideoConfig {
            self.prepareVideo(videoConfig: initialVideoConfig)
        }

        self.attachAudio()
        if let initialAudioConfig = initialAudioConfig {
            self.prepareAudio(audioConfig: initialAudioConfig)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        if isSrt {
            //self.srtConnection.addEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
            //self.srtConnection.addEventListener(.ioError, selector: #selector(self.rtmpErrorHandler), observer: self)
        } else {
            self.rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
            self.rtmpConnection.addEventListener(.ioError, selector: #selector(self.rtmpErrorHandler), observer: self)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.orientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    /// Creates a new Stream object with a NetStreamDrawable
    public convenience init(
        preview: NetStreamDrawable,
        initialAudioConfig: MyLiveAudioConfig? = MyLiveAudioConfig(),
        initialVideoConfig: MyLiveVideoConfig? = MyLiveVideoConfig(),
        initialCamera: AVCaptureDevice? = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ),
        mode: Int
    ) throws {
        try self.init(
            initialAudioConfig: initialAudioConfig,
            initialVideoConfig: initialVideoConfig,
            initialCamera: initialCamera,
            mode: mode
        )
        if isSrt {
            preview.attachStream(self.srtStream)
        } else {
            preview.attachStream(self.rtmpStream)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        if isSrt {
        } else {
            rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        }
    }

    public var audioConfig: MyLiveAudioConfig {
        get {
            if isSrt {
                MyLiveAudioConfig(bitrate: self.srtStream.audioSettings.bitRate)
            } else {
                MyLiveAudioConfig(bitrate: self.rtmpStream.audioSettings.bitRate)
            }
        }
        set {
            self.prepareAudio(audioConfig: newValue)
        }
    }

    public var videoConfig: MyLiveVideoConfig {
        get {
            if isSrt {
                try! MyLiveVideoConfig(
                    bitrate: Int(self.srtStream.videoSettings.bitRate),
                    width: Int(self.srtStream.videoSettings.videoSize.width),
                    height: Int(self.srtStream.videoSettings.videoSize.height),
                    fps: self.srtStream.frameRate,
                    gopDuration: TimeInterval(self.srtStream.videoSettings.maxKeyFrameIntervalDuration)
                )
            } else {
                try! MyLiveVideoConfig(
                    bitrate: Int(self.rtmpStream.videoSettings.bitRate),
                    width: Int(self.rtmpStream.videoSettings.videoSize.width),
                    height: Int(self.rtmpStream.videoSettings.videoSize.height),
                    fps: self.rtmpStream.frameRate,
                    gopDuration: TimeInterval(self.rtmpStream.videoSettings.maxKeyFrameIntervalDuration)
                )
            }
        }
        set {
            self.prepareVideo(videoConfig: newValue)
        }
    }

    // swiftlint:disable force_cast
    /// Getter and Setter for the Bitrate number for the video
    public var videoBitrate: Int {
        get {
            if isSrt {
                Int(self.srtStream.videoSettings.bitRate)
            } else {
                Int(self.rtmpStream.videoSettings.bitRate)
            }
        }
        set(newValue) {
            if isSrt {
                self.srtStream.videoSettings.bitRate = UInt32(newValue)
            } else {
                self.rtmpStream.videoSettings.bitRate = UInt32(newValue)
            }
        }
    }

    private var lastCamera: AVCaptureDevice?

    /// Camera position
    public var cameraPos: AVCaptureDevice.Position {
        get {
            if isSrt {
                guard let pos = srtStream.videoCapture(for: 0)?.device?.position else {
                    return AVCaptureDevice.Position.unspecified
                }
                return pos
            } else {
                guard let pos = rtmpStream.videoCapture(for: 0)?.device?.position else {
                    return AVCaptureDevice.Position.unspecified
                }
                return pos
            }
        }
        set(newValue) {
            self.attachCamera(newValue)
        }
    }

    /// Camera device
    public var camera: AVCaptureDevice? {
        get {
            if isSrt {
                self.srtStream.videoCapture(for: 0)?.device
            } else {
                self.rtmpStream.videoCapture(for: 0)?.device
            }
        }
        set(newValue) {
            self.attachCamera(newValue)
        }
    }

    /// Mutes or unmutes audio capture.
    public var isMuted: Bool {
        get {
            if isSrt {
                !self.srtStream.hasAudio
            } else {
                !self.rtmpStream.hasAudio
            }
        }
        set(newValue) {
            if isSrt {
                self.srtStream.hasAudio = !newValue
            } else {
                self.rtmpStream.hasAudio = !newValue
            }
        }
    }

    private func attachCamera(_ cameraPosition: AVCaptureDevice.Position) {
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
        self.attachCamera(camera)
    }

    private func attachCamera(_ camera: AVCaptureDevice?) {
        self.lastCamera = camera
        if let camera = camera {
            if isSrt {
                srtStream.videoCapture(for: 0)?.isVideoMirrored = camera.position == .front
            } else {
                rtmpStream.videoCapture(for: 0)?.isVideoMirrored = camera.position == .front
            }
        }

        if isSrt {
            self.srtStream.attachCamera(camera) { error in
                print("-- attachCamera error=\(error)")
                self.delegate?.videoError(error)
            }
            self.srtStream.lockQueue.async {
                guard let capture = self.srtStream.videoCapture(for: 0) else {
                    return
                }
                guard let device = capture.device else {
                    return
                }
                do {
                    try device.lockForConfiguration()
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for exposure and focus")
                }
            }
        } else {
            self.rtmpStream.attachCamera(camera) { error in
                print("-- attachCamera error=\(error)")
                self.delegate?.videoError(error)
            }
            self.rtmpStream.lockQueue.async {
                guard let capture = self.rtmpStream.videoCapture(for: 0) else {
                    return
                }
                guard let device = capture.device else {
                    return
                }
                do {
                    try device.lockForConfiguration()
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for exposure and focus")
                }
            }
        }
    }

    private func prepareVideo(videoConfig: MyLiveVideoConfig) {
        if isSrt {
            self.srtStream.frameRate = videoConfig.fps
            self.srtStream.sessionPreset = AVCaptureSession.Preset.high

            let width = self.srtStream.videoOrientation.isLandscape ? videoConfig.width : videoConfig.height
            let height = self.srtStream.videoOrientation.isLandscape ? videoConfig.height : videoConfig.width

            self.srtStream.videoSettings = VideoCodecSettings(
              videoSize: CGSize.init(width: Double(width), height: Double(height)),
              profileLevel: kVTProfileLevel_H264_Baseline_5_2 as String,
              bitRate: UInt32(videoConfig.bitrate),
              maxKeyFrameIntervalDuration: Int32(videoConfig.gopDuration)
            )

        } else {
            self.rtmpStream.frameRate = videoConfig.fps
            self.rtmpStream.sessionPreset = AVCaptureSession.Preset.high

            let width = self.rtmpStream.videoOrientation.isLandscape ? videoConfig.width : videoConfig.height
            let height = self.rtmpStream.videoOrientation.isLandscape ? videoConfig.height : videoConfig.width

            self.rtmpStream.videoSettings = VideoCodecSettings(
              videoSize: CGSize.init(width: Double(width), height: Double(height)),
              profileLevel: kVTProfileLevel_H264_Baseline_5_2 as String,
              bitRate: UInt32(videoConfig.bitrate),
              maxKeyFrameIntervalDuration: Int32(videoConfig.gopDuration)
            )
        }
        self.isVideoConfigured = true
    }

    private func attachAudio() {
        if isSrt {
            self.srtStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
                print("======== Audio error ==========")
                print(error)
                self.delegate?.audioError(error)
            }
        } else {
            self.rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
                print("======== Audio error ==========")
                print(error)
                self.delegate?.audioError(error)
            }
        }
    }

    private func prepareAudio(audioConfig: MyLiveAudioConfig) {
        /*
        self.rtmpStream.audioSettings = AudioCodecSettings(
            bitRate: audioConfig.bitrate
            //format: .aac
        )
        self.isAudioConfigured = true
        */
    }

    // swiftlint:disable implicit_return
    /// Zoom on the video capture
    public var zoomRatio: CGFloat {
        get {
            if isSrt {
                guard let device = srtStream.videoCapture(for: 0)?.device else {
                    return 1.0
                }
                return device.videoZoomFactor
            } else {
                guard let device = rtmpStream.videoCapture(for: 0)?.device else {
                    return 1.0
                }
                return device.videoZoomFactor
            }
        }
        set(newValue) {
            if isSrt {
                guard let device = srtStream.videoCapture(for: 0)?.device, newValue >= 1,
                      newValue < device.activeFormat.videoMaxZoomFactor else {
                    return
                }
                do {
                    try device.lockForConfiguration()
                    device.ramp(toVideoZoomFactor: newValue, withRate: 5.0)
                    device.unlockForConfiguration()
                } catch let error as NSError {
                    print("Error while locking device for zoom ramp: \(error)")
                }
            } else {
                guard let device = rtmpStream.videoCapture(for: 0)?.device, newValue >= 1,
                      newValue < device.activeFormat.videoMaxZoomFactor else {
                    return
                }
                do {
                    try device.lockForConfiguration()
                    device.ramp(toVideoZoomFactor: newValue, withRate: 5.0)
                    device.unlockForConfiguration()
                } catch let error as NSError {
                    print("Error while locking device for zoom ramp: \(error)")
                }
            }
        }
    }

    public func setUrl(url: String?, key: String?) {
        self.url = url
        self.key = key
    }

    public func startStream() {
        if isSrt {
            var url1 = url!
            if (key != nil && key! != "") { url1 += "?passphrase=" + key! }
            print("-- url1=\(url1)")
            self.srtStream.lockQueue.sync {
                srtConnection.open(URL(string: url1))
                srtStream.publish("")
                self.delegate?.connectionSuccess()
            }
        } else {
            self.rtmpStream.lockQueue.sync {
                rtmpConnection.connect(self.url!)
            }
        }
    }

    public func stopStream() {
        if isSrt {
            self.srtStream.close()
            self.srtConnection.close()
        } else {
            let isConnected = self.rtmpConnection.connected
            self.rtmpConnection.close()
            if isConnected {
                self.delegate?.disconnection()
            }
        }
    }

    public func startPlayback() {
        if isSrt {
            var url1 = url!
            if (key != nil && key! != "") { url1 += "?passphrase=" + key! }
            print("-- url1=\(url1)")
            self.srtStream.lockQueue.sync {
                srtConnection.open(URL(string: url1))
                srtStream.play("")
                self.delegate?.connectionSuccess()
            }
        } else {
        }
    }

    public func stopPlayback() {
        if isSrt {
            self.srtStream.close()
            self.srtConnection.close()
        } else {
        }
    }

    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject,
              let code: String = data["code"] as? String else
        {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            self.delegate?.connectionSuccess()
            self.rtmpStream.publish(self.key)
            break
        case RTMPConnection.Code.connectClosed.rawValue:
            self.delegate?.disconnection()
            break
        case RTMPConnection.Code.connectFailed.rawValue:
            self.delegate?.connectionFailed(code)
            break
        case RTMPConnection.Code.callBadVersion.rawValue
        , RTMPConnection.Code.callFailed.rawValue
        , RTMPConnection.Code.callProhibited.rawValue
        , RTMPConnection.Code.connectAppshutdown.rawValue
        , RTMPConnection.Code.connectIdleTimeOut.rawValue
        , RTMPConnection.Code.connectInvalidApp.rawValue
        , RTMPConnection.Code.connectNetworkChange.rawValue
        , RTMPConnection.Code.connectRejected.rawValue:
            self.delegate?.connectionFailed(code)
            break
        default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        let e = Event.from(notification)
        //print("rtmpErrorHandler: \(e)")
        DispatchQueue.main.async {
            self.rtmpConnection.connect(self.url!)
        }
    }

    public func startPreview() {
        guard let lastCamera = lastCamera else {
            print("No camera has been set")
            return
        }
        self.attachCamera(lastCamera)
        //self.attachAudio()
    }

    public func stopPreview() {
        if isSrt {
            self.srtStream.attachCamera(nil)
            self.srtStream.attachAudio(nil)
        } else {
            self.rtmpStream.attachCamera(nil)
            self.rtmpStream.attachAudio(nil)
        }
    }

    public func getCurrentFps() -> Int {
        var r = 0
        if isSrt {
            r = 0
        } else {
            r = Int(self.rtmpStream.currentFPS)
        }
        return r
    }

    func isStreaming() -> Bool {
      if isSrt {
          return self.srtConnection.connected
      } else {
          return self.rtmpStream.currentFPS > 0
      }
    }

    @objc
    private func orientationDidChange(_: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        if isSrt {
            self.srtStream.lockQueue.async {
                do {
                    self.srtStream.videoOrientation = orientation
                    let width = Int(self.srtStream.videoSettings.videoSize.width)
                    let height = Int(self.srtStream.videoSettings.videoSize.height)
                    let isLandscape = self.srtStream.videoOrientation.isLandscape
                    self.srtStream.videoSettings.videoSize = CGSize.init(
                        width: Double(isLandscape ? width : height),
                        height: Double(isLandscape ? height : width)
                    )
                } catch {
                    print("Failed to set resolution to orientation \(orientation)")
                }
            }
        } else {
            self.rtmpStream.lockQueue.async {
                do {
                    self.rtmpStream.videoOrientation = orientation
                    let width = Int(self.rtmpStream.videoSettings.videoSize.width)
                    let height = Int(self.rtmpStream.videoSettings.videoSize.height)
                    let isLandscape = self.rtmpStream.videoOrientation.isLandscape
                    self.rtmpStream.videoSettings.videoSize = CGSize.init(
                        width: Double(isLandscape ? width : height),
                        height: Double(isLandscape ? height : width)
                    )
                } catch {
                    print("Failed to set resolution to orientation \(orientation)")
                }
            }
        }
    }

    @objc
    private func didEnterBackground(_: Notification) {
        self.stopStream()
    }
}

public protocol MyLiveDelegate: AnyObject {
    /// Called when the connection to the rtmp server is successful
    func connectionSuccess()

    /// Called when the connection to the rtmp server failed
    func connectionFailed(_ code: String)

    /// Called when the connection to the rtmp server is closed
    func disconnection()

    /// Called if an error happened during the audio configuration
    func audioError(_ error: Error)

    /// Called if an error happened during the video configuration
    func videoError(_ error: Error)
}

extension AVCaptureVideoOrientation {
    var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
}

public enum LiveStreamError: Error {
    case IllegalArgumentError(String)
    case IllegalOperationError(String)
}

