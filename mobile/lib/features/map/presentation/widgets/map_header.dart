import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/map_providers.dart';
import '../../domain/map_models.dart';

class MapHeader extends ConsumerWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider).when(
          data: (value) => value,
          loading: () => NetworkStatus.checking,
          error: (error, stackTrace) => NetworkStatus.unknown,
        );

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('FestiSquad', style: Theme.of(context).textTheme.titleMedium),
            NetworkIndicator(status: status),
          ],
        ),
      ),
    );
  }
}

class NetworkIndicator extends StatelessWidget {
  const NetworkIndicator({super.key, required this.status});

  final NetworkStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      NetworkStatus.online => ('En linea', Icons.wifi),
      NetworkStatus.offline => ('Sin conexion', Icons.wifi_off),
      NetworkStatus.checking => ('Comprobando', Icons.sync),
      NetworkStatus.unknown => ('Red sin verificar', Icons.help_outline),
    };

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
