import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../../../utils/preview_transition/preview_transition_spec.dart';
import '../../../../../utils/preview_transition/preview_transition_tracker.dart';
import 'preview_transition_painter.dart';

/// The scene preview frame - plays [transition] when a new one comes in.
///
/// The live frame ([bytes]) always stays underneath; while a transition
/// runs, an overlay shows the old frame first (until both frames are
/// decoded) and then [PreviewTransitionPainter] with the old frame frozen
/// and the new scene's frames live. When it ends the overlay goes and the
/// live frame is already there - no flash in between.
class ScenePreviewImage extends StatefulWidget {
  final Uint8List bytes;

  /// The latest transition the store started (a new instance per
  /// transition) - null for previews without transitions (other canvases)
  final StartPreviewTransition? transition;

  const ScenePreviewImage({super.key, required this.bytes, this.transition});

  @override
  State<ScenePreviewImage> createState() => _ScenePreviewImageState();
}

class _ScenePreviewImageState extends State<ScenePreviewImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);

  /// Transition being played (null: just the live frame)
  StartPreviewTransition? _active;

  /// Id of the last transition seen - one that was already there when this
  /// widget mounted (fullscreen opened, tab switched) must not replay
  int? _seenId;

  _DecodedFrame? _from;
  _DecodedFrame? _to;
  ui.FragmentProgram? _lumaProgram;
  ui.Image? _lumaMask;

  @override
  void initState() {
    super.initState();
    _seenId = widget.transition?.id;
  }

  @override
  void didUpdateWidget(covariant ScenePreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final StartPreviewTransition? transition = widget.transition;
    if (transition == null) {
      if (_active != null) _stop();
    } else if (transition.id != _seenId) {
      _seenId = transition.id;
      _start(transition);
    } else if (_active != null &&
        _controller.isAnimating &&
        !identical(widget.bytes, oldWidget.bytes)) {
      /// The new scene keeps moving under the transition
      _decode(widget.bytes, _active!).then((frame) {
        if (frame == null || _active == null) return frame?.dispose();
        setState(() {
          _to?.dispose();
          _to = frame;
        });
      });
    }
  }

  Future<void> _start(StartPreviewTransition transition) async {
    _stop(rebuild: false);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() {});
      return;
    }
    setState(() => _active = transition);

    final PreviewTransitionSpec spec = transition.spec;
    final bool luma = spec.kind == PreviewTransitionKind.lumaWipe;
    final results = await Future.wait<Object?>([
      _decode(transition.fromBytes, transition),
      _decode(transition.toBytes, transition),
      if (luma) LumaWipeResources.program(),
      if (luma) LumaWipeResources.mask(spec.lumaImage),
    ]);
    final _DecodedFrame? from = results[0] as _DecodedFrame?;
    final _DecodedFrame? to = results[1] as _DecodedFrame?;

    if (!mounted || _active != transition || from == null || to == null) {
      from?.dispose();
      to?.dispose();
      if (mounted && _active == transition) _stop();
      return;
    }

    setState(() {
      _from = from;
      _to = to;
      _lumaProgram = luma ? results[2] as ui.FragmentProgram? : null;
      _lumaMask = luma ? results[3] as ui.Image? : null;
    });
    _controller
      ..duration = spec.duration
      ..forward(from: 0.0);
  }

  /// Decodes through the image cache (the live [Image.memory] shares it, so
  /// a frame is decoded once). Null when it fails or [transition] is over
  Future<_DecodedFrame?> _decode(
    Uint8List bytes,
    StartPreviewTransition transition,
  ) {
    final Completer<_DecodedFrame?> completer = Completer();
    final ImageStream stream = MemoryImage(
      bytes,
    ).resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(_DecodedFrame(info));
      },
      onError: (_, _) {
        stream.removeListener(listener);
        completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) _stop();
  }

  void _stop({bool rebuild = true}) {
    _controller.stop();
    _from?.dispose();
    _to?.dispose();
    _from = null;
    _to = null;
    _lumaProgram = null;
    _lumaMask = null;
    if (rebuild) {
      setState(() => _active = null);
    } else {
      _active = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _from?.dispose();
    _to?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StartPreviewTransition? active = _active;
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.memory(widget.bytes, fit: BoxFit.contain, gaplessPlayback: true),
        if (active != null)
          Positioned.fill(
            child: _from != null && _to != null
                ? CustomPaint(
                    painter: PreviewTransitionPainter(
                      from: _from!.image,
                      to: _to!.image,
                      spec: active.spec,
                      progress: _controller,
                      lumaProgram: _lumaProgram,
                      lumaMask: _lumaMask,
                    ),
                  )
                /// Until both frames are decoded the old scene stays
                : Image.memory(
                    active.fromBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          ),
      ],
    );
  }
}

/// A decoded frame - holds its own handle so the cache can't dispose it
/// while the painter uses it
class _DecodedFrame {
  _DecodedFrame(ImageInfo info) : _info = info;

  final ImageInfo _info;

  ui.Image get image => _info.image;

  void dispose() => _info.dispose();
}
