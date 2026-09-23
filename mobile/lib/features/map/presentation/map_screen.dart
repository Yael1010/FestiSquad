import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_sync_policy.dart';
import '../../squads/presentation/squad_preview.dart';
import '../data/offline_map_repository.dart';
import '../domain/festival_map.dart';
import 'widgets/map_canvas.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  final _policy = const LocationSyncPolicy();
  StreamSubscription<Position>? _positions;
  FestivalMapSnapshot? _snapshot;
  MapPoint? _myLocation;
  LocationSnapshot? _lastSent;
  bool _loading = true;
  bool _tracking = false;
  bool _sending = false;
  bool _isInBackground = false;
  bool _backgroundPermissionGranted = false;
  String? _error;

  String? get _squadId => activeSquadPreview.value.id;

  bool get _supportsBackgroundTracking =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _canTrackInBackground =>
      _supportsBackgroundTracking && _backgroundPermissionGranted;

  LocationSettings get _locationSettings {
    if (_canTrackInBackground) {
      return AndroidSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 15,
        intervalDuration: Duration(seconds: 30),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'FestiSquad comparte tu ubicación',
          notificationText:
              'Solo se sincroniza al moverte y como máximo cada 3 minutos.',
          enableWakeLock: false,
          setOngoing: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 15,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result =
          await ref.read(offlineMapRepositoryProvider).load(_squadId);
      if (!mounted) return;
      setState(() {
        _snapshot = result;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No fue posible cargar el mapa guardado.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startTracking() async {
    if (_positions != null) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _show('Activa la ubicación del dispositivo.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _show('El permiso de ubicación está desactivado.');
        return;
      }
      _backgroundPermissionGranted = permission == LocationPermission.always;
      if (_supportsBackgroundTracking && !_backgroundPermissionGranted) {
        _showBackgroundPermissionHint();
      }
      final current = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      await _onPosition(current);
      if (!mounted) return;
      _positions = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (position) => unawaited(_onPosition(position)),
        onError: (_) {
          _stopTracking();
          _show('Se interrumpió el GPS. El mapa sigue disponible.');
        },
      );
      setState(() => _tracking = true);
    } catch (_) {
      _show('No fue posible obtener tu ubicación.');
    }
  }

  Future<void> _onPosition(Position position) async {
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    final current = LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: now,
    );
    _myLocation = MapPoint(position.latitude, position.longitude);
    if (!_isInBackground) setState(() {});
    if (_squadId == null || _sending) return;
    if (!_policy.shouldSync(
      lastSynced: _lastSent,
      current: current,
      isInBackground: _isInBackground,
    )) {
      return;
    }
    _sending = true;
    try {
      await ref.read(offlineMapRepositoryProvider).sendLocation(
            squadId: _squadId!,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
            recordedAt: now,
          );
      _lastSent = current;
    } catch (_) {
      _show('Ubicación no enviada. Reintenta al volver la red.');
    } finally {
      _sending = false;
    }
  }

  Future<void> _addMeetingPoint() async {
    if (_squadId == null || _myLocation == null) {
      _show('Activa tu ubicación y selecciona un squad.');
      return;
    }
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo punto de encuentro'),
        content: TextField(
          controller: controller,
          maxLength: 120,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    try {
      await ref.read(offlineMapRepositoryProvider).createMeetingPoint(
            squadId: _squadId!,
            title: title,
            latitude: _myLocation!.latitude,
            longitude: _myLocation!.longitude,
          );
      await _load();
    } catch (_) {
      _show('No se pudo guardar el punto. Intenta con conexión.');
    }
  }

  void _stopTracking() {
    final subscription = _positions;
    _positions = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (mounted) setState(() => _tracking = false);
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showBackgroundPermissionHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text(
          'Para compartir en segundo plano, permite la ubicación todo el tiempo.',
        ),
        action: SnackBarAction(
          label: 'AJUSTES',
          onPressed: () => unawaited(Geolocator.openAppSettings()),
        ),
      ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInBackground = state != AppLifecycleState.resumed;
    if (_isInBackground && !_canTrackInBackground) {
      _stopTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final subscription = _positions;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: snapshot == null
                ? const ColoredBox(color: Color(0xFF081423))
                : FestivalMapCanvas(
                    snapshot: snapshot,
                    myLocation: _myLocation,
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Volver',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot?.festival.name ?? 'Mapa del festival',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Actualizar mapa',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (snapshot != null)
                    Text(
                      snapshot.festival.isDemo
                          ? 'PLANO DE DEMOSTRACIÓN'
                          : snapshot.fromCache
                              ? 'DATOS GUARDADOS · SIN CONEXIÓN'
                              : 'DATOS ACTUALIZADOS',
                      style: const TextStyle(
                        color: Color(0xFF35C4CF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        IconButton.filled(
                          tooltip: _tracking
                              ? 'Detener ubicación'
                              : 'Activar mi ubicación',
                          onPressed: _tracking ? _stopTracking : _startTracking,
                          icon: Icon(_tracking
                              ? Icons.location_disabled
                              : Icons.my_location),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Crear punto de encuentro',
                          onPressed: _addMeetingPoint,
                          icon: const Icon(Icons.add_location_alt_outlined),
                        ),
                      ],
                    ),
                  ),
                  if (snapshot != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xDD081423),
                      child: Text(
                        '${snapshot.locations.length} últimas ubicaciones  ·  '
                        '${snapshot.meetingPoints.length} puntos de encuentro',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
