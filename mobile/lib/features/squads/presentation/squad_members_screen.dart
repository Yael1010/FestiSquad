import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../application/squad_controller.dart';
import '../application/squad_members_controller.dart';
import '../domain/squad.dart';
import 'squad_preview.dart';

class SquadMembersScreen extends ConsumerWidget {
  const SquadMembersScreen({
    super.key,
    required this.squadId,
    required this.name,
    required this.code,
  });

  final String squadId;
  final String name;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(squadMembersControllerProvider(squadId));
    final data = state.valueOrNull;
    final members = data?.value ?? const <SquadMemberProfile>[];
    final current = members.where((member) => member.isCurrentUser).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Actualizar integrantes',
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(squadMembersControllerProvider(squadId).notifier)
                    .load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (current?.isOwner == true)
            IconButton(
              tooltip: 'Eliminar squad',
              onPressed: () => _deleteSquad(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: FestiBody(
        child: RefreshIndicator(
          onRefresh: () =>
              ref
                  .read(squadMembersControllerProvider(squadId).notifier)
                  .load(forceRefresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                '${members.length} integrantes',
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código privado',
                          style: TextStyle(
                            color: FestiColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          code,
                          style: const TextStyle(
                            color: FestiColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) _message(context, 'Código copiado.');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                ],
              ),
              if (data?.fromCache == true) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        color: FestiColors.muted, size: 17),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mostrando integrantes guardados sin conexión.',
                        style: TextStyle(color: FestiColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (state.isLoading && members.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (state.hasError && members.isEmpty)
                _Failure(
                    onRetry: () => ref
                        .read(squadMembersControllerProvider(squadId).notifier)
                        .load())
              else
                for (final member in members) ...[
                  _MemberTile(
                    member: member,
                    current: current,
                    onAction: (action) =>
                        _memberAction(context, ref, member, action),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _memberAction(
    BuildContext context,
    WidgetRef ref,
    SquadMemberProfile member,
    String action,
  ) async {
    final controller =
        ref.read(squadMembersControllerProvider(squadId).notifier);
    final descriptions = {
      'remove': '¿Expulsar a ${member.name} del squad?',
      'leave': '¿Abandonar este squad?',
      'transfer': '¿Transferir la propiedad a ${member.name}?',
    };
    if (descriptions[action] case final description?) {
      if (!await _confirm(context, description)) return;
    }
    try {
      switch (action) {
        case 'promote':
          await controller.updateRole(member.userId, 'admin');
        case 'demote':
          await controller.updateRole(member.userId, 'member');
        case 'remove' || 'leave':
          await controller.removeMember(member.userId);
        case 'transfer':
          await controller.transferOwnership(member.userId);
      }
      if (!context.mounted) return;
      if (action == 'leave') {
        activeSquadPreview.value = const SquadPreview('Sin squad activo', 0);
        context.go('/dashboard');
      } else {
        _message(context, 'Squad actualizado.');
      }
    } on SquadRequestException catch (error) {
      if (context.mounted) _message(context, error.message);
    }
  }

  Future<void> _deleteSquad(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      'Esta acción eliminará el squad, ubicaciones, puntos y gastos asociados.',
    )) {
      return;
    }
    try {
      await ref
          .read(squadMembersControllerProvider(squadId).notifier)
          .deleteSquad();
      activeSquadPreview.value = const SquadPreview('Sin squad activo', 0);
      if (context.mounted) context.go('/dashboard');
    } on SquadRequestException catch (error) {
      if (context.mounted) _message(context, error.message);
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar acción'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.current,
    required this.onAction,
  });

  final SquadMemberProfile member;
  final SquadMemberProfile? current;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final actions = <PopupMenuEntry<String>>[];
    if (current?.isAdmin == true && !member.isOwner && !member.isCurrentUser) {
      actions.add(PopupMenuItem(
        value: member.isAdmin ? 'demote' : 'promote',
        child: Text(
            member.isAdmin ? 'Quitar administración' : 'Hacer administrador'),
      ));
      if (current?.isOwner == true) {
        actions.add(const PopupMenuItem(
          value: 'transfer',
          child: Text('Transferir propiedad'),
        ));
      }
      actions.add(const PopupMenuItem(
        value: 'remove',
        child: Text('Expulsar'),
      ));
    } else if (member.isCurrentUser && !member.isOwner) {
      actions.add(const PopupMenuItem(
        value: 'leave',
        child: Text('Abandonar squad'),
      ));
    }
    return FestiCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _MemberAvatar(member: member),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name}${member.isCurrentUser ? ' · Tú' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(member.isOwner
                        ? 'Propietario'
                        : member.isAdmin
                            ? 'Admin'
                            : 'Miembro'),
                    Text(
                      _presence(member.lastLocationAt),
                      style: const TextStyle(
                        color: FestiColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Acciones de integrante',
              onSelected: onAction,
              itemBuilder: (_) => actions,
            ),
        ],
      ),
    );
  }

  static String _presence(DateTime? value) {
    if (value == null) return 'Sin ubicación compartida';
    final elapsed = DateTime.now().difference(value);
    if (elapsed.inMinutes < 2) return 'Ubicación actualizada ahora';
    if (elapsed.inMinutes < 60) {
      return 'Ubicación hace ${elapsed.inMinutes} min';
    }
    if (elapsed.inHours < 24) return 'Ubicación hace ${elapsed.inHours} h';
    return 'Ubicación hace ${elapsed.inDays} d';
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final SquadMemberProfile member;

  @override
  Widget build(BuildContext context) {
    final initials = member.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFF12365A),
      foregroundImage:
          member.avatarUrl == null ? null : NetworkImage(member.avatarUrl!),
      child:
          Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            const Text('No fue posible cargar los integrantes.'),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}
