import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_typography.dart';

/// Tweens between numeric string values whenever [value] changes (e.g. the
/// 1s stats cadence on the dashboard). Non-numeric values (units, "N/A",
/// locale strings) snap to the new value instead.
///
/// Cheap: a single [AnimationController], rebuilt only by its own ticks.
/// Resting text is the raw [value] string, so formatting is never altered.
class CountUpText extends StatefulWidget {
  final String value;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  final Duration duration;
  final Curve curve;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
    this.maxLines,
    this.duration = AppMotion.medium,
    this.curve = AppMotion.standard,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  /// Numeric tween endpoints - null while showing a non-numeric value
  double? _from;
  double? _to;

  /// Decimal places of the incoming value string (kept stable mid-tween)
  int _fractionDigits = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: this.widget.duration,
    );
    _curved = CurvedAnimation(parent: _controller, curve: this.widget.curve);
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == this.widget.value) return;

    final double? from = double.tryParse(oldWidget.value);
    final double? to = double.tryParse(this.widget.value);

    if (from != null && to != null) {
      _from = from;
      _to = to;
      _fractionDigits = _decimalsOf(this.widget.value);
      _controller.forward(from: 0.0);
    } else {
      /// Non-numeric input snaps
      _controller.stop();
      _controller.value = 1.0;
      _from = null;
      _to = null;
    }
  }

  int _decimalsOf(String value) {
    final int dot = value.indexOf('.');
    if (dot < 0) return 0;
    return value.length - dot - 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(fontFeatures: kTabularFigures);
    if (this.widget.style != null) {
      style = this.widget.style!.copyWith(
        fontFeatures: [
          ...?this.widget.style!.fontFeatures,
          ...kTabularFigures,
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        String text = this.widget.value;
        final double? from = _from;
        final double? to = _to;
        if (from != null && to != null && _controller.value < 1.0) {
          text = (from + (to - from) * _curved.value)
              .toStringAsFixed(_fractionDigits);
        }
        return Text(
          text,
          style: style,
          textAlign: this.widget.textAlign,
          maxLines: this.widget.maxLines,
        );
      },
    );
  }
}
