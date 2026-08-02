import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../../../../utils/styling_helper.dart';

class PaginationControl extends StatelessWidget {
  final int? currentPage;
  final int? amountPages;

  final void Function()? onBackMax;
  final void Function()? onBack;
  final void Function()? onForward;
  final void Function()? onForwardMax;

  const PaginationControl({
    super.key,
    this.currentPage,
    this.amountPages,
    this.onBackMax,
    this.onBack,
    this.onForward,
    this.onForwardMax,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            icon: CupertinoIcons.chevron_left_2,
            onTap: this.onBackMax,
          ),
          _PaginationButton(
            icon: CupertinoIcons.chevron_left,
            onTap: this.onBack,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor, 10),
              borderRadius: AppRadius.pill,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.exit,
              child: Text(
                '${this.currentPage} / ${this.amountPages}',
                key: ValueKey('${this.currentPage}/${this.amountPages}'),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _PaginationButton(
            icon: CupertinoIcons.chevron_right,
            onTap: this.onForward,
          ),
          _PaginationButton(
            icon: CupertinoIcons.chevron_right_2,
            onTap: this.onForwardMax,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final void Function()? onTap;

  const _PaginationButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = this.onTap != null;

    return Pressable(
      onTap: this.onTap,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: enabled
              ? StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor, 10)
              : Colors.transparent,
          borderRadius: AppRadius.pill,
        ),
        child: Icon(
          this.icon,
          size: 20.0,
          color: IconTheme.of(context).color?.withValues(
                alpha: enabled ? 1.0 : 0.3,
              ),
        ),
      ),
    );
  }
}
