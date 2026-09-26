import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../../squads/application/squad_controller.dart';
import '../application/clash_controller.dart';
import '../domain/clash_models.dart';

class ClashResolverScreen extends ConsumerStatefulWidget {
  const ClashResolverScreen({super.key});

  @override
  ConsumerState<ClashResolverScreen> createState() =>
      _ClashResolverScreenState();
}

class _ClashResolverScreenState extends ConsumerState<ClashResolverScreen> {
  static const _availableGenres = [
    'rock',
    'indie',
    'pop',
    'electrónica',
    'hip hop',
    'regional mexicano',
    'reggaetón',
    'alternativo',
  ];

  final _selectedGenres = <String>{};
  final _artistsController = TextEditingController();
  String? _squadId;
  int _selectedConflict = 0;
  bool _preferencesHydrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _artistsController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    var squad = ref.read(squadControllerProvider).valueOrNull;
    squad ??= await ref.read(squadControllerProvider.notifier).loadMine();
    if (!mounted) return;
    setState(() => _squadId = squad?.id);
    if (squad != null) await _reload();
  }

  Future<void> _reload() async {
    final squadId = _squadId;
    if (squadId == null) return;
    try {
      await ref.read(clashControllerProvider.notifier).load(squadId);
      if (!mounted) return;
      final snapshot = ref.read(clashControllerProvider).valueOrNull;
      if (snapshot != null) _hydratePreferences(snapshot.preferences);
    } catch (_) {
      if (mounted) _message('No fue posible actualizar los empalmes.');
    }
  }

  void _hydratePreferences(MusicPreferences preferences) {
    if (_preferencesHydrated) return;
    setState(() {
      _selectedGenres
        ..clear()
        ..addAll(preferences.manualGenres);
      _artistsController.text = preferences.manualArtists.join(', ');
      _preferencesHydrated = true;
    });
  }

  List<String> get _artists => _artistsController.text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .take(12)
      .toList(growable: false);

  Future<void> _savePreferences() async {
    final squadId = _squadId;
    if (squadId == null) return;
    if (_selectedGenres.isEmpty && _artists.isEmpty) {
      _message('Selecciona al menos un género o escribe un artista.');
      return;
    }
    try {
      await ref.read(clashControllerProvider.notifier).saveManual(
            squadId,
            _selectedGenres.toList(growable: false),
            _artists,
          );
      if (mounted) _message('Preferencias guardadas.');
    } catch (_) {
      if (mounted) _message('No fue posible guardar las preferencias.');
    }
  }

  Future<void> _connectSpotify() async {
    try {
      final value = await ref
          .read(clashControllerProvider.notifier)
          .spotifyAuthorizationUrl();
      final opened = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _message('No se pudo abrir Spotify.');
    } catch (error) {
      if (mounted) {
        _message(error.toString().contains('configurado')
            ? 'Spotify aún no está configurado. Usa el fallback manual.'
            : 'Spotify no está disponible. Usa el fallback manual.');
      }
    }
  }

  Future<void> _resolve(ClashConflict conflict) async {
    final squadId = _squadId;
    if (squadId == null) return;
    try {
      await ref
          .read(clashControllerProvider.notifier)
          .recommend(squadId, conflict);
    } catch (_) {
      if (mounted) _message('No se pudo calcular la recomendación.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clashControllerProvider);
    final snapshot = state.valueOrNull;
    if (snapshot != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? _hydratePreferences(snapshot.preferences) : null,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clash Resolver'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: state.isLoading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FestiBody(
        child: _squadId == null
            ? _NoSquad(onRetry: _initialize)
            : RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _Header(snapshot: snapshot),
                    const SizedBox(height: 16),
                    _SpotifySection(
                      preferences:
                          snapshot?.preferences ?? const MusicPreferences(),
                      onConnect: state.isLoading ? null : _connectSpotify,
                    ),
                    const SizedBox(height: 16),
                    _manualPreferences(
                        state.isLoading, snapshot?.syncPending ?? false),
                    const SizedBox(height: 20),
                    _conflicts(snapshot, state.isLoading),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _manualPreferences(bool loading, bool syncPending) {
    return FestiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('PREFERENCIAS MANUALES',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              if (syncPending)
                const StatusPill('Pendiente', icon: Icons.cloud_off_outlined),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Funcionan aunque Spotify no esté disponible.',
            style: TextStyle(color: FestiColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final genre in _availableGenres)
                FilterChip(
                  label: Text(genre),
                  selected: _selectedGenres.contains(genre),
                  onSelected: loading
                      ? null
                      : (selected) => setState(() => selected
                          ? _selectedGenres.add(genre)
                          : _selectedGenres.remove(genre)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _artistsController,
            enabled: !loading,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Artistas favoritos',
              hintText: 'Ej. Tame Impala, The Strokes',
              helperText: 'Sepáralos con comas',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loading ? null : _savePreferences,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar preferencias'),
          ),
        ],
      ),
    );
  }

  Widget _conflicts(ClashSnapshot? snapshot, bool loading) {
    final conflicts = snapshot?.conflicts ?? const <ClashConflict>[];
    if (loading && snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (conflicts.isEmpty) {
      return FestiCard(
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined,
                size: 38, color: FestiColors.cyan),
            const SizedBox(height: 12),
            const Text('No hay empalmes cargados',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              snapshot?.festivalName == null
                  ? 'Agrega el festival y sus horarios en SQL Server.'
                  : 'La agenda de ${snapshot!.festivalName} no tiene conflictos.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FestiColors.muted),
            ),
          ],
        ),
      );
    }
    if (_selectedConflict >= conflicts.length) _selectedConflict = 0;
    final conflict = conflicts[_selectedConflict];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(snapshot?.festivalName ?? 'Agenda',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (conflicts.length > 1)
          SegmentedButton<int>(
            segments: [
              for (var index = 0; index < conflicts.length; index++)
                ButtonSegment(value: index, label: Text('${index + 1}')),
            ],
            selected: {_selectedConflict},
            onSelectionChanged: (values) =>
                setState(() => _selectedConflict = values.first),
          ),
        if (conflicts.length > 1) const SizedBox(height: 12),
        FestiCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EMPALME · ${_time(conflict.startsAt)}',
                  style: const TextStyle(
                      color: FestiColors.cyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              const SizedBox(height: 12),
              for (final option in conflict.options) ...[
                _ConcertRow(option: option),
                if (option != conflict.options.last)
                  const Divider(color: FestiColors.border),
              ],
              const SizedBox(height: 14),
              BlueButton(
                label: 'Resolver empalme',
                icon: Icons.auto_awesome_outlined,
                onPressed: loading ? null : () => _resolve(conflict),
              ),
            ],
          ),
        ),
        if (snapshot?.recommendation != null) ...[
          const SizedBox(height: 14),
          _RecommendationCard(value: snapshot!.recommendation!),
        ],
      ],
    );
  }

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot});
  final ClashSnapshot? snapshot;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decidan con datos',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('Compara gustos del squad cuando dos shows se empalman.',
                    style: TextStyle(color: FestiColors.muted, height: 1.35)),
              ],
            ),
          ),
          if (snapshot?.fromCache ?? false)
            const StatusPill('Offline', icon: Icons.cloud_off_outlined),
        ],
      );
}

class _SpotifySection extends StatelessWidget {
  const _SpotifySection({required this.preferences, required this.onConnect});
  final MusicPreferences preferences;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) => FestiCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.graphic_eq_rounded,
                color: Color(0xFF1ED760), size: 30),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preferences.spotifyConnected
                        ? 'Spotify conectado'
                        : 'Conecta Spotify',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    preferences.spotifyConnected
                        ? '${preferences.spotifyArtists.length} artistas y ${preferences.spotifyGenres.length} géneros importados.'
                        : 'Importa tus artistas y géneros más escuchados.',
                    style:
                        const TextStyle(color: FestiColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(preferences.spotifyConnected
                        ? 'Actualizar'
                        : 'Conectar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ConcertRow extends StatelessWidget {
  const _ConcertRow({required this.option});
  final ConcertOption option;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2338),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.music_note_rounded, color: FestiColors.cyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.artist,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(option.stage,
                      style: const TextStyle(
                          color: FestiColors.muted, fontSize: 12)),
                  if (option.genres.isNotEmpty)
                    Text(option.genres.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: FestiColors.cyan, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.value});
  final ClashRecommendation value;

  @override
  Widget build(BuildContext context) => FestiCard(
        glow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: FestiColors.cyan),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('RECOMENDACIÓN',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                if (value.offline) const StatusPill('Local'),
              ],
            ),
            const SizedBox(height: 13),
            Text(value.selectedArtist,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            Text(value.selectedStage,
                style: const TextStyle(color: FestiColors.cyan)),
            const SizedBox(height: 9),
            Text(value.reason,
                style: const TextStyle(color: FestiColors.muted, height: 1.4)),
          ],
        ),
      );
}

class _NoSquad extends StatelessWidget {
  const _NoSquad({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined,
                  size: 42, color: FestiColors.cyan),
              const SizedBox(height: 12),
              const Text('Únete a un squad para comparar preferencias.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
