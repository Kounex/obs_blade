import 'dart:async';

import 'package:flutter/material.dart';

class BaseProgressIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;

  /// If we want to use the progress indicator to "count down", indicating
  /// we are waiting for something to complete for x amount of seconds
  final int? countdownInSeconds;
  final VoidCallback? onCountdownDone;

  /// Sets the value of the progress indicator [0 <= x <= 1.0]
  final double? value;

  /// The amount of time to pass before the progress indicator is in the new
  /// position representing the new value (initial value will be represented
  /// immediately)
  final Duration valueUpdateDuration;

  /// Amount of update steps to do while working towards the new value (the
  /// higher the value, the "fluent" the progression looks like). Base value of
  /// 100 is already very smooth, don't recommend to increase this.
  final double valueUpdateSteps;

  final String? text;

  BaseProgressIndicator({
    Key? key,
    this.text,
    this.countdownInSeconds,
    this.onCountdownDone,
    this.value,
    this.valueUpdateSteps = 100,
    this.valueUpdateDuration = const Duration(milliseconds: 1000),
    this.size = 32.0,
    this.strokeWidth = 2.0,
  })  : assert(text != null && text.isNotEmpty || text == null),
        assert(
          countdownInSeconds != null
              ? value == null
              : value != null
                  ? countdownInSeconds == null &&
                      valueUpdateSteps < valueUpdateDuration.inMilliseconds &&
                      valueUpdateDuration.inMilliseconds / valueUpdateSteps ==
                          (valueUpdateDuration.inMilliseconds ~/
                                  valueUpdateSteps)
                              .toDouble()
                  : true,
        ),
        super(key: key);

  @override
  State<BaseProgressIndicator> createState() => _BaseProgressIndicatorState();
}

class _BaseProgressIndicatorState extends State<BaseProgressIndicator> {
  double? _tempValue;

  @override
  void initState() {
    super.initState();

    if (this.widget.countdownInSeconds != null) {
      _tempValue ??= 1.0;
      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (_tempValue! <= 0) {
          timer.cancel();
          this.widget.onCountdownDone?.call();
        }
        setState(() {
          _tempValue = _tempValue! -
              (1.0 / ((this.widget.countdownInSeconds! * 1000) / 10));
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant BaseProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != null &&
        this.widget.value != null &&
        oldWidget.value != this.widget.value) {
      _tempValue ??= oldWidget.value;
      Timer.periodic(
          Duration(
            milliseconds: this.widget.valueUpdateDuration.inMilliseconds ~/
                this.widget.valueUpdateSteps,
          ), (timer) {
        setState(() {
          _tempValue = _tempValue! +
              (this.widget.value! - oldWidget.value!) /
                  this.widget.valueUpdateSteps;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: this.widget.size,
          width: this.widget.size,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
            strokeWidth: this.widget.strokeWidth,
            value: _tempValue ?? this.widget.value,
          ),
        ),
        if (this.widget.text != null)
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: Text(
              this.widget.text!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
          )
      ],
    );
  }
}
