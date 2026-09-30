import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/squad_signal.dart';

class SquadSignalScreen extends StatefulWidget {
  const SquadSignalScreen({
    required this.squadName,
    required this.squadCode,
    this.signalDuration = const Duration(seconds: 60),
    super.key,
  });

  final String squadName;
  final String squadCode;
  final Duration signalDuration;

  @override
  State<SquadSignalScreen> createState() => _SquadSignalScreenState();
}

class _SquadSignalScreenState extends State<SquadSignalScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _palettes = [
    (Color(0xFF00E5FF), Color(0xFFFF2D8D)),
    (Color(0xFF58F88B), Color(0xFF246BFD)),
    (Color(0xFFFFD84D), Color(0xFFEF476F)),
    (Color(0xFFFF7043), Color(0xFF26C6DA)),
    (Color(0xFFEAEAEA), Color(0xFF00C853)),
    (Color(0xFF40C4FF), Color(0xFFFFAB40)),
  ];
  static const _symbols = [
    Icons.graphic_eq_rounded,
    Icons.bolt_rounded,
    Icons.music_note_rounded,
    Icons.star_rounded,
    Icons.festival_rounded,
    Icons.radio_rounded,
  ];

  late final SquadSignalIdentity _identity;
  late final AnimationController _pulse;
  late DateTime _deadline;
  Timer? _ticker;
  int _secondsLeft = 60;
  double _intensity = .8;
  bool _active = true;
  bool _haptics = true;
  bool _reduceMotion = false;

  (Color, Color) get _palette => _palettes[_identity.paletteIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _identity = SquadSignalIdentity.fromCode(widget.squadCode);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: .35,
      upperBound: 1,
    );
    _activate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemaining();
      _syncAnimation();
    } else {
      _pulse.stop();
    }
  }

  void _activate() {
    _deadline = DateTime.now().add(widget.signalDuration);
    _secondsLeft = widget.signalDuration.inSeconds.clamp(1, 60);
    _active = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimation());
  }

  void _updateRemaining() {
    if (!mounted || !_active) return;
    final remaining = _deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      setState(() {
        _secondsLeft = 0;
        _active = false;
      });
      _ticker?.cancel();
      _pulse.stop();
      return;
    }
    setState(
      () => _secondsLeft = (remaining.inMilliseconds / 1000).ceil(),
    );
  }

  void _syncAnimation() {
    if (!_active || _reduceMotion) {
      _pulse.stop();
      _pulse.value = _active ? .72 : .35;
      return;
    }
    _pulse.repeat(reverse: true);
  }

  void _setActive(bool value) {
    if (value) {
      setState(_activate);
      if (_haptics) HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _active = false);
    _ticker?.cancel();
    _syncAnimation();
  }

  void _signalTap() {
    if (!_active) {
      _setActive(true);
      return;
    }
    if (_haptics) HapticFeedback.mediumImpact();
    if (!_reduceMotion) {
      _pulse.forward(from: _pulse.lowerBound).then((_) => _syncAnimation());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = _palette.$1;
    final secondary = _palette.$2;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final energy = _active ? _pulse.value * _intensity : .12;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 14, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      Text(
                        _active
                            ? '00:${_secondsLeft.toString().padLeft(2, '0')}'
                            : 'EN PAUSA',
                        style: TextStyle(
                          color: _active ? primary : FestiColors.muted,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    key: const ValueKey('squad-signal-canvas'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _signalTap,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        ColoredBox(
                          color: Color.lerp(
                            Colors.black,
                            primary,
                            .12 + energy * .18,
                          )!,
                        ),
                        CustomPaint(
                          painter: _SignalPatternPainter(
                            identity: _identity,
                            primary: primary,
                            secondary: secondary,
                            energy: energy,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _symbols[_identity.symbolIndex],
                                size: 96,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: primary, blurRadius: 30 * energy),
                                  Shadow(
                                    color: secondary,
                                    blurRadius: 54 * energy,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.squadName.toUpperCase(),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.squadCode.toUpperCase(),
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'LA SQUAD SIEMPRE ENCUENTRA EL CAMINO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF080D15),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: _intensity,
                              min: .35,
                              max: 1,
                              activeColor: primary,
                              onChanged: (value) =>
                                  setState(() => _intensity = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Pulso'),
                              secondary: const Icon(Icons.waves_rounded),
                              value: _active,
                              activeThumbColor: primary,
                              onChanged: _setActive,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Vibración'),
                              secondary: const Icon(Icons.vibration),
                              value: _haptics,
                              activeThumbColor: secondary,
                              onChanged: (value) =>
                                  setState(() => _haptics = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SignalPatternPainter extends CustomPainter {
  const _SignalPatternPainter({
    required this.identity,
    required this.primary,
    required this.secondary,
    required this.energy,
  });

  final SquadSignalIdentity identity;
  final Color primary;
  final Color secondary;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = primary.withValues(alpha: .28 + energy * .35);
    for (var index = 0; index < 4; index++) {
      final radius = size.shortestSide *
          (.18 + index * .12 + energy * .025 * (index.isEven ? 1 : -1));
      canvas.drawCircle(center, radius, ringPaint);
    }

    final beamPaint = Paint()
      ..strokeWidth = 2
      ..color = secondary.withValues(alpha: .2 + energy * .45);
    final count = 8 + identity.patternOffset;
    for (var index = 0; index < count; index++) {
      final angle =
          (math.pi * 2 / count) * index + identity.patternOffset * .07;
      final inner = size.shortestSide * .24;
      final outer = size.longestSide * (.48 + energy * .04);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        beamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalPatternPainter oldDelegate) {
    return oldDelegate.energy != energy ||
        oldDelegate.identity.seed != identity.seed;
  }
}
