import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../application/auth_controller.dart';
import '../domain/auth_session.dart';

void showSocialAuthSheet(
  BuildContext context,
  String provider, {
  bool link = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    builder: (_) => SocialAuthSheet(provider: provider, link: link),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _account(BuildContext context, bool register) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AccountSheet(register: register));
  }

  void _social(BuildContext context, String provider) {
    showSocialAuthSheet(context, provider);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_festival_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33030A17),
                    Color(0x55102758),
                    Color(0xDD02050B),
                    Color(0xFF02050B),
                  ],
                  stops: [0, .42, .78, 1],
                ),
              ),
            ),
            SafeArea(
              child: FestiBody(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(34, 24, 34, 14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 38)
                            .clamp(0, double.infinity),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 52),
                            const _LoginBrand(),
                            const Spacer(),
                            _LoginActionButton(
                              label: 'CREAR CUENTA',
                              background: const LinearGradient(
                                colors: [FestiColors.blue, FestiColors.cyan],
                              ),
                              foreground: Colors.white,
                              onPressed: () => _account(context, true),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Color(0xFF334258)),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'O REGÍSTRATE CON',
                                      style: TextStyle(
                                        color: Color(0xFFB6BDCA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Color(0xFF334258)),
                                  ),
                                ],
                              ),
                            ),
                            _LoginActionButton(
                              label: 'REGISTRARSE CON GOOGLE',
                              background: const LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                              foreground: const Color(0xFF161A22),
                              icon: const _GoogleMark(),
                              onPressed: () => _social(context, 'google'),
                            ),
                            const SizedBox(height: 14),
                            _LoginActionButton(
                              label: 'REGISTRARSE CON SPOTIFY',
                              background: const LinearGradient(
                                colors: [Color(0xFF1ED760), Color(0xFF1ED760)],
                              ),
                              foreground: Colors.black,
                              icon: const _SpotifyMark(),
                              onPressed: () => _social(context, 'spotify'),
                            ),
                            const SizedBox(height: 16),
                            _LoginActionButton(
                              label: 'INICIAR SESIÓN',
                              background: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent
                                ],
                              ),
                              foreground: FestiColors.cyan,
                              borderColor: const Color(0xFF1185B4),
                              onPressed: () => _account(context, false),
                            ),
                            const Spacer(),
                            _LegalNotice(
                              onTerms: () => showFeatureInfo(
                                context,
                                'Términos de servicio',
                                'Los términos de servicio se publicarán antes del lanzamiento oficial.',
                              ),
                              onPrivacy: () => showFeatureInfo(
                                context,
                                'Política de privacidad',
                                'FestiSquad protege las credenciales y utiliza los datos únicamente para prestar sus funciones.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const _FestiLogo(),
          const SizedBox(height: 2),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Festi',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Squad',
                    style: TextStyle(color: Color(0xFF3397EE)),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 43,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xB30A304A),
              border: Border.all(color: const Color(0xFF145F7E)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'CONNECT · COORDINATE · CELEBRATE',
                style: TextStyle(
                  color: Color(0xFF63DCF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ),
        ],
      );
}

class _LoginActionButton extends StatelessWidget {
  const _LoginActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
    this.borderColor,
  });

  final String label;
  final Gradient background;
  final Color foreground;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.circular(30),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                height: 58,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _SpotifyMark extends StatelessWidget {
  const _SpotifyMark();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
        radius: 12,
        backgroundColor: Colors.black,
        child: Icon(Icons.graphic_eq, size: 17, color: Color(0xFF1ED760)),
      );
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Al continuar, aceptas nuestros '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child:
                    _LegalLink(label: 'Términos de servicio', onTap: onTerms),
              ),
              const TextSpan(text: ' y '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _LegalLink(
                  label: 'Política de privacidad',
                  onTap: onPrivacy,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB6BDCA),
            fontSize: 11,
            height: 1.45,
          ),
        ),
      );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFE5E7EB),
            ),
          ),
        ),
      );
}

class SocialAuthSheet extends ConsumerStatefulWidget {
  const SocialAuthSheet({
    required this.provider,
    this.link = false,
    super.key,
  });

  final String provider;
  final bool link;

  @override
  ConsumerState<SocialAuthSheet> createState() => _SocialAuthSheetState();
}

class _SocialAuthSheetState extends ConsumerState<SocialAuthSheet>
    with WidgetsBindingObserver {
  SocialAuthAttempt? _attempt;
  bool _starting = true;
  bool _checking = false;
  String? _message;

  String get _providerName =>
      widget.provider == 'google' ? 'Google' : 'Spotify';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_start);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _attempt != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        () => mounted ? _check(silent: true) : null,
      );
    }
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _message = null;
    });
    try {
      final attempt = await ref
          .read(authControllerProvider.notifier)
          .startSocial(widget.provider, link: widget.link);
      if (!mounted) return;
      setState(() => _attempt = attempt);
      final opened = await launchUrl(
        Uri.parse(attempt.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _message = 'No se pudo abrir $_providerName.');
      }
    } on AuthRequestException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No se pudo abrir $_providerName.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _check({bool silent = false}) async {
    final attempt = _attempt;
    if (attempt == null || _checking) return;
    setState(() {
      _checking = true;
      if (!silent) _message = null;
    });
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .finishSocial(attempt.flowToken);
      if (!mounted) return;
      switch (result.status) {
        case SocialAuthStatus.completed:
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        case SocialAuthStatus.pending:
          if (!silent) {
            setState(() => _message =
                'La autorización sigue pendiente. Termínala en $_providerName.');
          }
        case SocialAuthStatus.failed:
          setState(() => _message = _socialError(result.error));
      }
    } on AuthRequestException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _socialError(String? code) {
    return switch (code) {
      'authorization_denied' => 'La autorización fue cancelada.',
      'email_requires_account_link' =>
        'Ese correo ya tiene una cuenta. Inicia sesión con contraseña para vincularla.',
      'provider_profile_incomplete' =>
        '$_providerName no compartió un correo electrónico.',
      'flow_expired' => 'El intento expiró. Inicia uno nuevo.',
      _ => 'No fue posible completar el acceso con $_providerName.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.link
                      ? 'Vincular $_providerName'
                      : 'Acceso con $_providerName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (widget.link) ...[
            const SizedBox(height: 4),
            const Text(
              'Vincula este proveedor con tu cuenta actual.',
              style: TextStyle(color: FestiColors.cyan),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _starting
                ? 'Preparando la conexión segura...'
                : 'Completa la autorización en $_providerName y vuelve a FestiSquad.',
            style: const TextStyle(color: FestiColors.muted),
          ),
          if (_starting || _checking) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 18),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _attempt == null || _checking ? null : () => _check(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('YA AUTORICÉ'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _starting ? null : _start,
            icon: const Icon(Icons.open_in_new),
            label: Text('ABRIR $_providerName DE NUEVO'),
          ),
        ],
      ),
    );
  }
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
