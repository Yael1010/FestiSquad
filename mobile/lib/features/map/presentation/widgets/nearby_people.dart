import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/map_providers.dart';

class NearbyPeople extends ConsumerWidget {
  const NearbyPeople({super.key, required this.totemId});

  final String totemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(nearbyPeopleProvider(totemId));

    return people.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Cargando personas cercanas',
          ),
        ),
      ),
      error: (error, stackTrace) => Column(
        children: [
          const Text('No pudimos cargar las personas cercanas.'),
          TextButton(
            onPressed: () => ref.invalidate(nearbyPeopleProvider(totemId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personas cerca del totem (${items.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No hay personas cercanas para mostrar.'),
          for (final person in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.person_outline),
              ),
              title: Text(person.name),
              subtitle: Text('A ${person.distanceMeters} m del totem'),
            ),
        ],
      ),
    );
  }
}
