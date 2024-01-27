
# mylive_libraly

mylive_libraly is a flutter library for video streaming using SRT and RTMP.
This library is used in Its my Live.

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
      url: 'srt://10.221.58.8:5000',
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

mylive_libraly Flutter live stream library is using external native library:

|OS |Plugin |README |
|--|--|--|
|Android |StreamPack | [StreamPack] |
|iOS |HaishinKit | [HaishinKit] |

[StreamPack]: <https://github.com/ThibaultBee/StreamPack>

[HaishinKit]: <https://github.com/shogo4405/HaishinKit.swift>



