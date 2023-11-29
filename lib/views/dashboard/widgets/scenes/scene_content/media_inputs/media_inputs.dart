import 'package:flutter/material.dart';

import '../../../../../../shared/general/nested_list_manager.dart';

class MediaInputs extends StatefulWidget {
  const MediaInputs({super.key});

  @override
  State<MediaInputs> createState() => _MediaInputsState();
}

class _MediaInputsState extends State<MediaInputs>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NestedScrollManager(
      parentScrollController:
          ModalRoute.of(context)!.settings.arguments as ScrollController,
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: ListView(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(0.0),
          children: const [],
        ),
      ),
    );
  }
}
