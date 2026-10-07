import 'dart:math' as math;

/// How the scene preview plays an OBS scene transition. Mirrors the look of
/// OBS' built-in transitions (`plugins/obs-transitions` in obs-studio) -
/// see docs/superpowers/specs/2026-10-06-preview-transitions-design.md
enum PreviewTransitionKind {
  /// Swap without animation (`cut_transition`)
  cut,

  /// Linear crossfade (`fade_transition`, and the stand-in for transitions
  /// we can't reproduce, e.g. Move)
  fade,

  /// Fade to a color, then from it (`fade_to_color_transition`)
  fadeToColor,

  /// The incoming (or outgoing) scene moves over the other one
  /// (`swipe_transition`)
  swipe,

  /// Both scenes move (`slide_transition`)
  slide,

  /// Luma mask wipe (`wipe_transition`)
  lumaWipe,

  /// Hold the old frame, swap at the end (`obs_stinger_transition` - its
  /// video lives inside the transition and never shows in a screenshot)
  cutAtEnd,
}

/// Direction setting of swipe / slide - the content moves this way
enum PreviewTransitionDirection { left, right, up, down }

/// Everything the painter needs to draw one transition
class PreviewTransitionSpec {
  final PreviewTransitionKind kind;

  /// How long the animation runs
  final Duration duration;

  /// [PreviewTransitionKind.swipe] / [PreviewTransitionKind.slide]
  final PreviewTransitionDirection direction;

  /// [PreviewTransitionKind.swipe]: the incoming scene moves in over the
  /// old one (true) instead of the old one moving off (false)
  final bool swipeIn;

  /// [PreviewTransitionKind.fadeToColor]: ARGB color faded through
  final int color;

  /// [PreviewTransitionKind.fadeToColor]: 0..1 point of the swap
  final double switchPoint;

  /// [PreviewTransitionKind.lumaWipe]: mask file name (OBS' `luma_image`)
  final String lumaImage;

  /// [PreviewTransitionKind.lumaWipe]
  final double lumaSoftness;

  /// [PreviewTransitionKind.lumaWipe]
  final bool lumaInvert;

  /// [PreviewTransitionKind.cutAtEnd] built from a stinger: when the swap
  /// happens, counted from the transition start (the tracker turns it into
  /// [duration] once the first incoming frame is there)
  final Duration? stingerPoint;

  const PreviewTransitionSpec({
    required this.kind,
    required this.duration,
    this.direction = PreviewTransitionDirection.left,
    this.swipeIn = false,
    this.color = 0xFF000000,
    this.switchPoint = 0.5,
    this.lumaImage = kDefaultLumaImage,
    this.lumaSoftness = 0.03,
    this.lumaInvert = false,
    this.stingerPoint,
  });

  static const PreviewTransitionSpec none = PreviewTransitionSpec(
    kind: PreviewTransitionKind.cut,
    duration: Duration.zero,
  );

  /// Nothing to animate
  bool get isCut =>
      kind == PreviewTransitionKind.cut || duration <= Duration.zero;

  PreviewTransitionSpec withDuration(Duration duration) =>
      PreviewTransitionSpec(
        kind: kind,
        duration: duration,
        direction: direction,
        swipeIn: swipeIn,
        color: color,
        switchPoint: switchPoint,
        lumaImage: lumaImage,
        lumaSoftness: lumaSoftness,
        lumaInvert: lumaInvert,
        stingerPoint: stingerPoint,
      );

  @override
  String toString() =>
      'PreviewTransitionSpec(${kind.name}, ${duration.inMilliseconds} ms)';
}

/// OBS' default luma wipe mask (`luma_wipe_defaults`)
const String kDefaultLumaImage = 'linear-h.png';

/// The masks OBS ships in `plugins/obs-transitions/data/luma_wipes` - bundled
/// under `assets/luma_wipes/`. A user can drop their own PNG into OBS'
/// folder; those fall back to a crossfade
const Set<String> kBundledLumaImages = {
  'barndoor-botleft.png',
  'barndoor-h.png',
  'barndoor-topleft.png',
  'barndoor-v.png',
  'blinds-h.png',
  'box-botleft.png',
  'box-botright.png',
  'box-topleft.png',
  'box-topright.png',
  'burst.png',
  'checkerboard-small.png',
  'circles.png',
  'clock.png',
  'cloud.png',
  'curtain.png',
  'fan.png',
  'fractal.png',
  'iris.png',
  'linear-h.png',
  'linear-topleft.png',
  'linear-topright.png',
  'linear-v.png',
  'parallel-zigzag-h.png',
  'parallel-zigzag-v.png',
  'sinus9.png',
  'spiral.png',
  'square.png',
  'squares.png',
  'stripes.png',
  'strips-h.png',
  'strips-v.png',
  'watercolor.png',
  'zigzag-h.png',
  'zigzag-v.png',
};

/// Default duration when nothing better is known (OBS' own default)
const Duration kDefaultTransitionDuration = Duration(milliseconds: 300);

/// Builds the spec for an OBS transition [kind] with its [settings] (as
/// `GetCurrentSceneTransition` returns them - defaults left out, so every
/// missing key falls back to OBS' default) and its [duration].
///
/// [fps] (OBS' output frame rate) only matters for a stinger whose transition
/// point is given in frames.
PreviewTransitionSpec resolvePreviewTransitionSpec({
  required String? kind,
  Map<String, dynamic>? settings,
  Duration? duration,
  double? fps,
}) {
  final Map<String, dynamic> s = settings ?? const {};
  final Duration d = duration ?? kDefaultTransitionDuration;

  switch (kind) {
    case 'cut_transition':
      return PreviewTransitionSpec.none;
    case 'fade_transition':
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.fade,
        duration: d,
      );
    case 'fade_to_color_transition':
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.fadeToColor,
        duration: d,
        color: obsColorToArgb(_int(s['color']) ?? 0xFF000000),
        switchPoint: ((_int(s['switch_point']) ?? 50) / 100.0).clamp(0.0, 1.0),
      );
    case 'swipe_transition':
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.swipe,
        duration: d,
        direction: _direction(s['direction']),
        swipeIn: s['swipe_in'] == true,
      );
    case 'slide_transition':
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.slide,
        duration: d,
        direction: _direction(s['direction']),
      );
    case 'wipe_transition':
      final String image = (s['luma_image'] as String?)?.isNotEmpty == true
          ? s['luma_image'] as String
          : kDefaultLumaImage;

      /// A custom mask lives only on the OBS machine
      if (!kBundledLumaImages.contains(image)) {
        return PreviewTransitionSpec(
          kind: PreviewTransitionKind.fade,
          duration: d,
        );
      }
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.lumaWipe,
        duration: d,
        lumaImage: image,
        lumaSoftness: (_double(s['luma_softness']) ?? 0.03).clamp(0.0, 1.0),
        lumaInvert: s['luma_invert'] == true,
      );
    case 'obs_stinger_transition':
      final int point = _int(s['transition_point']) ?? 0;
      final bool inFrames = _int(s['tp_type']) == 1;
      final double pointMs = inFrames
          ? (fps != null && fps > 0 ? point * 1000.0 / fps : 0.0)
          : point.toDouble();
      final Duration stingerPoint = Duration(
        milliseconds: math.max(0, pointMs.round()),
      );
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.cutAtEnd,
        duration: stingerPoint,
        stingerPoint: stingerPoint,
      );

    /// Plugin transitions (Move, shaders, ...) and unknown kinds
    default:
      return PreviewTransitionSpec(
        kind: PreviewTransitionKind.fade,
        duration: d,
      );
  }
}

/// OBS stores colors as ABGR ints (`vec4_from_rgba`: red in the low byte);
/// the fade-to-color transition forces full alpha
int obsColorToArgb(int obsColor) {
  final int r = obsColor & 0xFF;
  final int g = (obsColor >> 8) & 0xFF;
  final int b = (obsColor >> 16) & 0xFF;
  return 0xFF000000 | (r << 16) | (g << 8) | b;
}

/// `cubic_ease_in_out` of `plugins/obs-transitions/easings.h`
double cubicEaseInOut(double t) {
  if (t < 0.5) return 4.0 * t * t * t;
  final double temp = 2.0 * t - 2.0;
  return (t - 1.0) * temp * temp + 1.0;
}

/// HLSL `smoothstep`
double smoothstep(double edge0, double edge1, double x) {
  if (edge1 <= edge0) return x < edge0 ? 0.0 : 1.0;
  final double t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

PreviewTransitionDirection _direction(Object? value) => switch (value) {
  'right' => PreviewTransitionDirection.right,
  'up' => PreviewTransitionDirection.up,
  'down' => PreviewTransitionDirection.down,
  _ => PreviewTransitionDirection.left,
};

int? _int(Object? value) => value is num ? value.toInt() : null;

double? _double(Object? value) => value is num ? value.toDouble() : null;
