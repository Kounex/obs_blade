import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/views/dashboard.dart';

class ScreenshotPreview extends StatefulWidget {
  final Uint8List screenshot;
  final String screenshotPath;

  const ScreenshotPreview({
    super.key,
    required this.screenshot,
    required this.screenshotPath,
  });

  @override
  State<ScreenshotPreview> createState() => _ScreenshotPreviewState();
}

class _ScreenshotPreviewState extends State<ScreenshotPreview> {
  @override
  void initState() {
    super.initState();

    /// Once this preview has been triggered and opened, we will immediately
    /// set the screenshot source value to null to avoid failing to do so
    /// on other triggers like closing this preview etc. Sicne we get the
    /// screenshot as a parameter, we have it in memory nontheless so no
    /// problem to do it here immediately
    GetIt.instance<DashboardStore>().manualScreenshotImageBytes = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + 24,
          left: 0,
          right: 0,
          child: Text(
            'Screenshot',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Positioned(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          left: 24.0,
          right: 24.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BaseDivider(),
              const SizedBox(height: 12.0),
              const Text(
                  'Screenshot has been saved on your device running OBS.'),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  const SizedBox(
                    width: 52.0,
                    child: Text(
                      'Path:',
                    ),
                  ),
                  Text(
                    GetIt.instance<DashboardStore>().recordDirectory!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 52.0,
                    child: Text('Name:'),
                  ),
                  Text(
                    this.widget.screenshotPath.split('/').removeLast(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InteractiveViewer(
          // clipBehavior: Clip.none,
          // boundaryMargin: const EdgeInsets.all(double.infinity),

          child: Image.memory(
            this.widget.screenshot,
            // fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
