import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/map_providers.dart';

class DemoMapCanvas extends ConsumerWidget {
  const DemoMapCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totems = ref.watch(totemsProvider);
    final selectedId = ref.watch(selectedTotemIdProvider);

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48),
              const SizedBox(height: 8),
              const Text('Mapa de demostracion'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final totem in totems)
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                      ),
                      label: Text(totem.name),
                      selected: selectedId == totem.id,
                      onSelected: (_) => ref
                          .read(selectedTotemIdProvider.notifier)
                          .select(totem.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
