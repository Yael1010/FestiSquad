import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows the app at a representative phone size when it runs on desktop/web.
/// Android and iOS keep the native full-screen layout.
class PhonePreview extends StatelessWidget {
  const PhonePreview({super.key, required this.child});

  static const _screenSize = Size(390, 844);
  static const _framePadding = 10.0;
  static const _outerRadius = 46.0;
  static const _screenRadius = 36.0;

  final Widget child;

  bool get _usesPhysicalPhone =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    if (_usesPhysicalPhone) return child;

    return ColoredBox(
      color: const Color(0xFF02050B),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final frameSize = Size(
              _screenSize.width + (_framePadding * 2),
              _screenSize.height + (_framePadding * 2),
            );
            final scale = math
                .min(
                  (constraints.maxWidth - 24) / frameSize.width,
                  (constraints.maxHeight - 24) / frameSize.height,
                )
                .clamp(0.2, 1.0);

            return Center(
              child: SizedBox(
                width: frameSize.width * scale,
                height: frameSize.height * scale,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: SizedBox.fromSize(
                    size: frameSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF11151C),
                        borderRadius: BorderRadius.circular(_outerRadius),
                        border: Border.all(
                          color: const Color(0xFF303845),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 30,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(_framePadding),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_screenRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  size: _screenSize,
                                  padding: const EdgeInsets.only(
                                    top: 28,
                                    bottom: 14,
                                  ),
                                  viewPadding: const EdgeInsets.only(
                                    top: 28,
                                    bottom: 14,
                                  ),
                                  viewInsets: EdgeInsets.zero,
                                ),
                                child: child,
                              ),
                              const Align(
                                alignment: Alignment.topCenter,
                                child: IgnorePointer(child: _PhoneSpeaker()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhoneSpeaker extends StatelessWidget {
  const _PhoneSpeaker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF05080D),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
    );
  }
}
