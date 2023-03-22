import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PaginationControl extends StatelessWidget {
  final int? currentPage;
  final int? amountPages;

  final void Function()? onBackMax;
  final void Function()? onBack;
  final void Function()? onForward;
  final void Function()? onForwardMax;

  const PaginationControl({
    Key? key,
    this.currentPage,
    this.amountPages,
    this.onBackMax,
    this.onBack,
    this.onForward,
    this.onForwardMax,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_left_2),
            onPressed: this.onBackMax,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: this.onBack,
          ),
          const SizedBox(width: 14.0),
          Text(
            '${this.currentPage} / ${this.amountPages}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 14.0),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right),
            onPressed: this.onForward,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right_2),
            onPressed: this.onForwardMax,
          ),
        ],
      ),
    );
  }
}
