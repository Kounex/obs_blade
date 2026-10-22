import 'package:flutter/widgets.dart';

/// FOSS build (copied over `lib/purchase_base.dart` by
/// `tool/foss/prepare.sh`): no store SDK, so nothing listens for
/// purchases. Same names as the store version so the shared code
/// (`main.dart`, `ProStore`) compiles unchanged.
void showProRestoredDialog() {}

class PurchaseBase extends StatelessWidget {
  static bool restoreTriggeredExplicitly = false;

  final Widget child;

  const PurchaseBase({super.key, required this.child});

  @override
  Widget build(BuildContext context) => this.child;
}
