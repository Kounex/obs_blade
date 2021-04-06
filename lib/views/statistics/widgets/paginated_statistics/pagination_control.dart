import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PaginationControl extends StatelessWidget {
  final int? currentPage;
  final int? amountPages;

  final void Function()? onBackMax;
  final void Function()? onBack;
  final void Function()? onForward;
  final void Function()? onForwardMax;

  PaginationControl({
    this.currentPage,
    this.amountPages,
    this.onBackMax,
    this.onBack,
    this.onForward,
    this.onForwardMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.chevron_left_2),
            onPressed: this.onBackMax,
          ),
          IconButton(
            icon: Icon(CupertinoIcons.chevron_left),
            onPressed: this.onBack,
          ),
          SizedBox(width: 14.0),
          Text(
            '${this.currentPage} / ${this.amountPages}',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          SizedBox(width: 14.0),
          IconButton(
            icon: Icon(CupertinoIcons.chevron_right),
            onPressed: this.onForward,
          ),
          IconButton(
            icon: Icon(CupertinoIcons.chevron_right_2),
            onPressed: this.onForwardMax,
          ),
        ],
      ),
    );
  }
}
