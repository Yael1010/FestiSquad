import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../application/squad_controller.dart';
import 'squad_preview.dart';

class JoinSquadScreen extends ConsumerStatefulWidget {
  const JoinSquadScreen({super.key});
  @override
  ConsumerState<JoinSquadScreen> createState() => _JoinSquadScreenState();
}

class _JoinSquadScreenState extends ConsumerState<JoinSquadScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _manual = false;
  bool _joining = false;
  String? _error;
  bool get _valid =>
      RegExp(r'^[A-F0-9]{6}$').hasMatch(_code.text.trim().toUpperCase());
  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      setState(() {
        if (data?.text == null || data!.text!.trim().isEmpty) {
          _error = 'El portapapeles está vacío. Escribe el código.';
        } else {
          _code.text = data.text!.trim().toUpperCase();
          _error = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'No se pudo leer el portapapeles. Escribe el código.');
      }
    }
  }

  Future<void> _join() async {
    if (!_valid) {
      setState(() => _error = 'Ingresa un código hexadecimal de 6 caracteres.');
      return;
    }
    if (_joining) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final squad = await ref
          .read(squadControllerProvider.notifier)
          .join(_code.text.trim());
      activeSquadPreview.value = SquadPreview(
        squad.name,
        squad.memberIds.length,
        id: squad.id,
        code: squad.code,
      );
      if (!mounted) return;
      context.go('/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Te uniste a ${squad.name}.')),
      );
    } on SquadRequestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10283E),
                      border: Border.all(color: FestiColors.border)),
                  child: const Icon(Icons.festival_outlined,
                      color: FestiColors.cyan)),
              const SizedBox(width: 10),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Inicio',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('• SQUADS PRIVADOS',
                        style: TextStyle(
                            color: FestiColors.cyan,
                            fontSize: 9,
                            letterSpacing: .6))
                  ])),
            ]),
            actions: [
              IconButton(
                  tooltip: 'Notificaciones',
                  onPressed: () => showFeatureInfo(context, 'Notificaciones',
                      'No tienes notificaciones nuevas.'),
                  icon: const Icon(Icons.notifications_none)),
              IconButton(
                  tooltip: 'Perfil',
                  onPressed: () => showFeatureInfo(
                      context,
                      'Perfil de demostración',
                      'Yael Flores · Explora las interfaces sin crear una cuenta.'),
                  icon: const Icon(Icons.account_circle,
                      color: FestiColors.cyan)),
              const SizedBox(width: 8)
            ]),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C1B35), Color(0xFF07111F)])),
          child: SafeArea(
              top: false,
              child: FestiBody(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                      children: [
                    Row(children: [
                      TextButton.icon(
                          onPressed: () => context.go('/dashboard'),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Inicio')),
                      const Expanded(
                          child: Text('Unirse a Squad',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800))),
                      const StatusPill('DEMO')
                    ]),
                    const Center(
                        child: Text('CORONA CAPITAL 2026',
                            style: TextStyle(
                                color: FestiColors.cyan,
                                fontSize: 12,
                                letterSpacing: 1))),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: false,
                              icon: Icon(Icons.qr_code_scanner),
                              label: Text('Escanear QR')),
                          ButtonSegment(
                              value: true,
                              icon: Icon(Icons.keyboard),
                              label: Text('Pegar código'))
                        ],
                        selected: {_manual},
                        onSelectionChanged: (value) {
                          setState(() => _manual = value.first);
                          if (value.first) {
                            _focus.requestFocus();
                          } else {
                            _focus.unfocus();
                          }
                        }),
                    const SizedBox(height: 22),
                    if (!_manual) ...[
                      Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF060E1C),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                            color: const Color(0xFF196685)),
                                        boxShadow: [
                                          BoxShadow(
                                              color: FestiColors.cyan
                                                  .withValues(alpha: .13),
                                              blurRadius: 28)
                                        ]),
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(48),
                                              gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white,
                                                    Color(0xFFE2ECF4)
                                                  ]))),
                                      const Center(
                                          child: Icon(Icons.qr_code_2_rounded,
                                              size: 185,
                                              color: Color(0xFF07111F),
                                              semanticLabel:
                                                  'QR ilustrativo, no escaneable')),
                                      Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                  color: FestiColors.cyan
                                                      .withValues(alpha: .65),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                        color: FestiColors.cyan,
                                                        blurRadius: 12)
                                                  ]))),
                                      const Positioned(
                                          bottom: 8,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                              child: StatusPill(
                                                  'VISTA PREVIA · CÁMARA INACTIVA',
                                                  icon:
                                                      Icons.qr_code_scanner))),
                                    ]),
                                  )))),
                      const SizedBox(height: 18),
                      const Text(
                          'Escanea el código de un amigo para encontrar su squad. La cámara se conectará en una iteración posterior.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: FestiColors.muted,
                              fontSize: 14,
                              height: 1.5)),
                    ] else ...[
                      const FestiCard(
                          child: Column(children: [
                        Icon(Icons.tag_rounded,
                            size: 64, color: FestiColors.cyan),
                        SizedBox(height: 12),
                        Text('Tu squad está a un código de distancia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        SizedBox(height: 10),
                        Text(
                            'Pega el código privado de 6 caracteres que compartieron contigo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: FestiColors.muted, height: 1.5))
                      ])),
                    ],
                    const SizedBox(height: 22),
                    const Row(children: [
                      Expanded(child: Divider(color: FestiColors.border)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('O INGRESA EL CÓDIGO',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: FestiColors.muted,
                                  letterSpacing: .8))),
                      Expanded(child: Divider(color: FestiColors.border))
                    ]),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _code,
                        focusNode: _focus,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Fa-f0-9]'))
                        ],
                        style: const TextStyle(
                            letterSpacing: 2, fontWeight: FontWeight.w800),
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _join(),
                        decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.tag, color: FestiColors.cyan),
                            hintText: 'A1B2C3',
                            errorText: _error,
                            errorMaxLines: 3,
                            suffixIcon: TextButton.icon(
                                onPressed: _paste,
                                icon: const Icon(Icons.content_paste, size: 18),
                                label: const Text('Pegar')))),
                    const SizedBox(height: 12),
                    if (_valid)
                      const FestiCard(
                          padding: EdgeInsets.all(14),
                          child: Row(children: [
                            CircleAvatar(
                                backgroundColor: Color(0xFF173654),
                                child: Icon(Icons.groups,
                                    color: FestiColors.cyan)),
                            SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Código listo para verificar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 4),
                                  Text(
                                      'La API confirmará el squad y sus miembros',
                                      style: TextStyle(
                                          color: FestiColors.muted,
                                          fontSize: 11))
                                ])),
                            Icon(Icons.verified_outlined,
                                color: FestiColors.cyan, size: 21)
                          ])),
                    const SizedBox(height: 16),
                    BlueButton(
                        label: _joining ? 'UNIÉNDOME...' : 'UNIRME AL SQUAD',
                        icon: Icons.bolt,
                        onPressed: _joining ? null : _join),
                    const SizedBox(height: 20),
                    const Center(
                        child: Text(
                            'La unión requiere sesión y conexión con FestiSquad',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: FestiColors.muted,
                                fontSize: 11,
                                height: 1.5))),
                  ]))),
        ),
      );
}
