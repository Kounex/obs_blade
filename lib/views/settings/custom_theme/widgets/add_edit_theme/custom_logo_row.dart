import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'theme_row.dart';

class CustomLogoRow extends StatelessWidget {
  final CustomTheme customTheme;

  final void Function(Uint8List imageBytes) onSelectLogo;
  final VoidCallback onReset;

  const CustomLogoRow({
    Key? key,
    required this.customTheme,
    required this.onSelectLogo,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemeRow(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Logo',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
            ),
            child: Container(
              alignment: Alignment.center,
              height: 128.0,
              width: 128.0,
              decoration: BoxDecoration(
                border: this.customTheme.customLogo == null
                    ? Border.all(
                        color: Theme.of(context).textTheme.caption!.color!,
                      )
                    : null,
                borderRadius: const BorderRadius.all(
                  Radius.circular(8.0),
                ),
              ),
              child: this.customTheme.customLogo != null
                  ? Image.memory(
                      base64Decode(this.customTheme.customLogo!),
                      key: Key(this.customTheme.customLogo!),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0.03,
                          child: Transform.translate(
                            offset: const Offset(0, -8),
                            child: Image.asset(
                              StylingHelper.brightnessAwareOBSLogo(context),
                              key: Key(
                                StylingHelper.brightnessAwareOBSLogo(context),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '- None -',
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                fontSize: 14.0,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      description:
          'You can select your own logo which will be shown inside the app bar in the home tab (instead of the OBS Blade one)',
      buttonText: 'Select',
      onButtonPressed: () {
        ImagePicker().pickImage(source: ImageSource.gallery).then(
              (image) => image?.readAsBytes().then(
                    (imageBytes) => this.onSelectLogo(imageBytes),
                  ),
            );
      },
      resetButtonText: 'Clear',
      onResetButtonPressed: () => ModalHandler.showBaseDialog(
        context: context,
        dialogWidget: ConfirmationDialog(
          title: 'Delete Logo',
          body:
              'Are you sure you want to remove your custom logo? You won\'t be able to get it back unless you select it again!',
          isYesDestructive: true,
          onOk: (_) => this.onReset(),
        ),
      ),
    );
  }
}
