import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../application/festival_catalog_controller.dart';
import '../domain/festival.dart';

class FestivalCatalogScreen extends ConsumerWidget {
  const FestivalCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(festivalCatalogControllerProvider);
    final admin = ref.watch(festivalAdminAccessProvider).valueOrNull == true;
    final data = state.valueOrNull;
    final festivals = data?.value ?? const <FestivalSummary>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Festivales'),
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Administrar festivales',
              onPressed: () => context.push('/festivals/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: 'Actualizar catálogo',
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(festivalCatalogControllerProvider.notifier)
                    .load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FestiBody(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(festivalCatalogControllerProvider.notifier)
              .load(forceRefresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Elige tu festival',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mapas, escenarios y logística de tu squad en un solo lugar.',
                style: TextStyle(color: FestiColors.muted),
              ),
              if (data?.fromCache == true) ...[
                const SizedBox(height: 12),
                const _OfflineNotice(),
              ],
              const SizedBox(height: 20),
              if (state.isLoading && festivals.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (state.hasError && festivals.isEmpty)
                _CatalogFailure(
                  message: state.error.toString(),
                  onRetry: () => ref
                      .read(festivalCatalogControllerProvider.notifier)
                      .load(forceRefresh: true),
                )
              else if (festivals.isEmpty)
                _EmptyCatalog(onDemo: () => context.push('/map'))
              else
                for (final festival in festivals) ...[
                  _FestivalCard(
                    festival: festival,
                    onTap: () => context.push(
                      '/map?festivalId=${Uri.encodeQueryComponent(festival.id)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.festival, required this.onTap});

  final FestivalSummary festival;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FestiCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            width: double.infinity,
            child: festival.imageUrl == null
                ? const _FestivalPlaceholder()
                : Image.network(
                    festival.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FestivalPlaceholder(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        festival.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: FestiColors.cyan),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${festival.venueName} · ${festival.city}',
                  style: const TextStyle(color: FestiColors.muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      _dateLabel(festival.startsAt, festival.endsAt),
                      icon: Icons.calendar_today_outlined,
                    ),
                    StatusPill(
                      '${festival.stageCount} escenarios',
                      icon: Icons.music_note_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime start, DateTime end) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    if (start.year == end.year && start.month == end.month) {
      return start.day == end.day
          ? '${start.day} ${months[start.month - 1]} ${start.year}'
          : '${start.day}-${end.day} ${months[start.month - 1]} ${start.year}';
    }
    return '${start.day} ${months[start.month - 1]} · '
        '${end.day} ${months[end.month - 1]}';
  }
}

class _FestivalPlaceholder extends StatelessWidget {
  const _FestivalPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF103047),
        child: CustomPaint(painter: _MapPatternPainter()),
      );
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = FestiColors.cyan.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .72)
      ..lineTo(size.width * .28, size.height * .22)
      ..lineTo(size.width * .54, size.height * .44)
      ..lineTo(size.width * .72, size.height * .16)
      ..lineTo(size.width * .93, size.height * .65)
      ..close();
    canvas.drawPath(path, line);
    canvas.drawCircle(
      Offset(size.width * .54, size.height * .44),
      8,
      Paint()..color = FestiColors.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: FestiColors.muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Catálogo guardado en este dispositivo.',
              style: TextStyle(color: FestiColors.muted),
            ),
          ),
        ],
      );
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.onDemo});

  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) => FestiCard(
        child: Column(
          children: [
            const Icon(Icons.map_outlined, size: 40, color: FestiColors.cyan),
            const SizedBox(height: 12),
            const Text('Aún no hay festivales publicados.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onDemo,
              child: const Text('Abrir plano de demostración'),
            ),
          ],
        ),
      );
}

class _CatalogFailure extends StatelessWidget {
  const _CatalogFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FestiCard(
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}
