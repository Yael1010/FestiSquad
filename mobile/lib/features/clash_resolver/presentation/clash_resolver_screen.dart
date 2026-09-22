import 'package:flutter/material.dart';

class ClashResolverScreen extends StatefulWidget {
  const ClashResolverScreen({super.key});

  @override
  State<ClashResolverScreen> createState() => _ClashResolverScreenState();
}

class _ClashResolverScreenState extends State<ClashResolverScreen> {
  final Set<String> _genres = {'indie'};

  @override
  Widget build(BuildContext context) {
    final genres = ['rock', 'indie', 'edm', 'pop', 'regional'];
    return Scaffold(
      appBar: AppBar(title: const Text('Clash Resolver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fallback manual de géneros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final genre in genres)
                FilterChip(
                  label: Text(genre),
                  selected: _genres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      selected ? _genres.add(genre) : _genres.remove(genre);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Resolver empalme'),
          ),
        ],
      ),
    );
  }
}
