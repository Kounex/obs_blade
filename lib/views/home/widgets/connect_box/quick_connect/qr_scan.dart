import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:obs_blade/shared/dialogs/info.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class QRScan extends StatefulWidget {
  const QRScan({super.key});

  @override
  State<QRScan> createState() => _QRScanState();
}

class _QRScanState extends State<QRScan> {
  final GlobalKey _key = GlobalKey();

  QRViewController? _controller;
  bool? _qrScanState;

  bool _scanLocked = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller!.pauseCamera();
    } else if (Platform.isIOS) {
      _controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TransculentCupertinoNavBarWrapper(
      leading: Transform.scale(
        scale: 0.8,
        child: const QuestionMarkTooltip(
            message:
                'You can find the QR code in:\n\nTools -> obs-websocket Settings -> Show Connect Info'),
      ),
      title: 'Quick Connect',
      actions: ThemedCupertinoButton(
        padding: const EdgeInsets.all(0),
        text: 'Close',
        onPressed: () => Navigator.of(context).pop(),
      ),
      customBody: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                BaseProgressIndicator(
                  text: 'Initialising camera...',
                ),
                QRView(
                  key: _key,
                  overlay: QrScannerOverlayShape(
                    borderRadius: 0,
                  ),
                  formatsAllowed: const [BarcodeFormat.qrcode],
                  onQRViewCreated: (controller) {
                    _controller = controller;
                    _controller!.scannedDataStream.listen(
                      (scanData) {
                        if (!_scanLocked && _qrScanState == null ||
                            !_qrScanState!) {
                          bool result = scanData.code!.contains('obsws://');
                          if (result != _qrScanState) {
                            setState(() {
                              if (scanData.code != null) {
                                _qrScanState = result;
                                if (_qrScanState!) {
                                  _scanLocked = true;
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    Navigator.of(context).pop(
                                      Connection(
                                        scanData.code!
                                            .split('//')[1]
                                            .split(':')[0],
                                        int.tryParse(scanData.code!
                                            .split(':')[2]
                                            .split('/')[0]),
                                        scanData.code!
                                            .split('//')[1]
                                            .split('/')[1],
                                      ),
                                    );
                                  });
                                } else {
                                  Future.delayed(
                                    const Duration(seconds: 3),
                                    () {
                                      if (_qrScanState != null &&
                                          !_qrScanState!) {
                                        setState(() => _qrScanState = null);
                                      }
                                    },
                                  );
                                }
                              } else {
                                _qrScanState = null;
                              }
                            });
                          }
                        }
                      },
                    );
                  },
                  onPermissionSet: (_, permission) {
                    if (!permission) {
                      ModalHandler.showBaseDialog(
                        context: context,
                        dialogWidget: InfoDialog(
                          body:
                              'OBS Blade has no permission to use your camera. This feature does not work without using the camera, since we will scan a QR code provided by the WebSocket plugin.\n\nIf you change your mind and want to use this feature, go to:\n\niOS Settings -> OBS Blade (scroll way down) -> Toggle camera on',
                          onPressed: (_) => Navigator.of(context).pop(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: _qrScanState == null
                  ? BaseProgressIndicator(
                      text: 'Waiting for QR code...',
                    )
                  : _qrScanState!
                      ? const BaseResult(
                          icon: BaseResultIcon.Positive,
                          iconColor: CupertinoColors.activeGreen,
                          text: 'Quick connect QR code found!',
                        )
                      : const BaseResult(
                          icon: BaseResultIcon.Negative,
                          iconColor: CupertinoColors.destructiveRed,
                          text: 'Wrong QR code!',
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
