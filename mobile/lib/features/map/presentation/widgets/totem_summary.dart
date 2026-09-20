import 'package:flutter/material.dart';

import '../../domain/map_models.dart';

class TotemSummary extends StatelessWidget {
  const TotemSummary({
    super.key,
    required this.totem,
    required this.onClose,
  });

  final Totem totem;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.location_on),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totem.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text('A ${totem.distanceMeters} m de ti'),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar totem',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
