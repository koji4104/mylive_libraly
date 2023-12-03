import 'package:flutter/material.dart';
import 'package:mylive_libraly/mylive_libraly.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  MyLiveController _controller = MyLiveController();
  bool _isStreaming = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    var v = MyLiveVideoConfig(
      bitrate: 1000 * 1000,
      fps: 30,
      width: 1280,
      height: 720,
    );
    var a = MyLiveAudioConfig(
      bitrate: 128 * 1000,
      sampleRate: 44100,
    );
    _controller.initialize(
      videoConfig: v,
      audioConfig: a,
      cameraPos: 1,
      url: 'rtmp://192.168.1.1:1935/live',
      key: 'live',
      onConnected: () {
        print('-- onConnected');
        setState(() => _isStreaming = true);
      },
      onFailed: (error) {
        print('-- onFailed: $error');
        setState(() => _isStreaming = false);
      },
      onDisconnected: (message) {
        print('-- onDisconnected: $message');
        setState(() => _isStreaming = false);
      },
      onError: (error) {
        print('-- onError: $error');
        setState(() => _isStreaming = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: Stack(
          children: <Widget>[
            Center(child: MyLivePreview(controller: _controller)),
            Center(
              child: IconButton(
                icon: Icon(Icons.play_circle_outline, color: _isStreaming ? Colors.redAccent : Colors.greenAccent),
                iconSize: 100.0,
                onPressed: () => _isStreaming ? onStop() : onStart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future onStart() async {
    _controller.startStream();
  }

  Future onStop() async {
    _controller.stopStream();
  }
}
