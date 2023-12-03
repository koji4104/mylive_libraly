import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'mylive_config.dart';

abstract class MyLivePlatform extends PlatformInterface {
  MyLivePlatform() : super(token: _token);

  static final Object _token = Object();
  static MyLivePlatform _instance = _PlatformImplementation();

  static MyLivePlatform get instance => _instance;

  static set instance(MyLivePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Creates a new live stream instance
  Future<int?> create(int mode) {
    throw UnimplementedError('create() has not been implemented.');
  }

  /// Disposes the live stream instance
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Future<void> setVideoConfig(MyLiveVideoConfig videoConfig) {
    throw UnimplementedError('setVideoConfig() has not been implemented.');
  }

  Future<void> setAudioConfig(MyLiveAudioConfig audioConfig) {
    throw UnimplementedError('setAudioConfig() has not been implemented.');
  }

  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Future<void> setUrl({String? url, String? key}) {
    throw UnimplementedError('setUrl() has not been implemented.');
  }

  Future<void> startStream() {
    throw UnimplementedError('startStream() has not been implemented.');
  }

  Future<void> stopStream() {
    throw UnimplementedError('stopStream() has not been implemented.');
  }

  Future<void> startPreview() {
    throw UnimplementedError('startPreview() has not been implemented.');
  }

  Future<void> stopPreview() {
    throw UnimplementedError('stopPreview() has not been implemented.');
  }

  Future<void> setMute(bool mute) {
    throw UnimplementedError('setMute() has not been implemented.');
  }

  Future<bool> isStreaming() {
    throw UnimplementedError('isStreaming() has not been implemented.');
  }

  Future<int> getCameraPos() {
    throw UnimplementedError('getCameraPos() has not been implemented.');
  }

  Future<void> setCameraPos(int pos) {
    throw UnimplementedError('setCameraPos() has not been implemented.');
  }

  Future<int?> getCurrentFps() {
    throw UnimplementedError('getCurrentFps() has not been implemented.');
  }

  Future<Size?> getVideoSize() {
    throw UnimplementedError('getVideoSize() has not been implemented.');
  }

  /// Returns a Stream of [LiveStreamingEvent]s.
  Stream<LiveStreamingEvent> liveStreamingEventsFor(int textureId) {
    throw UnimplementedError('liveStreamingEventsFor() has not been implemented.');
  }

  Widget buildPreview(int textureId) {
    throw UnimplementedError('buildPreview() has not been implemented.');
  }
}

class _PlatformImplementation extends MyLivePlatform {}

class LiveStreamingEvent {
  /// Adds optional parameters here if needed
  final Object? data;

  /// The [LiveStreamingEventType]
  final LiveStreamingEventType type;

  LiveStreamingEvent({required this.type, this.data});
}

enum LiveStreamingEventType {
  /// The live streaming is connected.
  connected,

  /// The live streaming has just been disconnected.
  disconnected,

  /// The connection to the server failed.
  failed,

  videoSizeChanged,

  /// Unknown event
  unknown
}
