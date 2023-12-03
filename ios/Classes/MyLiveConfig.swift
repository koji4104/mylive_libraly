import Foundation
import Network

public struct MyLiveAudioConfig {
    public let bitrate: Int
    public init(bitrate: Int = 128_000) {
        self.bitrate = bitrate
    }
}

public struct MyLiveVideoConfig {
    public let bitrate: Int
    public let width: Int
    public let height: Int
    public let fps: Float64
    public let gopDuration: TimeInterval

    public init(
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = 1_000_000
        self.fps = fps
        self.gopDuration = gopDuration
        self.width = 1280
        self.height = 720
    }

    public init(
        bitrate: Int,
        width: Int = 1280,
        height: Int = 720,
        fps: Float64 = 30,
        gopDuration: TimeInterval = 1.0
    ) {
        self.bitrate = bitrate
        self.fps = fps
        self.width = width
        self.height = height
        self.gopDuration = gopDuration
    }
}

enum ConfigurationError: Error {
    case invalidParameter(String)
}
