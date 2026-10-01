import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../clash_resolver/application/clash_controller.dart';
import '../../clash_resolver/data/clash_repository.dart';
import '../../clash_resolver/domain/clash_models.dart';
import '../../finances/data/finance_repository.dart';
import '../../finances/domain/finance_models.dart';
import '../../finances/domain/money.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../application/squad_controller.dart';
import '../data/squad_repository.dart';
import '../domain/squad.dart';
import 'squad_preview.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';
  FinanceSnapshot? _financeSnapshot;
  String? _financeSquadId;
  bool _financeLoading = false;
  List<SquadMemberProfile> _squadMembers = const [];
  MusicPreferences? _musicPreferences;
  bool _spotifyLoading = false;
  bool _avatarSaving = false;
  final ImagePicker _imagePicker = ImagePicker();
  static const _searchItems = [
    ('Festivales y escenarios', '/festivals', 'escenarios mapa festival'),
    ('Mi squad · Amigos', '/join', 'amigos squad'),
    ('Fondo común · Compras', '/finances', 'compras finanzas fondo'),
  ];
  bool _matches((String, String, String) item) =>
      '${item.$1.toLowerCase()} ${item.$3}'.contains(_query);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSquad());
  }

  Future<void> _loadSquad() async {
    await ref.read(authControllerProvider.notifier).initialized;
    if (!mounted) return;
    if (ref.read(authControllerProvider).valueOrNull == null) return;
    activeSquadPreview.value = const SquadPreview('Cargando squad…', 0);
    setState(() {
      _squadMembers = const [];
      _musicPreferences = null;
      _financeSnapshot = null;
    });
    try {
      final squad = await _loadSquadWithRetry();
      if (squad == null) {
        activeSquadPreview.value = const SquadPreview('Sin squad activo', 0);
        return;
      }
      activeSquadPreview.value = SquadPreview(
        squad.name,
        squad.memberIds.length,
        id: squad.id,
        code: squad.code,
      );
      unawaited(_loadFinance(squad.id));
      unawaited(_loadMembers(squad.id));
      unawaited(_loadSpotifyStatus());
      if (ref.read(squadControllerProvider.notifier).lastLoadWasFromCache) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mostrando el squad guardado en este dispositivo.'),
          ),
        );
      }
    } on SquadRequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<Squad?> _loadSquadWithRetry() async {
    try {
      return await ref.read(squadControllerProvider.notifier).loadMine();
    } on SquadRequestException {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return ref.read(squadControllerProvider.notifier).loadMine();
    }
  }

  Future<void> _loadMembers(String squadId) async {
    try {
      final result = await ref
          .read(squadRepositoryProvider)
          .loadMembers(squadId, forceRefresh: true);
      if (!mounted || activeSquadPreview.value.id != squadId) return;
      setState(() => _squadMembers = result.value);
    } catch (_) {
      // El contador del squad sigue siendo exacto aunque falle el detalle.
    }
  }

  Future<void> _loadSpotifyStatus() async {
    if (mounted) setState(() => _spotifyLoading = true);
    try {
      final preferences =
          await ref.read(clashRemoteDataSourceProvider).preferences();
      if (!mounted) return;
      setState(() => _musicPreferences = preferences);
    } catch (_) {
      final cached = ref.read(clashControllerProvider).valueOrNull;
      if (mounted && cached != null) {
        setState(() => _musicPreferences = cached.preferences);
      }
    } finally {
      if (mounted) setState(() => _spotifyLoading = false);
    }
  }

  Future<void> _loadFinance(String squadId) async {
    if (mounted) {
      setState(() {
        _financeLoading = true;
        _financeSquadId = squadId;
      });
    }
    try {
      final snapshot = await ref.read(financeRepositoryProvider).load(squadId);
      if (!mounted || _financeSquadId != squadId) return;
      setState(() => _financeSnapshot = snapshot);
    } catch (_) {
      if (!mounted || _financeSquadId != squadId) return;
      setState(() => _financeSnapshot = null);
    } finally {
      if (mounted && _financeSquadId == squadId) {
        setState(() => _financeLoading = false);
      }
    }
  }

  Future<void> _openFinances(String? squadId) async {
    await context.push('/finances');
    if (mounted && squadId != null) {
      await _loadFinance(squadId);
    }
  }

  Future<void> _createSquad() async {
    var draftName = '';
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Crear nuevo squad'),
                content: TextField(
                    onChanged: (value) => draftName = value,
                    autofocus: true,
                    maxLength: 40,
                    decoration: const InputDecoration(
                        labelText: 'Nombre del squad',
                        helperText:
                            'Recibirás un código privado para compartir.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () {
                        if (draftName.trim().isNotEmpty) {
                          Navigator.pop(context, draftName.trim());
                        }
                      },
                      child: const Text('Crear'))
                ]));
    if (name == null) return;
    try {
      final squad =
          await ref.read(squadControllerProvider.notifier).create(name);
      activeSquadPreview.value = SquadPreview(
        squad.name,
        squad.memberIds.length,
        id: squad.id,
        code: squad.code,
      );
      unawaited(_loadFinance(squad.id));
      unawaited(_loadMembers(squad.id));
      unawaited(_loadSpotifyStatus());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Squad creado. Código: ${squad.code}')),
      );
    } on SquadRequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _openProfile() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      showFeatureInfo(context, 'Perfil de demostración',
          'Explora las interfaces sin crear una cuenta.');
      return;
    }

    UserProfile? profile;
    try {
      profile = await ref.read(profileRepositoryProvider).getMe();
    } catch (_) {
      // El perfil puede abrirse con los datos del squad si la red falla.
    }
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: FestiColors.surface,
      builder: (context) => _ProfileSheet(
        name: profile?.name.trim().isNotEmpty == true
            ? profile!.name.trim()
            : _displayName,
        email: profile?.email,
        avatarUrl: profile?.avatarUrl ?? _displayAvatarUrl,
        spotifyConnected: _musicPreferences?.spotifyConnected == true,
      ),
    );
    if (action == 'google' || action == 'spotify') {
      if (mounted) showSocialAuthSheet(context, action!, link: true);
      return;
    }
    if (action == 'avatar') {
      await _changeAvatar();
      return;
    }
    if (action == 'remove_avatar') {
      await _removeAvatar();
      return;
    }
    if (action != 'logout') return;
    await ref.read(authControllerProvider.notifier).logout();
    activeSquadPreview.value = const SquadPreview('Sin squad activo', 0);
    if (mounted) context.go('/login');
  }

  Future<void> _changeAvatar() async {
    if (_avatarSaving) return;
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      _showMessage('La imagen no puede superar 5 MB.');
      return;
    }
    setState(() => _avatarSaving = true);
    try {
      final profile = await ref.read(profileRepositoryProvider).uploadAvatar(
            bytes: bytes,
            filename: image.name.isEmpty ? 'perfil.jpg' : image.name,
          );
      if (!mounted) return;
      setState(() {
        _squadMembers = _squadMembers
            .map((member) => member.isCurrentUser
                ? member.copyWith(avatarUrl: profile.avatarUrl)
                : member)
            .toList(growable: false);
      });
      _showMessage('Foto de perfil actualizada.');
    } catch (error) {
      if (mounted) _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _avatarSaving = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarSaving) return;
    setState(() => _avatarSaving = true);
    try {
      final profile = await ref.read(profileRepositoryProvider).removeAvatar();
      if (!mounted) return;
      setState(() {
        _squadMembers = _squadMembers
            .map((member) => member.isCurrentUser
                ? member.copyWith(avatarUrl: profile.avatarUrl)
                : member)
            .toList(growable: false);
      });
      _showMessage('Se restauró la foto vinculada o las iniciales.');
    } catch (error) {
      if (mounted) _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _avatarSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openClash() async {
    await context.push('/clash');
    if (mounted) await _loadSpotifyStatus();
  }

  String get _displayName {
    for (final member in _squadMembers) {
      if (member.isCurrentUser) return member.name.trim();
    }
    return ref.read(authControllerProvider).valueOrNull == null
        ? 'Invitado'
        : 'Mi perfil';
  }

  String get _displayInitials {
    final words = _displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final value = words.map((word) => word[0].toUpperCase()).join();
    return value.isEmpty ? 'FS' : value;
  }

  String? get _displayAvatarUrl {
    for (final member in _squadMembers) {
      if (member.isCurrentUser) return member.avatarUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final displayInitials = _displayInitials;
    final displayAvatarUrl = _displayAvatarUrl;
    return Scaffold(
      body: SafeArea(
          child: FestiBody(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  children: [
            Row(children: [
              _DashboardAvatar(
                initials: displayInitials,
                avatarUrl: displayAvatarUrl,
                saving: _avatarSaving,
                onEdit: _changeAvatar,
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    const Text('En sintonía con tu squad',
                        style:
                            TextStyle(color: FestiColors.cyan, fontSize: 12)),
                  ])),
              IconButton.filledTonal(
                  tooltip: 'Notificaciones',
                  onPressed: () => showFeatureInfo(context, 'Notificaciones',
                      'No tienes notificaciones nuevas.'),
                  icon: const Icon(Icons.notifications_none_rounded)),
              IconButton(
                  tooltip: 'Perfil',
                  onPressed: _openProfile,
                  icon: const Icon(Icons.account_circle_outlined,
                      color: FestiColors.cyan)),
            ]),
            const SizedBox(height: 20),
            TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: FestiColors.muted),
                    hintText: 'Buscar escenarios, amigos o compras…',
                    hintStyle:
                        TextStyle(fontSize: 14, color: FestiColors.muted))),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 12),
              FestiCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    for (final item in _searchItems)
                      if (_matches(item))
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.$1),
                            trailing: const Icon(Icons.arrow_forward,
                                color: FestiColors.cyan),
                            onTap: () => context.push(item.$2)),
                    if (!_searchItems.any(_matches))
                      const Text(
                          'Sin resultados. Prueba “mapa”, “amigos” o “compras”.',
                          style: TextStyle(color: FestiColors.muted)),
                  ])),
            ],
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => context.push('/join'),
                      icon: const Icon(Icons.tag, size: 19),
                      label: const Text('Unirse con código',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)))),
              const SizedBox(width: 12),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _createSquad,
                      icon: const Icon(Icons.person_add_alt_1, size: 19),
                      label: const Text('Crear nuevo squad',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12))))
            ]),
            const SizedBox(height: 18),
            ValueListenableBuilder<SquadPreview>(
                valueListenable: activeSquadPreview,
                builder: (context, squad, _) =>
                    LayoutBuilder(builder: (context, constraints) {
                      final cards = [
                        FestiCard(
                            glow: true,
                            onTap: () {
                              if (squad.id == null) {
                                showFeatureInfo(
                                  context,
                                  squad.name,
                                  'Crea o selecciona un squad para consultar sus integrantes.',
                                );
                                return;
                              }
                              context.push(
                                '/squads/${squad.id}?name=${Uri.encodeQueryComponent(squad.name)}&code=${squad.code ?? '------'}',
                              );
                            },
                            padding: const EdgeInsets.all(17),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Expanded(
                                        child: Text('SQUAD ACTIVO',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: FestiColors.muted))),
                                    _SquadSignalTrigger(
                                      onActivated: () {
                                        HapticFeedback.heavyImpact();
                                        context.push(
                                          '/squad-signal?name=${Uri.encodeQueryComponent(squad.name)}&code=${Uri.encodeQueryComponent(squad.code ?? '------')}',
                                        );
                                      },
                                    ),
                                  ]),
                                  const SizedBox(height: 5),
                                  Text(squad.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: FestiColors.cyan)),
                                  const SizedBox(height: 12),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('${squad.members}',
                                            style: const TextStyle(
                                                fontSize: 44,
                                                height: 1,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(width: 10),
                                        const Flexible(
                                            child: Text('Amigos\n• en línea',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: FestiColors.cyan)))
                                      ]),
                                  const SizedBox(height: 22),
                                  _SquadAvatars(
                                    memberCount: squad.members,
                                    members: _squadMembers,
                                    demo: ref
                                            .watch(authControllerProvider)
                                            .valueOrNull ==
                                        null,
                                  ),
                                ])),
                        _FinanceDashboardCard(
                          snapshot: _financeSnapshot,
                          loading: _financeLoading,
                          onTap: () => _openFinances(squad.id),
                        ),
                      ];
                      if (constraints.maxWidth < 330 ||
                          MediaQuery.textScalerOf(context).scale(14) > 20) {
                        return Column(children: [
                          cards[0],
                          const SizedBox(height: 14),
                          cards[1]
                        ]);
                      }
                      return IntrinsicHeight(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 14),
                            Expanded(child: cards[1])
                          ]));
                    })),
            const SizedBox(height: 18),
            FestiCard(
                glow: true,
                padding: EdgeInsets.zero,
                onTap: () => context.push('/festivals'),
                child: SizedBox(
                    height: 206 *
                        (MediaQuery.textScalerOf(context).scale(14) / 14)
                            .clamp(1, 2),
                    child: Stack(fit: StackFit.expand, children: [
                      const CustomPaint(painter: _FestivalPainter()),
                      Container(
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Color(0x22060B16),
                            Color(0xFF060B16)
                          ]))),
                      const Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  StatusPill('Mapa del festival',
                                      icon: Icons.location_on),
                                  StatusPill('VISTA PREVIA')
                                ]),
                                Spacer(),
                                Text('Catálogo de festivales',
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: 8),
                                Text('Selecciona el recinto y abre su mapa',
                                    style: TextStyle(
                                        color: FestiColors.cyan, fontSize: 12)),
                              ])),
                    ]))),
            const SizedBox(height: 18),
            FestiCard(
                onTap: _openClash,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('SUGERENCIA INTELIGENTE',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: .5)),
                            StatusPill(
                              ref.watch(authControllerProvider).valueOrNull ==
                                      null
                                  ? 'Spotify · Sin conectar'
                                  : _spotifyLoading
                                      ? 'Spotify · Consultando'
                                      : _musicPreferences == null
                                          ? 'Spotify · No disponible'
                                          : _musicPreferences!.spotifyConnected
                                              ? 'Spotify · Conectado'
                                              : 'Spotify · Sin conectar',
                              icon: Icons.graphic_eq,
                            )
                          ]),
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: FestiColors.background,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: FestiColors.border)),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.bolt_rounded,
                                    color: FestiColors.cyan),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          ref
                                                      .watch(
                                                          authControllerProvider)
                                                      .valueOrNull ==
                                                  null
                                              ? '¡Empalme a las 8:00 PM!'
                                              : 'Revisa los próximos empalmes',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15)),
                                      const SizedBox(height: 7),
                                      Text(
                                          ref
                                                      .watch(
                                                          authControllerProvider)
                                                      .valueOrNull ==
                                                  null
                                              ? 'Tu artista favorito coincide con la votación del squad en el Escenario Corona.'
                                              : 'Abre Clash Resolver para consultar las recomendaciones reales de tu squad.',
                                          style: const TextStyle(
                                              color: FestiColors.muted,
                                              fontSize: 13,
                                              height: 1.4))
                                    ])),
                              ])),
                    ])),
            if (ref.watch(authControllerProvider).valueOrNull == null) ...[
              const SizedBox(height: 18),
              const Center(
                  child: Text('DEMOSTRACIÓN · DATOS DE EJEMPLO',
                      style: TextStyle(
                          color: FestiColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.2))),
            ],
          ]))),
      bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF080F1C),
          indicatorColor: const Color(0xFF103952),
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index != 0) {
              context.push(
                  ['/dashboard', '/festivals', '/finances', '/clash'][index]);
            }
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_rounded, color: FestiColors.cyan),
                label: 'Inicio'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined), label: 'Mapa'),
            NavigationDestination(
                icon: Icon(Icons.payments_outlined), label: 'Finanzas'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined), label: 'Agenda')
          ]),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.spotifyConnected,
  });

  final String name;
  final String? email;
  final String? avatarUrl;
  final bool spotifyConnected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 4, 22, 22 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mi perfil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _ProfilePhoto(
                  name: name,
                  avatarUrl: avatarUrl,
                  onTap: () => Navigator.pop(context, 'avatar'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? 'Cuenta FestiSquad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FestiColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          SizedBox(
                            width: 7,
                            height: 7,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: FestiColors.success,
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Sesión activa',
                            style: TextStyle(
                              color: FestiColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _ProfileSectionLabel('PERSONALIZACIÓN'),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.photo_camera_outlined,
              title: 'Cambiar foto de perfil',
              subtitle: 'Elige una imagen desde tu dispositivo',
              onTap: () => Navigator.pop(context, 'avatar'),
            ),
            if (avatarUrl != null)
              _ProfileAction(
                icon: Icons.person_remove_outlined,
                title: 'Restaurar foto vinculada',
                subtitle: 'Usa tu foto social o tus iniciales',
                onTap: () => Navigator.pop(context, 'remove_avatar'),
              ),
            const SizedBox(height: 18),
            const _ProfileSectionLabel('CUENTAS VINCULADAS'),
            const SizedBox(height: 8),
            _ProfileAction(
              leading: const Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              title: 'Google',
              subtitle: 'Vincula otra forma de iniciar sesión',
              trailing: 'Vincular',
              onTap: () => Navigator.pop(context, 'google'),
            ),
            _ProfileAction(
              icon: Icons.graphic_eq_rounded,
              iconColor:
                  spotifyConnected ? FestiColors.success : FestiColors.cyan,
              title: 'Spotify',
              subtitle: spotifyConnected
                  ? 'Preferencias musicales sincronizadas'
                  : 'Conecta tus artistas y géneros',
              trailing: spotifyConnected ? 'Conectado' : 'Vincular',
              trailingColor:
                  spotifyConnected ? FestiColors.success : FestiColors.cyan,
              onTap: () => Navigator.pop(context, 'spotify'),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'logout'),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('CERRAR SESIÓN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FestiColors.danger,
                side: const BorderSide(color: Color(0xFF633445)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF173B67),
            border: Border.all(color: FestiColors.cyan, width: 2),
          ),
          child: avatarUrl == null
              ? Text(
                  initials.isEmpty ? 'FS' : initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Image.network(
                  avatarUrl!,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    initials.isEmpty ? 'FS' : initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: IconButton.filled(
            tooltip: 'Cambiar foto',
            onPressed: onTap,
            style: IconButton.styleFrom(
              minimumSize: const Size(30, 30),
              fixedSize: const Size(30, 30),
              padding: EdgeInsets.zero,
              backgroundColor: FestiColors.cyan,
              foregroundColor: FestiColors.background,
              side: const BorderSide(color: FestiColors.surface, width: 3),
            ),
            icon: const Icon(Icons.edit_rounded, size: 15),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: FestiColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = FestiColors.cyan,
    this.trailing,
    this.trailingColor = FestiColors.cyan,
  }) : assert(icon != null || leading != null);

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final String? trailing;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF111F34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FestiColors.border),
              ),
              child: leading ?? Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FestiColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: TextStyle(
                  color: trailingColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else
              const Icon(
                Icons.chevron_right_rounded,
                color: FestiColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class _SquadAvatars extends StatelessWidget {
  const _SquadAvatars({
    required this.memberCount,
    required this.members,
    required this.demo,
  });

  final int memberCount;
  final List<SquadMemberProfile> members;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    if (demo) {
      return const Wrap(
        spacing: -5,
        children: [_Avatar('YL'), _Avatar('AM'), _Avatar('JC'), _Avatar('+2')],
      );
    }

    final visibleCount = memberCount > 3 ? 3 : memberCount;
    return Wrap(
      spacing: -5,
      children: [
        for (var index = 0; index < visibleCount; index++)
          _Avatar.fromMember(index < members.length ? members[index] : null),
        if (memberCount > visibleCount)
          _Avatar('+${memberCount - visibleCount}'),
      ],
    );
  }
}

class _FinanceDashboardCard extends ConsumerWidget {
  const _FinanceDashboardCard({
    required this.snapshot,
    required this.loading,
    required this.onTap,
  });

  final FinanceSnapshot? snapshot;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    if (session == null) {
      return FestiCard(
        onTap: onTap,
        padding: const EdgeInsets.all(17),
        child: const _DemoFinanceSummary(),
      );
    }

    final balance = snapshot?.netBalances[session.userId] ?? Money.zero;
    final hasSnapshot = snapshot != null;
    final amount = hasSnapshot
        ? Money.fromCents(balance.cents.abs()).toDecimalString()
        : '--';
    final label = loading && !hasSnapshot
        ? 'Actualizando saldo'
        : !hasSnapshot
            ? 'Saldo no disponible'
            : balance.cents < 0
                ? 'Pendiente por pagar'
                : balance.cents > 0
                    ? 'Pendiente por recibir'
                    : 'Al corriente';
    final amountColor =
        balance.cents < 0 ? const Color(0xFFFF8D8D) : FestiColors.cyan;
    final latest = snapshot?.expenses.firstOrNull;

    return FestiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'FONDO COMÚN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FestiColors.muted,
                  ),
                ),
              ),
              Icon(
                Icons.account_balance_wallet_rounded,
                color: FestiColors.cyan,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 26),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasSnapshot ? 'MXN \$$amount' : amount,
              style: TextStyle(
                color: hasSnapshot ? amountColor : FestiColors.muted,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: FestiColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 19),
          const Divider(color: FestiColors.border),
          Text(
            latest == null
                ? 'Sin tickets registrados'
                : 'Último ticket: ${latest.description} · ${latest.amount.format()}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: latest == null ? FestiColors.muted : FestiColors.cyan,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoFinanceSummary extends StatelessWidget {
  const _DemoFinanceSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'FONDO COMÚN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FestiColors.muted,
                ),
              ),
            ),
            Icon(
              Icons.account_balance_wallet_rounded,
              color: FestiColors.cyan,
              size: 18,
            ),
          ],
        ),
        SizedBox(height: 26),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '\$500',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '.00',
                  style: TextStyle(
                    fontSize: 18,
                    color: FestiColors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'MXN disponible',
          style: TextStyle(color: FestiColors.muted, fontSize: 12),
        ),
        SizedBox(height: 19),
        Divider(color: FestiColors.border),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Último gasto: ',
                style: TextStyle(color: FestiColors.muted),
              ),
              TextSpan(
                text: '-\$120',
                style: TextStyle(color: FestiColors.cyan),
              ),
            ],
          ),
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _SquadSignalTrigger extends StatefulWidget {
  const _SquadSignalTrigger({required this.onActivated});

  final VoidCallback onActivated;

  @override
  State<_SquadSignalTrigger> createState() => _SquadSignalTriggerState();
}

class _SquadSignalTriggerState extends State<_SquadSignalTrigger> {
  Timer? _holdTimer;
  bool _activated = false;

  void _startHold(TapDownDetails _) {
    _holdTimer?.cancel();
    _activated = false;
    _holdTimer = Timer(const Duration(seconds: 3), () {
      _activated = true;
      widget.onActivated();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Activar señal del squad',
      button: true,
      onLongPress: widget.onActivated,
      child: GestureDetector(
        key: const ValueKey('squad-signal-trigger'),
        behavior: HitTestBehavior.opaque,
        onTapDown: _startHold,
        onTapUp: (_) => _cancelHold(),
        onTapCancel: _cancelHold,
        onTap: () {
          if (!_activated) _cancelHold();
        },
        child: const Icon(
          Icons.bolt,
          size: 18,
          color: FestiColors.cyan,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.label) : avatarUrl = null;
  _Avatar.fromMember(SquadMemberProfile? member)
      : label = member == null ? '?' : _initialsFor(member.name),
        avatarUrl = member?.avatarUrl;
  final String label;
  final String? avatarUrl;

  static String _initialsFor(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) => Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF153D5B),
          border: Border.all(color: FestiColors.cyan)),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: FestiColors.cyan,
                  fontWeight: FontWeight.bold))
          : Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      color: FestiColors.cyan,
                      fontWeight: FontWeight.bold)),
            ));
}

class _DashboardAvatar extends StatelessWidget {
  const _DashboardAvatar({
    required this.initials,
    required this.avatarUrl,
    required this.saving,
    required this.onEdit,
  });

  final String initials;
  final String? avatarUrl;
  final bool saving;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: FestiColors.cyan),
            boxShadow: [
              BoxShadow(
                color: FestiColors.cyan.withValues(alpha: .18),
                blurRadius: 16,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFF173B67),
            foregroundImage:
                avatarUrl == null ? null : NetworkImage(avatarUrl!),
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Positioned(
          right: -5,
          bottom: -5,
          child: Material(
            color: FestiColors.cyan,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: saving ? null : onEdit,
              child: SizedBox(
                width: 23,
                height: 23,
                child: saving
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit,
                        size: 13, color: Color(0xFF071120)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FestivalPainter extends CustomPainter {
  const _FestivalPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF102F56));
    for (var i = 0; i < 9; i++) {
      final x = size.width * i / 8;
      final beam = Path()
        ..moveTo(size.width * .7, 95)
        ..lineTo(x - 35, 0)
        ..lineTo(x + 20, 0)
        ..close();
      canvas.drawPath(
          beam,
          Paint()
            ..color = (i.isEven ? FestiColors.cyan : FestiColors.blue)
                .withValues(alpha: .2));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * .55, 55, size.width * .36, 65),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF081728));
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
          Rect.fromLTWH(size.width * .58 + i * size.width * .05, 65, 6, 35),
          Paint()..color = FestiColors.cyan.withValues(alpha: .7));
    }
    for (var i = 0; i < 110; i++) {
      final x = ((i * 37) % 503) / 503 * size.width;
      final y = 115 + ((i * 19) % 80).toDouble();
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = const Color(0xFF287198));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
