import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FestiSquad', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('Coordina tu squad aun cuando la red falle.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              TextField(
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

