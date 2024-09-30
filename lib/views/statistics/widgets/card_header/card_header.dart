import 'package:flutter/material.dart';

import 'header_decoration.dart';

class CardHeader extends StatelessWidget {
  final String title;
  final String description;

  final IconData? headerDecorationIcon;

  final List<Widget> additionalCardWidgets;

  const CardHeader({
    super.key,
    required this.title,
    this.description = '',
    this.headerDecorationIcon,
    this.additionalCardWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 14.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(
                      width: 108.0,
                      child: Divider(height: 8.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4.0,
                        bottom: 12.0,
                      ),
                      child: Text(
                        this.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HeaderDecoration(
              icon: this.headerDecorationIcon,
            ),
          ],
        ),
        ...this.additionalCardWidgets,
      ],
    );
  }
}
