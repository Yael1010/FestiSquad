import 'package:flutter/material.dart';
import 'app_theme.dart';

class FestiBody extends StatelessWidget {
  const FestiBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520), child: child));
}

class BlueButton extends StatelessWidget {
  const BlueButton(
      {super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: FestiColors.gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: FestiColors.blue.withValues(alpha: .22),
                  blurRadius: 24,
                  offset: const Offset(0, 6))
            ]),
        child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
              Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, letterSpacing: 1))),
            ])),
      );
}

class FestiCard extends StatelessWidget {
  const FestiCard(
      {super.key,
      required this.child,
      this.onTap,
      this.glow = false,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final VoidCallback? onTap;
  final bool glow;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: glow
                ? [
                    BoxShadow(
                        color: FestiColors.cyan.withValues(alpha: .12),
                        blurRadius: 18)
                  ]
                : null),
        child: Material(
            color: FestiColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color:
                        glow ? const Color(0xFF166381) : FestiColors.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap, child: Padding(padding: padding, child: child))),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.icon = Icons.circle});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFF0A2338),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF14506B))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: FestiColors.cyan),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: FestiColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)))
        ]),
      );
}

void showFeatureInfo(BuildContext context, String title, String message) {
  showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(title: Text(title), content: Text(message), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'))
          ]));
}
