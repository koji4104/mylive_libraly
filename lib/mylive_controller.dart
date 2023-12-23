import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'mylive_config.dart';
import 'mylive_platform.dart';

MyLivePlatform get _platform {
  return MyLivePlatform.instance;
}

class MyLiveController {
  int _textureId = -1;
  int get textureId => _textureId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int _mode = 0;
  String _url = "";
  String? _key;
  bool get isSrt => (_mode == 0);

  /// Events
  StreamSubscription<dynamic>? _eventSubscription;
  List<MyLiveEventsListener> _eventsListeners = [];
  List<MyLiveWidgetListener> _widgetListeners = [];

  MyLiveController() {}

  MyLiveController.fromListener({MyLiveEventsListener? listener}) {
    if (listener != null) {
      _eventsListeners.add(listener);
    }
  }

  Future<void> initialize({
    MyLiveVideoConfig? videoConfig,
    MyLiveAudioConfig? audioConfig,
    int? cameraPos,
    required String url,
    String? key,
    VoidCallback? onConnected,
    Function(String)? onFailed,
    Function(String)? onDisconnected,
    Function(PlatformException)? onError,
  }) async {
    _isInitialized = false;
    await stopPreview().catchError((e) {});

    _eventsListeners.add(
      MyLiveEventsListener(
        onConnected: onConnected,
        onFailed: onFailed,
        onDisconnected: onDisconnected,
        onError: onError,
      ),
    );

    _mode = (url.contains('srt://')) ? 0 : 1;
    _textureId = await _platform.create(_mode) ?? -1;

    print('-- initialize() _textureId=${_textureId}');
    if (_textureId < 0) throw Exception("isInitialized error");

    _eventSubscription = _platform.liveStreamingEventsFor(_textureId).listen(
          _eventListener,
          onError: _errorListener,
        );

    _url = url;
    _key = key;
    _platform.setUrl(url: _url, key: _key);

    for (var listener in [..._widgetListeners]) {
      if (listener.onTextureReady != null) {
        listener.onTextureReady!();
      }
    }

    if (videoConfig == null) videoConfig = MyLiveVideoConfig();
    if (audioConfig == null) audioConfig = MyLiveAudioConfig();
    if (cameraPos == null) cameraPos = 0;

    await setVideoConfig(videoConfig).onError((error, stackTrace) {
      print('-- setVideoConfig $error');
      return;
    });
    await setAudioConfig(audioConfig).onError((error, stackTrace) {
      print('-- setAudioConfig $error');
      return;
    });
    await setCameraPos(cameraPos);
    await startPreview().onError((error, stackTrace) {
      print('-- startPreview $error');
      return;
    });
    _isInitialized = true;
    return;
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventsListeners.clear();
    _widgetListeners.clear();
    await _platform.dispose();
    return;
  }

  Future<void> setVideoConfig(MyLiveVideoConfig videoConfig) {
    return _platform.setVideoConfig(videoConfig);
  }

  Future<void> setAudioConfig(MyLiveAudioConfig audioConfig) {
    return _platform.setAudioConfig(audioConfig);
  }

  Future<void> startStream() async {
    return _platform.startStream().catchError((e) {
      _errorListener(e);
    });
  }

  Future<void> stopStream() {
    return _platform.stopStream();
  }

  Future<void> startPreview() {
    return _platform.startPreview();
  }

  Future<void> stopPreview() {
    return _platform.stopPreview();
  }

  Future<void> setMute(bool mute) {
    return _platform.setMute(mute);
  }

  Future<bool> isStreaming() {
    return _platform.isStreaming();
  }

  Future<int> getCameraPos() async {
    return _platform.getCameraPos();
  }

  /// Sets camera position 0=back 1=front
  Future<void> setCameraPos(int pos) {
    return _platform.setCameraPos(pos);
  }

  Future<int> getCurrentFps() async {
    return await _platform.getCurrentFps() ?? 0;
  }

  /// Builds the preview widget.
  @internal
  Widget buildPreview() {
    return Texture(textureId: textureId);
  }

  void addEventsListener(MyLiveEventsListener listener) {
    _eventsListeners.add(listener);
  }

  void removeEventsListener(MyLiveEventsListener listener) {
    _eventsListeners.remove(listener);
  }

  @internal
  void addWidgetListener(MyLiveWidgetListener listener) {
    _widgetListeners.add(listener);
  }

  @internal
  void removeWidgetListener(MyLiveWidgetListener listener) {
    _widgetListeners.remove(listener);
  }

  void _errorListener(Object obj) {
    final PlatformException e = obj as PlatformException;
    for (var listener in [..._eventsListeners]) {
      if (listener.onError != null) {
        listener.onError!(e);
      }
    }
  }

  void _eventListener(LiveStreamingEvent event) {
    switch (event.type) {
      case LiveStreamingEventType.connected:
        for (var listener in [..._eventsListeners]) {
          if (listener.onConnected != null) {
            listener.onConnected!();
          }
        }
        break;
      case LiveStreamingEventType.disconnected:
        for (var listener in [..._eventsListeners]) {
          if (listener.onDisconnected != null) {
            listener.onDisconnected!(event.data as String);
          }
        }
        break;
      case LiveStreamingEventType.failed:
        for (var listener in [..._eventsListeners]) {
          if (listener.onFailed != null) {
            listener.onFailed!(event.data as String);
          }
        }
        break;
      case LiveStreamingEventType.videoSizeChanged:
        for (var listener in [..._eventsListeners]) {
          if (listener.onVideoSizeChanged != null) {
            listener.onVideoSizeChanged!(event.data as Size);
          }
        }
        break;
      case LiveStreamingEventType.unknown:
        // Nothing to do
        break;
    }
  }
}

class MyLiveEventsListener {
  final VoidCallback? onConnected;
  final Function(String)? onFailed;
  final Function(String)? onDisconnected;
  final Function(Size)? onVideoSizeChanged;
  final Function(PlatformException)? onError;

  MyLiveEventsListener({
    this.onConnected,
    this.onFailed,
    this.onDisconnected,
    this.onVideoSizeChanged,
    this.onError,
  });
}

class MyLiveWidgetListener {
  final VoidCallback? onTextureReady;
  MyLiveWidgetListener({this.onTextureReady});
}
