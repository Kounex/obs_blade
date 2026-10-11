import 'package:release/src/commands.dart';
import 'package:test/test.dart';

/// Apple's live video specs (GET v1/appAssetLibraryRefData -> videoSpecs,
/// 2026-10-11) for the two creative-asset slots.
const header = <String, Object?>{
  'shortName': 'v3840x1646f30f60t10~30u0',
  'aspectRatio': '21:9',
  'dimensions': {
    'minWidth': 3840,
    'maxWidth': 3840,
    'minHeight': 1646,
    'maxHeight': 1646,
  },
  'compatiblePlacementTypes': ['PRODUCT_PAGE_HEADER_ASSET'],
  'frameRates': [
    {'minFps': 30, 'maxFps': 30},
    {'minFps': 60, 'maxFps': 60},
  ],
  'duration': {'min': 'PT5S', 'max': 'PT30S'},
  'audioRequired': false,
  'fileExtensions': ['.mp4', '.m4v', '.mov'],
  'maxFileSize': 524288000,
};
const search = <String, Object?>{
  'shortName': 'v3x2w1920~3840f30f60t15~30u0',
  'aspectRatio': '3:2',
  'dimensions': {
    'minWidth': 1920,
    'maxWidth': 3840,
    'minHeight': 1280,
    'maxHeight': 2560,
  },
  'compatiblePlacementTypes': ['APP_STORE_SEARCH_RESULTS_ASSET'],
  'frameRates': [
    {'minFps': 30, 'maxFps': 30},
    {'minFps': 60, 'maxFps': 60},
  ],
  'duration': {'min': 'PT5S', 'max': 'PT30S'},
  'audioRequired': false,
  'fileExtensions': ['.mp4', '.m4v', '.mov'],
  'maxFileSize': 524288000,
};

VideoFacts video(
  int w,
  int h, {
  double fps = 30,
  double duration = 10,
  bool audio = false,
}) => (w: w, h: h, fps: fps, duration: duration, audio: audio);

String? miss(
  Map<String, Object?> spec,
  VideoFacts v, {
  int bytes = 30000000,
  String name = 'header.mp4',
}) => Release.videoSpecMiss(spec, v, bytes: bytes, fileName: name);

void main() {
  test('ISO 8601 durations from the ref data', () {
    expect(Release.isoSeconds('PT5S'), 5);
    expect(Release.isoSeconds('PT30S'), 30);
    expect(Release.isoSeconds('PT1M'), 60);
    expect(Release.isoSeconds('PT1M2.5S'), 62.5);
    expect(Release.isoSeconds('PT'), isNull);
    expect(Release.isoSeconds(null), isNull);
  });

  test('a silent 10 s 30 fps header video fits the header spec only', () {
    final v = video(3840, 1646);
    expect(miss(header, v), isNull);
    expect(miss(search, v), startsWith('size'));
  });

  test('search takes any 3:2 size in range, at 30 or 60 fps', () {
    expect(miss(search, video(3840, 2560), name: 'search.mp4'), isNull);
    expect(
      miss(search, video(1920, 1280, fps: 60), name: 'search.mov'),
      isNull,
    );
    expect(miss(search, video(1600, 1067)), startsWith('size'));
  });

  test('frame rate, duration, file size and type are checked', () {
    expect(miss(header, video(3840, 1646, fps: 24)), contains('fps'));
    expect(miss(header, video(3840, 1646, fps: 29.97)), contains('fps'));
    expect(miss(header, video(3840, 1646, duration: 4)), contains('s ('));
    // a container a frame past the cut still fits
    expect(miss(header, video(3840, 1646, duration: 30.033)), isNull);
    expect(miss(header, video(3840, 1646, duration: 31)), contains('s ('));
    expect(miss(header, video(3840, 1646), bytes: 600000000), contains('MB'));
    expect(
      miss(header, video(3840, 1646), name: 'header.webm'),
      startsWith('file type'),
    );
  });

  test('image sizes match their spec by aspect ratio too', () {
    expect(Release.fitsSpec(search, (3840, 1646)), isFalse);
    expect(Release.fitsSpec(search, (3840, 2560)), isTrue);
    expect(Release.fitsSpec(header, (3840, 1646)), isTrue);
    const universal = {
      'aspectRatio': '16:9',
      'dimensions': {
        'minWidth': 5244,
        'maxWidth': 5244,
        'minHeight': 2950,
        'maxHeight': 2950,
      },
    };
    expect(Release.fitsSpec(universal, (5244, 2950)), isTrue);
  });

  test('a spec that wants audio rejects a silent video', () {
    final withAudio = {...header, 'audioRequired': true};
    expect(miss(withAudio, video(3840, 1646)), 'no audio track');
    expect(miss(withAudio, video(3840, 1646, audio: true)), isNull);
  });

  test('spec names carry their own minimum length', () {
    expect(Release.specNameMinSeconds('v3840x1646f30f60t10~30u0'), 10);
    expect(Release.specNameMinSeconds('v3x2w1920~3840f30f60t15~30u0'), 15);
    expect(Release.specNameMinSeconds('i3840x1646'), isNull);
  });

  test('poster time codes count frames at the video frame rate', () {
    expect(Release.timeCode(0, fps: 60), '00:00:00:00');
    expect(Release.timeCode(2.5, fps: 60), '00:00:02:30');
    expect(Release.timeCode(2.5), '00:00:02:15');
  });

  test('video files are told apart by extension', () {
    expect(Release.isVideo('fastlane/assets/ios/header.mp4'), isTrue);
    expect(Release.isVideo('Header.MOV'), isTrue);
    expect(Release.isVideo('header.png'), isFalse);
  });
}
