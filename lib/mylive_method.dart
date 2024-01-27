import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'mylive_platform.dart';
import 'mylive_config.dart';

class MyLiveChannel extends MyLivePlatform {
  final MethodChannel _channel = const MethodChannel('com.koji4104.mylive_libraly/controller');

  static void registerWith() {
    MyLivePlatform.instance = MyLiveChannel();
  }

  @override
  Future<int?> create(int mode) async {
    Map<String, dynamic> map = {'mode': mode};
    final Map<String, dynamic>? reply = await _channel.invokeMapMethod<String, dynamic>('create', map);
    return reply!['textureId']! as int;
  }

  @override
  Future<void> dispose() {
    return _channel.invokeMapMethod<String, dynamic>('dispose');
  }

  @override
  Future<void> setVideoConfig(MyLiveVideoConfig videoConfig) {
    Map<String, dynamic> map = {
      'bitrate': videoConfig.bitrate,
      'fps': videoConfig.fps,
      'width': videoConfig.width,
      'height': videoConfig.height,
    };
    return _channel.invokeMethod('setVideoConfig', map);
  }

  @override
  Future<void> setAudioConfig(MyLiveAudioConfig audioConfig) {
    Map<String, dynamic> map = {
      'bitrate': audioConfig.bitrate,
      'sampleRate': audioConfig.sampleRate,
    };
    return _channel.invokeMethod('setAudioConfig', map);
  }

  Future<void> disconnect() {
    return _channel.invokeMethod('disconnect');
  }

  @override
  Future<void> setUrl({String? url, String? key}) {
    return _channel.invokeMethod('setUrl', <String, dynamic>{
      'url': url,
      'key': key,
    });
  }

  @override
  Future<void> startStream() {
    return _channel.invokeMethod('startStream');
  }

  @override
  Future<void> stopStream() {
    return _channel.invokeMethod('stopStream');
  }

  @override
  Future<void> startPreview() {
    return _channel.invokeMethod('startPreview');
  }

  @override
  Future<void> stopPreview() {
    return _channel.invokeMethod('stopPreview');
  }

  @override
  Future<void> setMute(bool mute) {
    return _channel.invokeMethod('setMute', <String, dynamic>{'mute': mute});
  }

  @override
  Future<bool> isStreaming() async {
    final Map<dynamic, dynamic> reply = await _channel.invokeMethod('isStreaming') as Map;
    return reply['isStreaming'] as bool;
  }

  @override
  Future<int> getCameraPos() async {
    final Map<dynamic, dynamic> reply = await _channel.invokeMethod('getCameraPos') as Map;
    String strpos = reply['pos'] as String;
    return strpos == 'front' ? 1 : 0;
  }

  @override
  Future<void> setCameraPos(int pos) {
    String spos = pos == 0 ? 'back' : 'front';
    return _channel.invokeMethod('setCameraPos', <String, dynamic>{'pos': spos});
  }

  @override
  Future<void> setCameraZoom(int zoom) {
    return _channel.invokeMethod('setCameraZoom', <String, dynamic>{'zoom': zoom});
  }

  @override
  Future<int?> getCurrentFps() async {
    final Map<dynamic, dynamic>? reply = await _channel.invokeMethod('getCurrentFps') as Map;
    return reply!['fps']! as int;
  }

  @override
  Future<Size?> getVideoSize() async {
    final Map<dynamic, dynamic> reply = await _channel.invokeMethod('getVideoSize') as Map;
    if (reply.containsKey("width") && reply.containsKey("height")) {
      return Size(reply["width"] as double, reply["height"] as double);
    } else {
      return null;
    }
  }

  @override
  Future<void> startPlayback() async {
    return _channel.invokeMethod('startPlayback');
  }

  @override
  Future<void> stopPlayback() async {
    return _channel.invokeMethod('stopPlayback');
  }

  /// Builds the preview widget.
  @override
  Widget buildPreview(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Stream<LiveStreamingEvent> liveStreamingEventsFor(int textureId) {
    return EventChannel('com.koji4104.mylive_libraly/events').receiveBroadcastStream().map((dynamic map) {
      final Map<dynamic, dynamic> event = map as Map<dynamic, dynamic>;
      switch (event['type']) {
        case 'connected':
          return LiveStreamingEvent(type: LiveStreamingEventType.connected);
        case 'disconnected':
          return LiveStreamingEvent(type: LiveStreamingEventType.disconnected, data: event['message']);
        case 'failed':
          return LiveStreamingEvent(type: LiveStreamingEventType.failed, data: event['message']);
        case 'videoSizeChanged':
          return LiveStreamingEvent(
              type: LiveStreamingEventType.videoSizeChanged,
              data: Size(event['width'] as double, event['height'] as double));
        default:
          return LiveStreamingEvent(type: LiveStreamingEventType.unknown);
      }
    });
  }
}
