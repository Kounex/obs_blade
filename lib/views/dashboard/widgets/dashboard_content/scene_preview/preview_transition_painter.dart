import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../../utils/general_helper.dart';
import '../../../../../utils/preview_transition/preview_transition_spec.dart';

/// Paints one frame of an OBS scene transition between two preview frames,
/// with the math of OBS' own transitions (`plugins/obs-transitions`) so the
/// preview moves like the program does. Draws into the [BoxFit.contain] rect
/// of [to] - the same rect the live preview image takes.
class PreviewTransitionPainter extends CustomPainter {
  PreviewTransitionPainter({
    required this.from,
    required this.to,
    required this.spec,
    required this.progress,
    this.lumaProgram,
    this.lumaMask,
  }) : super(repaint: progress);

  /// Last frame of the old scene
  final ui.Image from;

  /// Latest frame of the new scene
  final ui.Image to;

  final PreviewTransitionSpec spec;

  /// Linear 0..1 - each kind applies its own easing like OBS
  final Animation<double> progress;

  /// Both set for [PreviewTransitionKind.lumaWipe]; without them it fades
  final ui.FragmentProgram? lumaProgram;
  final ui.Image? lumaMask;

  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect dest = _containRect(size, to);
    if (dest.isEmpty) return;
    final double t = progress.value.clamp(0.0, 1.0);

    canvas.save();
    canvas.clipRect(dest);
    switch (spec.kind) {
      case PreviewTransitionKind.cut:
      case PreviewTransitionKind.cutAtEnd:
        _draw(canvas, from, dest);
      case PreviewTransitionKind.fade:
        _fade(canvas, dest, t);
      case PreviewTransitionKind.fadeToColor:
        _fadeToColor(canvas, dest, t);
      case PreviewTransitionKind.swipe:
        _swipe(canvas, dest, t);
      case PreviewTransitionKind.slide:
        _slide(canvas, dest, t);
      case PreviewTransitionKind.lumaWipe:
        if (lumaProgram != null && lumaMask != null) {
          _lumaWipe(canvas, dest, t);
        } else {
          _fade(canvas, dest, t);
        }
    }
    canvas.restore();
  }

  /// `fade_transition`: lerp(a, b, t) in the frames' own (sRGB) space -
  /// OBS' default "nonlinear" fade
  void _fade(Canvas canvas, Rect dest, double t) {
    _draw(canvas, from, dest);
    _draw(
      canvas,
      to,
      dest,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(0, 0, 0, t),
    );
  }

  /// `fade_to_color_transition`: a → color until the switch point, then
  /// color → b, each half smoothstepped
  void _fadeToColor(Canvas canvas, Rect dest, double t) {
    final double sp = spec.switchPoint;
    final bool first = t < sp;
    final double amount = first
        ? smoothstep(0.0, sp, t)
        : 1.0 - smoothstep(sp, 1.0, t);
    _draw(canvas, first ? from : to, dest);
    canvas.drawRect(
      dest,
      Paint()..color = Color(spec.color).withValues(alpha: amount),
    );
  }

  /// `swipe_transition`: one frame moves over the other (eased). Out: the
  /// old one leaves towards [PreviewTransitionSpec.direction] over the new
  /// one; in: the new one comes in moving that way over the old one
  void _swipe(Canvas canvas, Rect dest, double t) {
    final double e = cubicEaseInOut(t);
    final Offset dir = _direction(dest);
    if (spec.swipeIn) {
      _draw(canvas, from, dest);
      _draw(canvas, to, dest.shift(-dir * (1.0 - e)));
    } else {
      _draw(canvas, to, dest);
      _draw(canvas, from, dest.shift(dir * e));
    }
  }

  /// `slide_transition`: both move towards the direction (eased)
  void _slide(Canvas canvas, Rect dest, double t) {
    final double e = cubicEaseInOut(t);
    final Offset dir = _direction(dest);
    _draw(canvas, from, dest.shift(dir * e));
    _draw(canvas, to, dest.shift(-dir * (1.0 - e)));
  }

  /// `wipe_transition`: OBS' PSLumaWipe in `shaders/luma_wipe.frag`
  void _lumaWipe(Canvas canvas, Rect dest, double t) {
    final ui.FragmentShader shader = lumaProgram!.fragmentShader()
      ..setFloat(0, dest.width)
      ..setFloat(1, dest.height)
      ..setFloat(2, t)
      ..setFloat(3, spec.lumaSoftness)
      ..setFloat(4, spec.lumaInvert ? 1.0 : 0.0)
      ..setImageSampler(0, from)
      ..setImageSampler(1, to)
      ..setImageSampler(2, lumaMask!);

    /// FlutterFragCoord is local - draw at the origin so uv = coord / size
    canvas.save();
    canvas.translate(dest.left, dest.top);
    canvas.drawRect(Offset.zero & dest.size, Paint()..shader = shader);
    canvas.restore();
    shader.dispose();
  }

  /// Where the content moves, scaled to the frame - OBS' `dir` vector
  /// (uv + dir samples the frame shifted against it)
  Offset _direction(Rect dest) => switch (spec.direction) {
    PreviewTransitionDirection.left => Offset(-dest.width, 0),
    PreviewTransitionDirection.right => Offset(dest.width, 0),
    PreviewTransitionDirection.up => Offset(0, -dest.height),
    PreviewTransitionDirection.down => Offset(0, dest.height),
  };

  void _draw(Canvas canvas, ui.Image image, Rect dest, [Paint? paint]) =>
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dest,
        paint ?? _imagePaint,
      );

  static Rect _containRect(Size size, ui.Image image) {
    final FittedSizes fitted = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      size,
    );
    return Alignment.center.inscribe(fitted.destination, Offset.zero & size);
  }

  @override
  bool shouldRepaint(PreviewTransitionPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.spec != spec ||
      oldDelegate.lumaMask != lumaMask ||
      oldDelegate.lumaProgram != lumaProgram;
}

/// The luma wipe shader and its masks, loaded once and shared
class LumaWipeResources {
  LumaWipeResources._();

  static Future<ui.FragmentProgram?>? _program;
  static final Map<String, Future<ui.Image?>> _masks = {};

  /// null when the shader can't be loaded - the wipe then fades
  static Future<ui.FragmentProgram?> program() =>
      _program ??= ui.FragmentProgram.fromAsset('shaders/luma_wipe.frag')
          .then<ui.FragmentProgram?>((program) => program)
          .catchError((Object error) {
            GeneralHelper.logFailure('Preview luma wipe shader failed', error);
            return null;
          });

  /// One of OBS' masks ([kBundledLumaImages]), null when it can't be loaded
  static Future<ui.Image?> mask(String name) => _masks[name] ??= rootBundle
      .load('assets/luma_wipes/$name')
      .then<ui.Image?>((data) => decodeImageFromList(data.buffer.asUint8List()))
      .catchError((Object error) {
        GeneralHelper.logFailure('Preview luma wipe mask $name failed', error);
        return null;
      });
}
