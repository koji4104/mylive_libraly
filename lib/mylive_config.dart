class MyLiveVideoConfig {
  /// bps
  int bitrate = 1000 * 1000;

  /// width e.g. 640, 854, 1280, 1920, 2560, 3840
  int width = 1280;

  /// height e.g. 360, 480, 720, 1080, 1440, 2160
  int height = 720;

  /// fps e.g. 30, 60
  int fps = 30;

  MyLiveVideoConfig({this.bitrate = 1000 * 1000, this.width = 1280, this.height = 720, this.fps = 30});
}

class MyLiveAudioConfig {
  /// The video bitrate in bps
  int bitrate = 128 * 1000;

  /// sample rate
  int sampleRate = 44100;

  MyLiveAudioConfig({this.bitrate = 128 * 1000, this.sampleRate = 44100});
}
