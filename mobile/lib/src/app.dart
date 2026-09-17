import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/clash_resolver/presentation/clash_resolver_screen.dart';
import '../features/finances/presentation/finances_screen.dart';
import '../features/map/presentation/festival_map_screen.dart';
import '../features/squads/presentation/dashboard_screen.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/map', builder: (context, state) => const FestivalMapScreen()),
    GoRoute(path: '/finances', builder: (context, state) => const FinancesScreen()),
    GoRoute(path: '/clash', builder: (context, state) => const ClashResolverScreen()),
  ],
);

class FestiSquadApp extends StatelessWidget {
  const FestiSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FestiSquad',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

