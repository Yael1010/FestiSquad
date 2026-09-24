import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/security/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/festi_widgets.dart';
import '../../squads/application/squad_controller.dart';
import '../../squads/domain/squad.dart';
import '../../squads/presentation/squad_preview.dart';
import '../application/finance_controller.dart';
import '../domain/finance_models.dart';
import '../domain/money.dart';

class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({super.key});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen> {
  String? get _squadId => activeSquadPreview.value.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final squadId = _squadId;
    if (squadId != null) {
      await ref.read(financeControllerProvider.notifier).load(squadId);
    }
  }

  Future<void> _newExpense() async {
    final squad = ref.read(squadControllerProvider).valueOrNull;
    final session = await ref.read(tokenStorageProvider).readSession();
    if (!mounted) return;
    if (squad == null || session == null) {
      _show('Selecciona o crea un squad antes de registrar gastos.');
      return;
    }
    final draft = await showModalBottomSheet<ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ExpenseForm(
        squad: squad,
        currentUserId: session.userId,
      ),
    );
    if (draft == null || !mounted) return;
    try {
      await ref.read(financeControllerProvider.notifier).create(draft);
      if (!mounted) return;
      final snapshot = ref.read(financeControllerProvider).valueOrNull;
      _show(
        snapshot?.fromCache == true
            ? 'Ticket guardado. Se sincronizará cuando vuelva la conexión.'
            : 'Ticket registrado correctamente.',
      );
    } on FinanceRequestException catch (error) {
      _show(error.message);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final finances = ref.watch(financeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Fondo común'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: finances.isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FestiBody(
          child: finances.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                _ErrorView(message: error.toString(), retry: _load),
            data: (snapshot) {
              if (_squadId == null) return const _NoSquadView();
              final value = snapshot ??
                  const FinanceSnapshot(
                    expenses: [],
                    netBalances: {},
                    transfers: [],
                    fromCache: false,
                  );
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                  children: [
                    if (value.fromCache)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: StatusPill(
                          'DATOS GUARDADOS · SINCRONIZANDO',
                          icon: Icons.cloud_off_outlined,
                        ),
                      ),
                    _BalanceSummary(snapshot: value),
                    const SizedBox(height: 20),
                    Text('DEUDAS SIMPLIFICADAS',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 10),
                    _TransfersList(transfers: value.transfers),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text('TICKETS',
                              style: Theme.of(context).textTheme.labelLarge),
                        ),
                        Text('${value.expenses.length}',
                            style: const TextStyle(color: FestiColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ExpenseList(expenses: value.expenses),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _squadId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: finances.isLoading ? null : _newExpense,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo ticket'),
            ),
    );
  }
}

class _BalanceSummary extends ConsumerWidget {
  const _BalanceSummary({required this.snapshot});

  final FinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<StoredSession?>(
      future: ref.read(tokenStorageProvider).readSession(),
      builder: (context, session) {
        final mine = snapshot.netBalances[session.data?.userId] ?? Money.zero;
        final positive = mine.cents >= 0;
        return FestiCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TU BALANCE',
                  style: TextStyle(color: FestiColors.muted, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                mine.format(),
                style: TextStyle(
                  color: positive ? FestiColors.cyan : const Color(0xFFFF8D8D),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mine.cents == 0
                    ? 'Estás al corriente con el squad.'
                    : positive
                        ? 'El squad debe pagarte este importe.'
                        : 'Este es tu saldo pendiente por pagar.',
                style: const TextStyle(color: FestiColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransfersList extends StatelessWidget {
  const _TransfersList({required this.transfers});

  final List<DebtTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Text('No hay pagos pendientes.',
          style: TextStyle(color: FestiColors.muted));
    }
    return Column(
      children: [
        for (final transfer in transfers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const CircleAvatar(child: Icon(Icons.swap_horiz, size: 18)),
            title: Text(
              '${_memberLabel(transfer.fromUserId)} paga a '
              '${_memberLabel(transfer.toUserId)}',
            ),
            trailing: Text(
              transfer.amount.format(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  final List<SquadExpense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 42, color: FestiColors.muted),
            SizedBox(height: 12),
            Text('Todavía no hay tickets compartidos.',
                style: TextStyle(color: FestiColors.muted)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final expense in expenses)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const CircleAvatar(child: Icon(Icons.receipt_long, size: 18)),
            title: Text(expense.description),
            subtitle: Text(
              '${_memberLabel(expense.paidByUserId)} · '
              '${expense.participants.length} participantes',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(expense.amount.format(),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                if (expense.pendingSync)
                  const Text('PENDIENTE',
                      style: TextStyle(color: FestiColors.cyan, fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({required this.squad, required this.currentUserId});

  final Squad squad;
  final String currentUserId;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  late String _payer;
  late Set<String> _participants;

  @override
  void initState() {
    super.initState();
    _payer = widget.currentUserId;
    _participants = widget.squad.memberIds.toSet();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un participante.')),
      );
      return;
    }
    try {
      final amount = Money.parse(_amount.text, allowNegative: false);
      final shares = splitEqually(amount, _participants);
      Navigator.pop(
        context,
        ExpenseDraft(
          clientRequestId: const Uuid().v4(),
          squadId: widget.squad.id,
          paidByUserId: _payer,
          description: _description.text.trim(),
          amount: amount,
          participants: shares.entries
              .map((entry) => ExpenseShare(
                    userId: entry.key,
                    amount: entry.value,
                  ))
              .toList(growable: false),
        ),
      );
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo ticket',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextFormField(
              controller: _description,
              maxLength: 180,
              decoration: const InputDecoration(labelText: 'Concepto'),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Escribe al menos dos caracteres.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total en MXN',
                prefixText: r'$ ',
              ),
              validator: (value) {
                try {
                  Money.parse(value ?? '', allowNegative: false);
                  return null;
                } on FormatException catch (error) {
                  return error.message;
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _payer,
              decoration: const InputDecoration(labelText: 'Pagó'),
              items: [
                for (final member in widget.squad.memberIds)
                  DropdownMenuItem(
                    value: member,
                    child: Text(member == widget.currentUserId
                        ? 'Yo'
                        : _memberLabel(member)),
                  ),
              ],
              onChanged: (value) => setState(() => _payer = value ?? _payer),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Text('Dividir entre')),
                TextButton(
                  onPressed: () => setState(
                    () => _participants = widget.squad.memberIds.toSet(),
                  ),
                  child: const Text('Todos'),
                ),
              ],
            ),
            for (final member in widget.squad.memberIds)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _participants.contains(member),
                title: Text(member == widget.currentUserId
                    ? 'Yo'
                    : _memberLabel(member)),
                onChanged: (selected) => setState(() {
                  if (selected ?? false) {
                    _participants.add(member);
                  } else {
                    _participants.remove(member);
                  }
                }),
              ),
            const SizedBox(height: 14),
            BlueButton(
              label: 'GUARDAR Y DIVIDIR',
              icon: Icons.receipt_long,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSquadView extends StatelessWidget {
  const _NoSquadView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Crea o selecciona un squad para administrar el fondo común.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FestiColors.muted),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

String _memberLabel(String id) {
  final compact = id.replaceAll('-', '');
  final end = compact.length < 6 ? compact.length : 6;
  return 'Miembro ${compact.substring(0, end)}';
}
