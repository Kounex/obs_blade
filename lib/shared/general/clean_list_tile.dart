import 'package:flutter/material.dart';

class CleanListTile extends StatelessWidget {
  final String title;
  final String description;

  final Widget? trailing;

  const CleanListTile({
    Key? key,
    required this.title,
    required this.description,
    this.trailing,
  }) : super(key: key);

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
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4.0),
              Text(
                this.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (this.trailing != null) ...[
          const SizedBox(width: 32.0),
          this.trailing!,
        ],
      ],
    );
  }
}
