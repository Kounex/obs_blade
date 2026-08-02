import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../types/extensions/color.dart';
import '../../../../../types/extensions/string.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/validation_helper.dart';
import 'color_bubble.dart';
import 'color_slider.dart';

enum PickerType {
  RGB,
  HSL,
}

extension PickerTypeFunctions on PickerType {
  String get name => {
        PickerType.RGB: 'RGB',
        PickerType.HSL: 'HSL',
      }[this]!;
}

class ColorPicker extends StatefulWidget {
  final String title;
  final String description;
  final String? color;
  final bool editableColorValues;
  final bool useAlpha;
  final void Function(String)? onSave;

  const ColorPicker({
    super.key,
    required this.title,
    required this.description,
    this.color,
    this.editableColorValues = false,
    this.useAlpha = false,
    this.onSave,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  PickerType _pickerType = PickerType.RGB;

  late CustomValidationTextEditingController _hexController;
  late String _latestValidHexValue;
  final FocusNode _hexFocusNode = FocusNode();

  final CustomValidationTextEditingController _rController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.R));

  final CustomValidationTextEditingController _gController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.G));

  final CustomValidationTextEditingController _bController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.B));

  final CustomValidationTextEditingController _hController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.H));

  final CustomValidationTextEditingController _sController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.S));

  final CustomValidationTextEditingController _lController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.L));

  final CustomValidationTextEditingController _aController =
      CustomValidationTextEditingController(
          check: (value) =>
              ValidationHelper.colorTypeValidator(value, ColorType.A));

  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    _hexController = CustomValidationTextEditingController(
      text: this.widget.color ?? '000000',
      check: (value) => ValidationHelper.colorHexValidator(value,
          useAlpha: this.widget.useAlpha),
    );
    _latestValidHexValue = _hexController.text;

    _setHSLColor();

    _hexFocusNode.addListener(() {
      if (_hexFocusNode.hasFocus) {
        _hexController.selection = TextSelection(
            baseOffset: 0, extentOffset: _hexController.text.length);
      }
    });
    super.initState();
  }

  void _setHSLColor() {
    HSLColor hslColor =
        HSLColor.fromColor(Color(int.parse(_latestValidHexValue, radix: 16)));

    _hue = hslColor.hue;
    _saturation = (hslColor.saturation * 100).roundToDouble();
    _lightness = (hslColor.lightness * 100).roundToDouble();
  }

  double _getColorSliderValue(ColorType type) {
    if (_pickerType == PickerType.RGB) {
      int offset = type == ColorType.A
          ? 0
          : (this.widget.useAlpha ? 0 : -2) + type.hexOffset;
      return int.parse(_latestValidHexValue.substring(offset, offset + 2),
              radix: 16)
          .toDouble();
    }
    HSLColor color =
        HSLColor.fromColor(Color(int.parse(_latestValidHexValue, radix: 16)));
    switch (type) {
      case ColorType.H:
        return _hue;
      case ColorType.S:
        return _saturation;
      case ColorType.L:
        return _lightness;
      case ColorType.A:
        return color.alpha;
      default:
        return 0;
    }
  }

  void _onColorSlideChange(String value, ColorType type) {
    _hexController.text = _latestValidHexValue;
    if (_pickerType == PickerType.RGB) {
      int offset = type == ColorType.A
          ? 0
          : (this.widget.useAlpha ? 0 : -2) + type.hexOffset;
      String hex = int.parse(value).toRadixString(16);
      _hexController.text = _hexController.text
          .replaceRange(offset, offset + 2, hex.padLeft(2, '0'));
    } else {
      HSLColor color =
          HSLColor.fromAHSL(1.0, _hue, _saturation / 100, _lightness / 100);
      switch (type) {
        case ColorType.H:
          _hue = double.parse(value);
          color = color.withHue(_hue);
          break;
        case ColorType.S:
          _saturation = double.parse(value);
          color = color.withSaturation(_saturation / 100);
          break;
        case ColorType.L:
          _lightness = double.parse(value);
          color = color.withLightness(_lightness / 100);
          break;
        case ColorType.A:
          color = color.withAlpha(double.parse(value));
          break;
        default:
      }
      Color rgbColor = color.toColor();
      String alphaHex = rgbColor.alpha.toRadixString(16).padLeft(2, '0');
      String redHex = rgbColor.red.toRadixString(16).padLeft(2, '0');
      String greenHex = rgbColor.green.toRadixString(16).padLeft(2, '0');
      String blueHex = rgbColor.blue.toRadixString(16).padLeft(2, '0');
      _hexController.text =
          (this.widget.useAlpha ? alphaHex : '') + redHex + greenHex + blueHex;
    }
    _latestValidHexValue = _hexController.text;
    setState(() {});
  }

  /// Quick swatches are derived from the currently active app theme so the
  /// user can pick "what they already see" - tapping one goes through the
  /// exact same code path as typing a valid hex value (alpha channel is
  /// preserved when [ColorPicker.useAlpha] is on), the `onSave` hex-string
  /// contract is untouched.
  void _applySwatch(Color color) {
    String hex = color.toHex();
    if (this.widget.useAlpha) {
      hex = _latestValidHexValue.substring(0, 2) + hex;
    }
    _hexController.text = hex;
    _latestValidHexValue = hex;
    _setHSLColor();
    setState(() {});
  }

  List<Color> _themeSwatches(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return [
      theme.cardColor,
      theme.scaffoldBackgroundColor,
      theme.appBarTheme.backgroundColor ?? theme.cardColor,
      theme.colorScheme.secondary,
      theme.buttonTheme.colorScheme!.secondary,
      theme.dividerColor,
      Colors.black,
      Colors.white,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ThemedCupertinoButton(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  text: 'Reset',
                  isDestructive: true,
                  onPressed: () => ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: 'Reset Color',
                      body:
                          'Are you sure you want to reset this color? It will be set to it\'s initial value!',
                      isYesDestructive: true,
                      onOk: (_) => Navigator.of(context).pop(true),
                    ),
                  ),
                ),
              ),
            ),
            ThemedCupertinoButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ThemedCupertinoButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              text: 'Save',
              onPressed: () {
                if (_hexController.isValid &&
                    (this.widget.editableColorValues
                        ? (_pickerType == PickerType.RGB
                                ? (_rController.isValid &&
                                    _gController.isValid &&
                                    _bController.isValid)
                                : (_hController.isValid &&
                                    _sController.isValid &&
                                    _lController.isValid)) &&
                            (this.widget.useAlpha ? _aController.isValid : true)
                        : true)) {
                  this.widget.onSave?.call(_hexController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        const BaseDivider(),
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.md, left: AppSpacing.md, bottom: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  this.widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md),
          child: Text(
            this.widget.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const BaseDivider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: CupertinoSlidingSegmentedControl<PickerType>(
                      groupValue: _pickerType,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs, horizontal: 2.0),
                      children: {
                        PickerType.RGB: SizedBox(
                          width: 96.0,
                          child: Text(
                            PickerType.RGB.name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        PickerType.HSL: SizedBox(
                          width: 96.0,
                          child: Text(
                            PickerType.HSL.name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      },
                      onValueChanged: (pickerType) {
                        _setHSLColor();
                        setState(() => _pickerType = pickerType!);
                      },
                    ),
                  ),
                ),
                const BaseDivider(),
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      right: AppSpacing.md),
                  child: Text(
                    'FROM CURRENT THEME',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final Color swatch in _themeSwatches(context))
                        Pressable(
                          onTap: () => _applySwatch(swatch),
                          child: ColorBubble(
                            color: swatch,
                            size: 32.0,
                          ),
                        ),
                    ],
                  ),
                ),
                const BaseDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.xl),
                            child: Text(
                              'Hex:',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          SizedBox(
                            width: 150.0,
                            height: 82.0,
                            child: StatefulBuilder(
                              builder: (context, setInnerState) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppSpacing.xl),
                                  child: TextFormField(
                                    controller: _hexController,
                                    focusNode: _hexFocusNode,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: Theme.of(context)
                                          .scaffoldBackgroundColor
                                          .withValues(alpha: 0.5),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                        borderSide: BorderSide.none,
                                      ),
                                      counterText: '',
                                      suffixText:
                                          '${_hexController.text.length} / ${this.widget.useAlpha ? 8 : 6}',
                                      suffixStyle: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    validator: (color) =>
                                        ValidationHelper.colorHexValidator(
                                            color),
                                    autovalidateMode: AutovalidateMode.always,
                                    autocorrect: false,
                                    maxLength: this.widget.useAlpha ? 8 : 6,
                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,
                                    // inputFormatters: [
                                    //   FilteringTextInputFormatter.allow(
                                    //     r'^[a-fA-F0-9]+$',
                                    //     replacementString: _color.text,
                                    //   )
                                    // ],
                                    onChanged: (value) {
                                      if (ValidationHelper.colorHexValidator(
                                              _hexController.text) ==
                                          null) {
                                        _latestValidHexValue = value;
                                        _setHSLColor();
                                        setState(() {});
                                      }
                                      setInnerState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.md),
                        child: ColorBubble(
                          color: _latestValidHexValue.hexToColor(),
                          size: 48.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const BaseDivider(),
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      left: AppSpacing.xl,
                      right: AppSpacing.lg),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.standard,
                    switchOutCurve: AppMotion.exit,
                    child: KeyedSubtree(
                      key: ValueKey(_pickerType),
                      child: Column(
                        children: [
                          if (_pickerType == PickerType.RGB) ...[
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _rController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.R,
                              value: _getColorSliderValue(ColorType.R),
                              activeColor: CupertinoColors.destructiveRed,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.R,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _gController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.G,
                              value: _getColorSliderValue(ColorType.G),
                              activeColor: Colors.green,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.G,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _bController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.B,
                              value: _getColorSliderValue(ColorType.B),
                              activeColor: Colors.blue,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.B,
                              ),
                            ),
                          ],
                          if (_pickerType == PickerType.HSL) ...[
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _hController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.H,
                              value: _getColorSliderValue(ColorType.H),
                              saturation: _saturation,
                              lightness: _lightness,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.H,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _sController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.S,
                              value: _getColorSliderValue(ColorType.S),
                              hue: _hue,
                              lightness: _lightness,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.S,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ColorSlider(
                              controller: this.widget.editableColorValues
                                  ? _lController
                                  : null,
                              pickerType: _pickerType,
                              colorType: ColorType.L,
                              value: _getColorSliderValue(ColorType.L),
                              hue: _hue,
                              saturation: _saturation,
                              onChanged: (colorVal) => _onColorSlideChange(
                                colorVal,
                                ColorType.L,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (this.widget.useAlpha)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.xl, right: AppSpacing.lg),
                    child: ColorSlider(
                      controller: this.widget.editableColorValues
                          ? _aController
                          : null,
                      pickerType: _pickerType,
                      colorType: ColorType.A,
                      value: _getColorSliderValue(ColorType.A),
                      activeColor: Colors.white,
                      onChanged: (colorVal) =>
                          _onColorSlideChange(colorVal, ColorType.A),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
