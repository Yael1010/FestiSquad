import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import '../domain/finance_models.dart';
import '../domain/money.dart';

final financeRemoteDataSourceProvider =
    Provider<FinanceRemoteDataSource>((ref) {
  return ApiFinanceRemoteDataSource(ref.watch(apiClientProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(
    ref.watch(financeRemoteDataSourceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract interface class FinanceRemoteDataSource {
  Future<List<SquadExpense>> expenses(String squadId);
  Future<({Map<String, Money> balances, List<DebtTransfer> transfers})>
      balances(
    String squadId,
  );
  Future<SquadExpense> create(ExpenseDraft draft);
}

class ApiFinanceRemoteDataSource implements FinanceRemoteDataSource {
  ApiFinanceRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<SquadExpense>> expenses(String squadId) async {
    final response = await _api.get('/expenses/squad/$squadId');
    return (response.data as List)
        .map((item) => SquadExpense.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
  }

  @override
  Future<({Map<String, Money> balances, List<DebtTransfer> transfers})>
      balances(
    String squadId,
  ) async {
    final response = await _api.get('/expenses/squad/$squadId/balances');
    final data = Map<String, dynamic>.from(response.data as Map);
    final balances = Map<String, dynamic>.from(data['net_balances'] as Map).map(
      (userId, amount) => MapEntry(userId, Money.parse(amount.toString())),
    );
    final transfers = (data['suggested_transfers'] as List).map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      return DebtTransfer(
        fromUserId: row['from_user_id'] as String,
        toUserId: row['to_user_id'] as String,
        amount: Money.parse(row['amount'].toString()),
      );
    }).toList(growable: false);
    return (balances: balances, transfers: transfers);
  }

  @override
  Future<SquadExpense> create(ExpenseDraft draft) async {
    final response = await _api.post('/expenses', data: draft.toJson());
    return SquadExpense.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class FinanceRepository {
  FinanceRepository(this._remote, this._database, this._tokens);

  final FinanceRemoteDataSource _remote;
  final AppDatabase _database;
  final TokenStorage _tokens;

  Future<FinanceSnapshot> load(String squadId) async {
    final userId = await _currentUserId();
    await _retryPending(userId);
    final cached = await _readCache(userId, squadId);
    if (cached.expenses.isNotEmpty || cached.netBalances.isNotEmpty) {
      unawaited(_refresh(userId, squadId));
      return cached;
    }
    try {
      return await _refresh(userId, squadId);
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      return cached;
    }
  }

  Future<FinanceSnapshot> create(ExpenseDraft draft) async {
    final userId = await _currentUserId();
    await _cacheExpense(
      userId,
      SquadExpense(
        id: draft.clientRequestId,
        clientRequestId: draft.clientRequestId,
        squadId: draft.squadId,
        paidByUserId: draft.paidByUserId,
        description: draft.description,
        amount: draft.amount,
        participants: draft.participants,
        createdAt: DateTime.now().toUtc(),
        pendingSync: true,
      ),
    );
    await _database.queueExpense(jsonEncode(draft.toJson()));
    await _recalculateLocalSummary(userId, draft.squadId);

    try {
      final saved = await _remote.create(draft);
      await _cacheExpense(userId, saved);
      await _deletePending(draft.clientRequestId);
      try {
        return await _refresh(userId, draft.squadId);
      } on DioException {
        return _readCache(userId, draft.squadId);
      }
    } on DioException catch (error) {
      if (_isNetworkFailure(error)) {
        return _readCache(userId, draft.squadId);
      }
      await _database.deleteExpense(userId, draft.clientRequestId);
      await _deletePending(draft.clientRequestId);
      await _recalculateLocalSummary(userId, draft.squadId);
      rethrow;
    }
  }

  Future<FinanceSnapshot> _refresh(String userId, String squadId) async {
    final responses = await Future.wait([
      _remote.expenses(squadId),
      _remote.balances(squadId),
    ]);
    final expenses = responses[0] as List<SquadExpense>;
    final summary = responses[1] as ({
      Map<String, Money> balances,
      List<DebtTransfer> transfers
    });
    await _database.replaceSyncedExpenses(
      userId,
      squadId,
      expenses.map((expense) => _toCache(userId, expense)),
    );
    await _cacheSummary(userId, squadId, summary.balances, summary.transfers);
    return FinanceSnapshot(
      expenses: await _readExpenses(userId, squadId),
      netBalances: summary.balances,
      transfers: summary.transfers,
      fromCache: false,
    );
  }

  Future<FinanceSnapshot> _readCache(String userId, String squadId) async {
    final expenses = await _readExpenses(userId, squadId);
    final balances = {
      for (final row in await _database.readBalances(userId, squadId))
        row.userId: Money.fromCents(row.balanceCents),
    };
    final transfers = (await _database.readDebtTransfers(userId, squadId))
        .map((row) => DebtTransfer(
              fromUserId: row.fromUserId,
              toUserId: row.toUserId,
              amount: Money.fromCents(row.amountCents),
            ))
        .toList(growable: false);
    return FinanceSnapshot(
      expenses: expenses,
      netBalances: balances,
      transfers: transfers,
      fromCache: true,
    );
  }

  Future<List<SquadExpense>> _readExpenses(
    String userId,
    String squadId,
  ) async {
    return (await _database.readExpenses(userId, squadId))
        .map((row) => SquadExpense(
              id: row.serverId ?? row.clientRequestId,
              clientRequestId: row.clientRequestId,
              squadId: row.squadId,
              paidByUserId: row.paidByUserId,
              description: row.description,
              amount: Money.fromCents(row.amountCents),
              participants:
                  (jsonDecode(row.participantsJson) as List).map((item) {
                final value = Map<String, dynamic>.from(item as Map);
                return ExpenseShare(
                  userId: value['user_id'] as String,
                  amount: Money.fromCents(value['share_cents'] as int),
                );
              }).toList(growable: false),
              createdAt: row.createdAt,
              pendingSync: row.syncState != 'synced',
            ))
        .toList(growable: false);
  }

  Future<void> _cacheExpense(String userId, SquadExpense expense) {
    return _database.upsertExpense(_toCache(userId, expense));
  }

  CachedExpensesCompanion _toCache(String userId, SquadExpense expense) {
    return CachedExpensesCompanion.insert(
      sessionUserId: userId,
      clientRequestId: expense.clientRequestId,
      serverId: Value(expense.pendingSync ? null : expense.id),
      squadId: expense.squadId,
      paidByUserId: expense.paidByUserId,
      description: expense.description,
      amountCents: expense.amount.cents,
      participantsJson: jsonEncode([
        for (final participant in expense.participants)
          {
            'user_id': participant.userId,
            'share_cents': participant.amount.cents,
          },
      ]),
      createdAt: expense.createdAt.toUtc(),
      syncState: expense.pendingSync ? 'pending' : 'synced',
    );
  }

  Future<void> _cacheSummary(
    String userId,
    String squadId,
    Map<String, Money> balances,
    List<DebtTransfer> transfers,
  ) {
    return _database.replaceFinanceSummary(
      userId,
      squadId,
      balances.entries.map((entry) => CachedBalancesCompanion.insert(
            sessionUserId: userId,
            squadId: squadId,
            userId: entry.key,
            balanceCents: entry.value.cents,
          )),
      transfers.indexed.map((entry) => CachedDebtTransfersCompanion.insert(
            sessionUserId: userId,
            squadId: squadId,
            position: entry.$1,
            fromUserId: entry.$2.fromUserId,
            toUserId: entry.$2.toUserId,
            amountCents: entry.$2.amount.cents,
          )),
    );
  }

  Future<void> _recalculateLocalSummary(String userId, String squadId) async {
    final expenses = await _readExpenses(userId, squadId);
    final balances = <String, Money>{};
    for (final expense in expenses) {
      balances.update(
        expense.paidByUserId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      for (final participant in expense.participants) {
        balances.update(
          participant.userId,
          (value) => value - participant.amount,
          ifAbsent: () => Money.fromCents(-participant.amount.cents),
        );
      }
    }
    balances.removeWhere((_, amount) => amount == Money.zero);
    await _cacheSummary(userId, squadId, balances, _simplify(balances));
  }

  List<DebtTransfer> _simplify(Map<String, Money> balances) {
    final debtors = balances.entries
        .where((entry) => entry.value.cents < 0)
        .map((entry) => [entry.key, -entry.value.cents])
        .toList()
      ..sort((a, b) {
        final amount = (b[1] as int).compareTo(a[1] as int);
        return amount != 0
            ? amount
            : (a[0] as String).compareTo(b[0] as String);
      });
    final creditors = balances.entries
        .where((entry) => entry.value.cents > 0)
        .map((entry) => [entry.key, entry.value.cents])
        .toList()
      ..sort((a, b) {
        final amount = (b[1] as int).compareTo(a[1] as int);
        return amount != 0
            ? amount
            : (a[0] as String).compareTo(b[0] as String);
      });
    final transfers = <DebtTransfer>[];
    var debtor = 0;
    var creditor = 0;
    while (debtor < debtors.length && creditor < creditors.length) {
      final debt = debtors[debtor][1] as int;
      final credit = creditors[creditor][1] as int;
      final cents = debt < credit ? debt : credit;
      transfers.add(DebtTransfer(
        fromUserId: debtors[debtor][0] as String,
        toUserId: creditors[creditor][0] as String,
        amount: Money.fromCents(cents),
      ));
      debtors[debtor][1] = debt - cents;
      creditors[creditor][1] = credit - cents;
      if (debt == cents) debtor++;
      if (credit == cents) creditor++;
    }
    return transfers;
  }

  Future<void> _retryPending(String userId) async {
    for (final operation in await _database.readPendingExpenses()) {
      final data = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      final draft = ExpenseDraft(
        clientRequestId: data['client_request_id'] as String,
        squadId: data['squad_id'] as String,
        paidByUserId: data['paid_by_user_id'] as String,
        description: data['description'] as String,
        amount: Money.parse(data['amount'] as String, allowNegative: false),
        participants: (data['participants'] as List)
            .map((item) => ExpenseShare.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(growable: false),
      );
      try {
        await _cacheExpense(userId, await _remote.create(draft));
        await _database.deletePendingOperation(operation.id);
      } on DioException {
        return;
      }
    }
  }

  Future<void> _deletePending(String clientRequestId) async {
    for (final operation in await _database.readPendingExpenses()) {
      final data = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      if (data['client_request_id'] == clientRequestId) {
        await _database.deletePendingOperation(operation.id);
      }
    }
  }

  Future<String> _currentUserId() async {
    final session = await _tokens.readSession();
    if (session == null) throw StateError('No hay una sesión activa.');
    return session.userId;
  }

  bool _isNetworkFailure(DioException error) {
    return error.response == null || (error.response!.statusCode ?? 0) >= 500;
  }
}
