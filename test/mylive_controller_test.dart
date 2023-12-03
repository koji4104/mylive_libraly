import 'dart:async';
import 'package:mylive_libraly/mylive_config.dart';
import 'package:mylive_libraly/mylive_controller.dart';
import 'package:mylive_libraly/mylive_platform.dart';
import 'package:flutter_test/flutter_test.dart';

// flutter test test/mylive_controller_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final _mockedPlatform = MockedMyLivePlatform();
  MyLivePlatform.instance = _mockedPlatform;
  final _controller = MyLiveController();

  test('initialized', () async {
    await _controller.initialize(url: 'srt://192.168.1.1:5000');
    expect(_mockedPlatform.calls.first, 'create');
  });
}

class MockedMyLivePlatform extends MyLivePlatform {
  Completer<bool> initialized = Completer<bool>();
  List<String> calls = <String>[];

  @override
  Future<int?> create(int mode) {
    calls.add('create');
    initialized.complete(true);
    return Future.value(123);
  }

  @override
  Future<int?> startStream() {
    calls.add('startStream');
    return Future.value();
  }

  @override
  Future<int?> setUrl({String? host, int? port, String? url, String? key}) {
    calls.add('setUrl');
    return Future.value();
  }

  @override
  Future<void> startPreview() {
    calls.add('startPreview');
    return Future.value();
  }

  @override
  Future<void> setVideoConfig(MyLiveVideoConfig videoConfig) {
    calls.add('setVideoConfig');
    return Future.value();
  }

  @override
  Future<void> setAudioConfig(MyLiveAudioConfig audioConfig) {
    calls.add('setAudioConfig');
    return Future.value();
  }

  @override
  Future<void> setCameraPos(int pos) {
    calls.add('setCameraPos');
    return Future.value();
  }

  @override
  Stream<LiveStreamingEvent> liveStreamingEventsFor(int textureId) {
    return StreamController<LiveStreamingEvent>().stream;
  }
}
