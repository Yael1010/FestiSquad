import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/squad_controller.dart';
import 'squad_preview.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _query = '';
  static const _searchItems = [
    ('Escenario Corona', '/map', 'escenarios mapa corona'),
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
    if (ref.read(authControllerProvider).valueOrNull == null) return;
    try {
      final squad = await ref.read(squadControllerProvider.notifier).loadMine();
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
    } on SquadRequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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

    final logout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesión activa'),
        content: Text('Usuario ${session.userId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (logout != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: FestiBody(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: FestiColors.cyan),
                        boxShadow: [
                          BoxShadow(
                              color: FestiColors.cyan.withValues(alpha: .18),
                              blurRadius: 16)
                        ]),
                    child: const CircleAvatar(
                        radius: 23,
                        backgroundColor: Color(0xFF173B67),
                        child: Text('YF',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)))),
                const SizedBox(width: 14),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: 'Yael ',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(
                                text: 'Flores',
                                style: TextStyle(color: FestiColors.muted))
                          ]),
                          style: TextStyle(fontSize: 21)),
                      SizedBox(height: 5),
                      Text('•  En sintonía con tu squad',
                          style:
                              TextStyle(color: FestiColors.cyan, fontSize: 12)),
                    ])),
                IconButton.filledTonal(
                    tooltip: 'Notificaciones',
                    onPressed: () => showFeatureInfo(context, 'Notificaciones',
                        'No tienes notificaciones nuevas en esta demostración.'),
                    icon: const Badge(
                        smallSize: 7,
                        backgroundColor: FestiColors.cyan,
                        child: Icon(Icons.notifications_none_rounded))),
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
                            style:
                                TextStyle(color: Colors.white, fontSize: 12))))
              ]),
              const SizedBox(height: 18),
              ValueListenableBuilder<SquadPreview>(
                  valueListenable: activeSquadPreview,
                  builder: (context, squad, _) =>
                      LayoutBuilder(builder: (context, constraints) {
                        final cards = [
                          FestiCard(
                              glow: true,
                              onTap: () => showFeatureInfo(context, squad.name,
                                  '${squad.members} integrantes en la vista de demostración. La presencia en línea requiere conectar el servicio de squads.'),
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(children: [
                                      Expanded(
                                          child: Text('SQUAD ACTIVO',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: FestiColors.muted))),
                                      Icon(Icons.bolt,
                                          size: 18, color: FestiColors.cyan)
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
                                    const Wrap(spacing: -5, children: [
                                      _Avatar('YL'),
                                      _Avatar('AM'),
                                      _Avatar('JC'),
                                      _Avatar('+2')
                                    ]),
                                  ])),
                          FestiCard(
                              onTap: () => context.push('/finances'),
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(children: [
                                      Expanded(
                                          child: Text('FONDO COMÚN',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: FestiColors.muted))),
                                      Icon(Icons.account_balance_wallet_rounded,
                                          color: FestiColors.cyan, size: 18)
                                    ]),
                                    const SizedBox(height: 26),
                                    const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text.rich(TextSpan(children: [
                                          TextSpan(
                                              text: '\$500',
                                              style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800)),
                                          TextSpan(
                                              text: '.00',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: FestiColors.cyan,
                                                  fontWeight: FontWeight.w700))
                                        ]))),
                                    const SizedBox(height: 8),
                                    const Text('MXN disponible',
                                        style: TextStyle(
                                            color: FestiColors.muted,
                                            fontSize: 12)),
                                    const SizedBox(height: 19),
                                    const Divider(color: FestiColors.border),
                                    const Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                              text: 'Último gasto: ',
                                              style: TextStyle(
                                                  color: FestiColors.muted)),
                                          TextSpan(
                                              text: '-\$120',
                                              style: TextStyle(
                                                  color: FestiColors.cyan))
                                        ]),
                                        style: TextStyle(fontSize: 11)),
                                  ])),
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
                  onTap: () => context.push('/map'),
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
                                  Text('Corona Capital 2026',
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 8),
                                  Text(
                                      'Encuentra a tu squad y tu próximo escenario',
                                      style: TextStyle(
                                          color: FestiColors.cyan,
                                          fontSize: 12)),
                                ])),
                      ]))),
              const SizedBox(height: 18),
              FestiCard(
                  onTap: () => context.push('/clash'),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('SUGERENCIA INTELIGENTE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: .5)),
                              StatusPill('Spotify · Sin conectar',
                                  icon: Icons.graphic_eq)
                            ]),
                        const SizedBox(height: 16),
                        Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: FestiColors.background,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: FestiColors.border)),
                            child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      color: FestiColors.cyan),
                                  SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text('¡Empalme a las 8:00 PM!',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15)),
                                        SizedBox(height: 7),
                                        Text(
                                            'Tu artista favorito coincide con la votación del squad en el Escenario Corona.',
                                            style: TextStyle(
                                                color: FestiColors.muted,
                                                fontSize: 13,
                                                height: 1.4))
                                      ])),
                                ])),
                      ])),
              const SizedBox(height: 18),
              const Center(
                  child: Text('DEMOSTRACIÓN · DATOS DE EJEMPLO',
                      style: TextStyle(
                          color: FestiColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.2))),
            ]))),
        bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF080F1C),
            indicatorColor: const Color(0xFF103952),
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index != 0) {
                context
                    .push(['/dashboard', '/map', '/finances', '/clash'][index]);
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

class _Avatar extends StatelessWidget {
  const _Avatar(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF153D5B),
          border: Border.all(color: FestiColors.cyan)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 9,
              color: FestiColors.cyan,
              fontWeight: FontWeight.bold)));
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
