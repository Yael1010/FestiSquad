import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/presentation/phone_preview.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/clash_resolver/presentation/clash_resolver_screen.dart';
import '../features/finances/presentation/finances_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/squads/presentation/dashboard_screen.dart';
import '../features/squads/presentation/join_squad_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final hasSession = auth.valueOrNull != null;
      if (hasSession && state.matchedLocation == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(
          path: '/join', builder: (context, state) => const JoinSquadScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
          path: '/finances',
          builder: (context, state) => const FinancesScreen()),
      GoRoute(
          path: '/clash',
          builder: (context, state) => const ClashResolverScreen()),
    ],
  );
});

class FestiSquadApp extends ConsumerWidget {
  const FestiSquadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FestiSquad',
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => PhonePreview(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
