import 'package:flutter/material.dart';

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fondo común')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Tickets compartidos'),
            subtitle: Text('Los importes se modelan en centavos para evitar errores de redondeo.'),
          ),
          ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Deudas cruzadas'),
            subtitle: Text('El backend calcula transferencias mínimas entre integrantes.'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
