import 'dart:typed_data';

import 'preview_transition_spec.dart';

/// What the scene preview should do with a frame
sealed class PreviewFrameOutcome {
  const PreviewFrameOutcome();
}

/// Show the frame as is (same scene, or a scene change without a transition)
class ShowPreviewFrame extends PreviewFrameOutcome {
  final Uint8List bytes;
  const ShowPreviewFrame(this.bytes);
}

/// Keep showing the last frame - a transition to this frame's scene is
/// starting but not resolved yet. The tracker keeps the frame
class HoldPreviewFrame extends PreviewFrameOutcome {
  const HoldPreviewFrame();
}

/// Play [spec] from [fromBytes] (the last frame of the old scene) to
/// [toBytes]; later frames of the new scene arrive as [ShowPreviewFrame]
class StartPreviewTransition extends PreviewFrameOutcome {
  final int id;
  final Uint8List fromBytes;
  final Uint8List toBytes;
  final PreviewTransitionSpec spec;

  const StartPreviewTransition({
    required this.id,
    required this.fromBytes,
    required this.toBytes,
    required this.spec,
  });
}

class _TransitionContext {
  _TransitionContext({required this.createdAt, this.target, this.name});

  final DateTime createdAt;

  /// Scene the transition goes to - known right away for an app switch,
  /// from `GetCurrentProgramScene` for one started elsewhere
  String? target;

  /// Transition really running (`SceneTransitionStarted`)
  String? name;
  DateTime? startedAt;

  PreviewTransitionSpec? spec;

  bool get resolved => target != null && name != null && spec != null;
}

/// Decides per scene preview frame whether to show it, hold it or play a
/// transition into it. Pure and synchronous - the store feeds it OBS events,
/// reads and frames, the clock is passed in.
///
/// Frames are tagged with the scene they show. A frame of another scene than
/// the last shown one is a scene change: it animates when a transition
/// context names that scene (app switch / `SceneTransitionStarted`) and cuts
/// otherwise (first frame, reconnect, collection switch, studio preview).
class PreviewTransitionTracker {
  PreviewTransitionTracker({
    this.contextTtl = const Duration(seconds: 3),
    this.holdLimit = const Duration(milliseconds: 400),
    this.maxFromFrameAge = const Duration(seconds: 3),
  });

  /// A context nobody completed (switch failed, preview not running) expires
  final Duration contextTtl;

  /// Longest a frame of the new scene waits for its transition to resolve
  final Duration holdLimit;

  /// An older last frame is no base for an animation (preview was paused)
  final Duration maxFromFrameAge;

  String? _shownScene;
  Uint8List? _shownBytes;
  DateTime? _shownAt;

  _TransitionContext? _context;

  String? _heldScene;
  Uint8List? _heldBytes;
  DateTime? _heldSince;

  int _nextId = 0;

  /// Start time of the latest `SceneTransitionStarted` per transition name -
  /// paired with `SceneTransitionVideoEnded` to learn real durations
  final Map<String, DateTime> _startedAt = {};
  final Map<String, Duration> _measured = {};

  /// Scene of the last shown frame
  String? get shownScene => _shownScene;

  /// Whether a frame waits for its transition
  bool get isHolding => _heldBytes != null;

  /// When the held frame has to go out at the latest
  DateTime? get holdDeadline => _heldSince?.add(holdLimit);

  /// The scene a pending transition goes to, if known
  String? pendingTarget(DateTime now) => _liveContext(now)?.target;

  /// Last measured Started → VideoEnded time of a transition
  Duration? measuredDuration(String name) => _measured[name];

  /// The app switches the program scene to [target] (scene tile, studio
  /// transition button). OBS confirms with `SceneTransitionStarted`
  void appSwitchRequested(String target, DateTime now) {
    _context = _TransitionContext(createdAt: now, target: target);
  }

  /// `SceneTransitionStarted` for transition [name]
  void transitionStarted(String name, DateTime now) {
    _startedAt[name] = now;
    final _TransitionContext? context = _liveContext(now);
    if (context != null && context.name == null) {
      context
        ..name = name
        ..startedAt = now;
    } else {
      _context = _TransitionContext(createdAt: now, name: name)
        ..startedAt = now;
    }
  }

  /// The scene a started transition goes to (`GetCurrentProgramScene` read
  /// at the start). Returns what to do with a held frame that was waiting
  /// for it
  PreviewFrameOutcome? targetResolved(String target, DateTime now) {
    final _TransitionContext? context = _liveContext(now);
    if (context == null) return null;
    context.target = target;
    return _releaseIfReady(now);
  }

  /// The resolved look of the pending transition [name] into [target]
  /// (null: the look doesn't depend on the target, e.g. a cut). A look
  /// resolved for another target (the switch went elsewhere meanwhile -
  /// overrides differ per scene) is ignored. Returns what to do with a held
  /// frame that was waiting for it
  PreviewFrameOutcome? specResolved(
    String name,
    String? target,
    PreviewTransitionSpec spec,
    DateTime now,
  ) {
    final _TransitionContext? context = _liveContext(now);
    if (context == null || context.name != name) return null;
    if (target != null && context.target != target) return null;
    context.spec = spec;
    return _releaseIfReady(now);
  }

  /// `SceneTransitionVideoEnded` - the transition's visible part is over
  void videoEnded(String name, DateTime now) {
    final DateTime? started = _startedAt.remove(name);
    if (started != null) _measured[name] = now.difference(started);
  }

  /// A preview frame of [scene] arrived
  PreviewFrameOutcome frameArrived(
    String scene,
    Uint8List bytes,
    DateTime now, {
    bool animate = true,
  }) {
    final _TransitionContext? context = _liveContext(now);

    if (_heldBytes != null) {
      if (scene == _heldScene) {
        _heldBytes = bytes;
        return _releaseIfReady(now) ??
            _releaseIfExpired(now) ??
            const HoldPreviewFrame();
      }

      /// Back to the old scene (or yet another one) - drop the held frame
      _clearHeld();
    }

    if (_shownScene == null || scene == _shownScene || !animate) {
      return _show(scene, bytes, now);
    }

    final bool fromUsable =
        _shownBytes != null &&
        _shownAt != null &&
        now.difference(_shownAt!) <= maxFromFrameAge;
    if (context == null ||
        !fromUsable ||
        (context.target != null && context.target != scene)) {
      return _show(scene, bytes, now);
    }

    _heldScene = scene;
    _heldBytes = bytes;
    _heldSince = now;
    return _releaseIfReady(now) ?? const HoldPreviewFrame();
  }

  /// Called at [holdDeadline]: a still unresolved held frame goes out
  /// (as a transition when it got resolved meanwhile, as a cut otherwise)
  PreviewFrameOutcome? holdExpired(DateTime now) =>
      _releaseIfReady(now) ?? _releaseIfExpired(now);

  /// Forget the measured durations - another scene collection (or OBS)
  /// can have same-named transitions that run differently
  void clearMeasurements() {
    _startedAt.clear();
    _measured.clear();
  }

  /// Forget everything about the shown frame and pending transitions -
  /// reconnect, scene collection switch, preview restarted
  void reset() {
    _shownScene = null;
    _shownBytes = null;
    _shownAt = null;
    _context = null;
    _clearHeld();
  }

  _TransitionContext? _liveContext(DateTime now) {
    final _TransitionContext? context = _context;
    if (context == null) return null;
    if (now.difference(context.createdAt) > contextTtl) {
      _context = null;
      return null;
    }
    return context;
  }

  /// The held frame once its transition is resolved: a transition to play,
  /// or the frame itself when there is nothing to animate (cut, a stinger
  /// point already passed)
  PreviewFrameOutcome? _releaseIfReady(DateTime now) {
    final _TransitionContext? context = _liveContext(now);
    final Uint8List? held = _heldBytes;
    if (context == null || held == null || !context.resolved) return null;
    if (context.target != _heldScene) return null;

    PreviewTransitionSpec spec = context.spec!;
    if (spec.stingerPoint != null) {
      /// The stinger swaps at its point after the start - what's left of it
      final Duration elapsed = now.difference(context.startedAt ?? now);
      spec = spec.withDuration(spec.stingerPoint! - elapsed);
    }

    final Uint8List from = _shownBytes!;
    final String scene = _heldScene!;
    _context = null;
    _clearHeld();
    _shownScene = scene;
    _shownBytes = held;
    _shownAt = now;
    if (spec.isCut) return ShowPreviewFrame(held);
    return StartPreviewTransition(
      id: _nextId++,
      fromBytes: from,
      toBytes: held,
      spec: spec,
    );
  }

  PreviewFrameOutcome? _releaseIfExpired(DateTime now) {
    if (_heldBytes == null || _heldSince == null) return null;
    if (now.difference(_heldSince!) < holdLimit) return null;
    final String scene = _heldScene!;
    final Uint8List bytes = _heldBytes!;
    _context = null;
    _clearHeld();
    return _show(scene, bytes, now);
  }

  ShowPreviewFrame _show(String scene, Uint8List bytes, DateTime now) {
    _shownScene = scene;
    _shownBytes = bytes;
    _shownAt = now;
    return ShowPreviewFrame(bytes);
  }

  void _clearHeld() {
    _heldScene = null;
    _heldBytes = null;
    _heldSince = null;
  }
}
