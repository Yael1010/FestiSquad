import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Squad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(title: 'Mapa resiliente', subtitle: 'Últimas ubicaciones y puntos de encuentro', route: '/map'),
          const SizedBox(height: 12),
          _ActionTile(title: 'Fondo común', subtitle: 'Gastos, saldos y deudas cruzadas', route: '/finances'),
          const SizedBox(height: 12),
          _ActionTile(title: 'Clash Resolver', subtitle: 'Decidan a qué escenario ir', route: '/clash'),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.subtitle, required this.route});

  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}

