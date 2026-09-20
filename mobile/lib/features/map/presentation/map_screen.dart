import 'package:flutter/material.dart';

import 'widgets/map_canvas.dart';
import 'widgets/map_header.dart';
import 'widgets/totem_sheet.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.map = const DemoMapCanvas()});

  /// Allows a real map adapter to replace the demo canvas without changing
  /// the screen layout or its Riverpod state.
  final Widget map;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: map),
          const Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(bottom: false, child: MapHeader()),
          ),
          const SafeArea(child: TotemSheet()),
        ],
      ),
    );
  }
}
