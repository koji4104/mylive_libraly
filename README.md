
# mylive_libraly

― mylive_libraly is a library for video streaming using SRT and RTMP.

# Getting started

## Installation

In your pubspec.yaml file, add the following:

```yaml
dependencies:
  mylive_libraly: ^0.1.0
```

In your dart file, import the package:

```dart 
import 'package:mylive_libraly/mylive_libraly.dart';
```

## Code sample


```dart

  MyLiveController _controller = MyLiveController();

      _controller.initialize(
      cameraPosition: 1,
      url: 'srt://10.221.58.8:3000',
      onConnected: () {
        print('---- onConnected');
      },
      onFailed: (error) {
        print('---- onFailed: $error');
      },
      onDisconnected: (message) {
        print('---- onDisconnected: $message');
      },
      onError: (error) {
        print('---- onError: $error');
      },
    );
```


# Plugins

srt_live_stream Flutter live stream library is using external native library:

| Plugin     | README       |
|------------|--------------|
| StreamPack | [StreamPack] |
| HaishinKit | [HaishinKit] |


[StreamPack]: <https://github.com/ThibaultBee/StreamPack>

[HaishinKit]: <https://github.com/shogo4405/HaishinKit.swift>



