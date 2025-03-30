import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'mylive_controller.dart';

class MyLivePreview extends StatefulWidget {
  const MyLivePreview({super.key, required this.controller, this.child});

  /// A widget to overlay on top of the camera preview
  final Widget? child;

  /// The controller for the camera to display the preview for.
  final MyLiveController controller;

  @override
  State<MyLivePreview> createState() => _MyLivePreviewState();
}

class _MyLivePreviewState extends State<MyLivePreview> {
  _MyLivePreviewState() {
    _widgetListener = MyLiveWidgetListener(onTextureReady: () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    });
    _eventsListener = MyLiveEventsListener(onVideoSizeChanged: (size) {
      _updateAspectRatio(size);
    });
  }

  late MyLiveWidgetListener _widgetListener;
  late MyLiveEventsListener _eventsListener;
  late int _textureId;
  double _aspectRatio = 1280 / 720;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    widget.controller.addWidgetListener(_widgetListener);
    widget.controller.addEventsListener(_eventsListener);
    if (widget.controller.isInitialized) {
      _updateAspectRatio(null);
      //widget.controller.videoSize.then((size) {
      //  _updateAspectRatio(size);
      //});
    }
  }

  @override
  void dispose() {
    widget.controller.stopPreview();
    widget.controller.removeWidgetListener(_widgetListener);
    widget.controller.removeEventsListener(_eventsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == -1 ? Container() : buildPreview(context);
  }

  Widget buildPreview(BuildContext context) {
    return NativeDeviceOrientationReader(
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);
        double _scale = 1.1;
        return Transform.scale(
          scale: _scale,
          child: AspectRatio(
            aspectRatio: _isLandscape(orientation) ? _aspectRatio : 1 / _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _wrapInRotatedBox(orientation: orientation, child: widget.controller.buildPreview()),
                widget.child ?? Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wrapInRotatedBox({required NativeDeviceOrientation orientation, required Widget child}) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return child;
    }

    return RotatedBox(
      quarterTurns: _getQuarterTurns(orientation),
      child: child,
    );
  }

  bool _isLandscape(NativeDeviceOrientation orientation) {
    return [NativeDeviceOrientation.landscapeLeft, NativeDeviceOrientation.landscapeRight].contains(orientation);
  }

  int _getQuarterTurns(NativeDeviceOrientation orientation) {
    Map<NativeDeviceOrientation, int> turns = {
      NativeDeviceOrientation.unknown: 0,
      NativeDeviceOrientation.portraitUp: 0,
      NativeDeviceOrientation.landscapeRight: 1,
      NativeDeviceOrientation.portraitDown: 2,
      NativeDeviceOrientation.landscapeLeft: 3,
    };
    return turns[orientation]!;
  }

  void _updateAspectRatio(Size? size) async {
    double newAspectRatio;
    if (size != null) {
      newAspectRatio = size.aspectRatio;
    } else {
      newAspectRatio = 1.77;
    }

    if (newAspectRatio != _aspectRatio) {
      setState(() {
        _aspectRatio = newAspectRatio;
      });
    }
  }
}
