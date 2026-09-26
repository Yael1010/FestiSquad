import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/app.dart';

void bootstrapFestiSquad() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (_) => const AppFailureView();

  runZonedGuarded(
    () => runApp(const ProviderScope(child: FestiSquadApp())),
    (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'),
  );
}

class AppFailureView extends StatelessWidget {
  const AppFailureView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFF050A13),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No fue posible mostrar esta pantalla. Reinicia la vista para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
