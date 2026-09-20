import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/map_providers.dart';
import '../../domain/map_models.dart';
import 'nearby_people.dart';
import 'totem_summary.dart';

class TotemSheet extends ConsumerWidget {
  const TotemSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totem = ref.watch(selectedTotemProvider);
    if (totem == null) return const SizedBox.shrink();

    return _SelectedTotemSheet(
      key: ValueKey(totem.id),
      totem: totem,
      onClose: () => ref.read(selectedTotemIdProvider.notifier).clear(),
    );
  }
}

class _SelectedTotemSheet extends StatefulWidget {
  const _SelectedTotemSheet({
    super.key,
    required this.totem,
    required this.onClose,
  });

  final Totem totem;
  final VoidCallback onClose;

  @override
  State<_SelectedTotemSheet> createState() => _SelectedTotemSheetState();
}

class _SelectedTotemSheetState extends State<_SelectedTotemSheet> {
  static const _maxSize = .86;

  final _controller = DraggableScrollableController();
  bool _expanded = false;
  double _minSize = .28;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onExtentChanged);
  }

  void _onExtentChanged() {
    if (!_controller.isAttached) return;

    final progress = (_controller.size - _minSize) / (_maxSize - _minSize);
    final nextExpanded = _expanded ? progress > .35 : progress >= .55;

    if (nextExpanded != _expanded) {
      setState(() => _expanded = nextExpanded);
    }
  }

  void _toggle() {
    if (!_controller.isAttached) return;

    final target = _expanded ? _minSize : _maxSize;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }

    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onExtentChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        _minSize = ((180 + 48 * (textScale - 1)) / constraints.maxHeight)
            .clamp(.28, .60)
            .toDouble();

        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: _minSize,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          snap: true,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return Material(
              elevation: 4,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  TotemSummary(
                    totem: widget.totem,
                    onClose: widget.onClose,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _toggle,
                      icon: Icon(
                        _expanded ? Icons.expand_more : Icons.expand_less,
                      ),
                      label: Text(
                        _expanded ? 'Ver menos' : 'Ver personas cercanas',
                      ),
                    ),
                  ),
                  if (_expanded) ...[
                    Text(widget.totem.location),
                    const SizedBox(height: 20),
                    NearbyPeople(totemId: widget.totem.id),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
