import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Dashboard'),
          )
        ],
      ),
    );
  }
}
