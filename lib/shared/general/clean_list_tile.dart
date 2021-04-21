import 'package:flutter/material.dart';

class CleanListTile extends StatelessWidget {
  final String title;
  final String description;

  final Widget? trailing;

  CleanListTile({
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.title,
                style:
                    Theme.of(context).textTheme.button!.copyWith(fontSize: 16),
              ),
              SizedBox(height: 4.0),
              Text(
                this.description,
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
        ),
        if (this.trailing != null) ...[
          SizedBox(width: 32.0),
          this.trailing!,
        ],
      ],
    );
  }
}
