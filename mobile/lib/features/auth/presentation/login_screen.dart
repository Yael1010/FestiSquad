import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../application/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _account(BuildContext context, bool register) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AccountSheet(register: register));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment(0, -.45),
                  radius: .95,
                  colors: [
                Color(0xFF0D4965),
                Color(0xFF0D2048),
                FestiColors.background
              ],
                  stops: [
                0,
                .45,
                1
              ])),
          child: SafeArea(
              child: FestiBody(
                  child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 24),
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: (constraints.maxHeight - 48)
                                        .clamp(0, double.infinity)),
                                child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 28),
                                      Column(children: [
                                        const _FestiLogo(),
                                        const SizedBox(height: 10),
                                        const Text.rich(
                                            TextSpan(children: [
                                              TextSpan(
                                                  text: 'Festi',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              TextSpan(
                                                  text: 'Squad',
                                                  style: TextStyle(
                                                      color: FestiColors.cyan))
                                            ]),
                                            style: TextStyle(
                                                fontSize: 46,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -2)),
                                        const SizedBox(height: 24),
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF09304A),
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFF14506B)),
                                                borderRadius:
                                                    BorderRadius.circular(30)),
                                            child: const Text(
                                                'CONNECT · COORDINATE · CELEBRATE',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: FestiColors.cyan,
                                                    fontSize: 11,
                                                    letterSpacing: 1.4,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                      ]),
                                      const SizedBox(height: 64),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            BlueButton(
                                                label: 'CREAR CUENTA',
                                                onPressed: () =>
                                                    _account(context, true)),
                                            const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 24),
                                                child: Row(children: [
                                                  Expanded(
                                                      child: Divider(
                                                          color: FestiColors
                                                              .border)),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16),
                                                      child: Text(
                                                          'O REGÍSTRATE CON',
                                                          style: TextStyle(
                                                              color: FestiColors
                                                                  .muted,
                                                              fontSize: 12,
                                                              letterSpacing:
                                                                  1))),
                                                  Expanded(
                                                      child: Divider(
                                                          color: FestiColors
                                                              .border))
                                                ])),
                                            ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        const Color(0xFF102141),
                                                    minimumSize:
                                                        const Size(0, 56)),
                                                onPressed: () => showFeatureInfo(
                                                    context,
                                                    'Google',
                                                    'El acceso con Google estará disponible cuando se configure OAuth. Puedes explorar la vista de demostración.'),
                                                icon: const Text('G',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            FestiColors.blue)),
                                                label: const Text(
                                                    'REGISTRARSE CON GOOGLE',
                                                    style:
                                                        TextStyle(fontWeight: FontWeight.w800))),
                                            const SizedBox(height: 14),
                                            FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        FestiColors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize:
                                                        const Size(0, 56)),
                                                onPressed: () => showFeatureInfo(
                                                    context,
                                                    'Spotify',
                                                    'La conexión con Spotify requiere configurar OAuth. Todavía no hay una cuenta vinculada.'),
                                                icon: const Icon(
                                                    Icons.graphic_eq),
                                                label: const Text(
                                                    'REGISTRARSE CON SPOTIFY',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800))),
                                            const SizedBox(height: 14),
                                            OutlinedButton(
                                                onPressed: () =>
                                                    _account(context, false),
                                                child: const Text(
                                                    'INICIAR SESIÓN',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: .8))),
                                            TextButton(
                                                onPressed: () =>
                                                    context.go('/dashboard'),
                                                child: const Text(
                                                    'Explorar demostración',
                                                    style: TextStyle(
                                                        color:
                                                            FestiColors.muted,
                                                        fontSize: 12))),
                                          ]),
                                      const SizedBox(height: 28),
                                      Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text(
                                                'Al continuar, aceptas nuestros',
                                                style: TextStyle(
                                                    color: FestiColors.muted,
                                                    fontSize: 12)),
                                            TextButton(
                                                onPressed: () => showFeatureInfo(
                                                    context,
                                                    'Términos de servicio',
                                                    'Los términos de servicio aún no han sido publicados. Esta versión es una demostración de las interfaces.'),
                                                child: const Text(
                                                    'Términos de servicio',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .underline))),
                                            TextButton(
                                                onPressed: () => showFeatureInfo(
                                                    context,
                                                    'Política de privacidad',
                                                    'La política de privacidad aún no ha sido publicada. Los formularios de esta demostración no envían ni almacenan tus datos.'),
                                                child: const Text(
                                                    'Política de privacidad',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .underline))),
                                          ]),
                                    ])),
                          )))),
        ),
      );
}

class _FestiLogo extends StatelessWidget {
  const _FestiLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 110,
      height: 132,
      child: CustomPaint(
          painter: _PinPainter(),
          child: const Align(
              alignment: Alignment(0, -.3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.graphic_eq, color: FestiColors.cyan, size: 24),
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42)
              ]))));
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height - 5)
      ..cubicTo(-35, 42, 12, 4, size.width / 2, 4)
      ..cubicTo(size.width - 12, 4, size.width + 35, 42, size.width / 2,
          size.height - 5)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF030912));
    canvas.drawPath(
        path,
        Paint()
          ..shader = FestiColors.gradient.createShader(Offset.zero & size)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({required this.register});
  final bool register;
  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _submitting = false;
  String? _requestError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _requestError = null;
    });

    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (widget.register) {
        await controller.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await controller.login(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.go('/dashboard');
    } on AuthRequestException catch (error) {
      if (mounted) setState(() => _requestError = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 28, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
        child: Form(
            key: _form,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      widget.register
                          ? 'Tu próximo festival empieza aquí'
                          : 'Bienvenido de vuelta',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                      widget.register
                          ? 'Crea tu cuenta para guardar squads y sincronizar tus datos.'
                          : 'Inicia sesión para recuperar tus squads.',
                      style: const TextStyle(color: FestiColors.muted)),
                  const SizedBox(height: 24),
                  if (widget.register) ...[
                    TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Escribe tu nombre'
                            : null),
                    const SizedBox(height: 14)
                  ],
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Correo electrónico'),
                      validator: (v) => v != null &&
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v.trim())
                          ? null
                          : 'Escribe un correo válido'),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _password,
                      obscureText: _hidden,
                      decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                              tooltip: _hidden
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(_hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined))),
                      validator: (v) => v != null && v.length >= 8
                          ? null
                          : 'Usa al menos 8 caracteres'),
                  const SizedBox(height: 24),
                  if (_requestError != null) ...[
                    Text(_requestError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                  ],
                  BlueButton(
                      label: _submitting
                          ? 'CONECTANDO...'
                          : widget.register
                              ? 'CREAR CUENTA'
                              : 'INICIAR SESIÓN',
                      onPressed: _submitting ? null : _submit),
                ])),
      );
}
