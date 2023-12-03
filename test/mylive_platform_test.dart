import 'package:mylive_libraly/mylive_method.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// flutter test test/mylive_platform_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel("com.koji4104.mylive_libraly/controller");
  final _platform = MyLiveChannel();

  test('startStream', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (MethodCall methodCall) async {
      throw Exception();
    });
    expect(_platform.startStream(), throwsException);
  });
}
