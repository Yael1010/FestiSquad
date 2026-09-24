import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:festisquad/core/database/app_database.dart';
import 'package:festisquad/core/security/token_storage.dart';
import 'package:festisquad/features/finances/data/finance_repository.dart';
import 'package:festisquad/features/finances/domain/finance_models.dart';
import 'package:festisquad/features/finances/domain/money.dart';

const userA = '00000000-0000-0000-0000-000000000001';
const userB = '00000000-0000-0000-0000-000000000002';
const squadId = '00000000-0000-0000-0000-000000000010';
const requestId = '00000000-0000-0000-0000-000000000099';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('money parser never truncates fractions', () {
    expect(Money.parse('100.00').cents, 10000);
    expect(Money.parse('-0.50').cents, -50);
    expect(() => Money.parse('1.001'), throwsFormatException);
    expect(
      () => Money.parse('0.00', allowNegative: false),
      throwsFormatException,
    );
  });

  test('equal split assigns every cent deterministically', () {
    final shares = splitEqually(Money.parse('100.00'), [userB, userA]);
    expect(shares[userA]!.cents, 5000);
    expect(shares[userB]!.cents, 5000);

    final remainder = splitEqually(Money.parse('10.01'), [userB, userA]);
    expect(remainder[userA]!.cents, 501);
    expect(remainder[userB]!.cents, 500);
  });

  test('offline expense is cached, queued and included in balances', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_user_id': userA,
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = _FakeFinanceRemote()..offline = true;
    final repository = FinanceRepository(
      remote,
      database,
      TokenStorage(const FlutterSecureStorage()),
    );
    final draft = ExpenseDraft(
      clientRequestId: requestId,
      squadId: squadId,
      paidByUserId: userA,
      description: 'Taxi',
      amount: Money.parse('100.00'),
      participants: const [
        ExpenseShare(userId: userA, amount: Money.fromCents(5000)),
        ExpenseShare(userId: userB, amount: Money.fromCents(5000)),
      ],
    );

    final result = await repository.create(draft);

    expect(result.fromCache, isTrue);
    expect(result.expenses.single.pendingSync, isTrue);
    expect(result.netBalances[userA]!.cents, 5000);
    expect(result.netBalances[userB]!.cents, -5000);
    expect(result.transfers.single.fromUserId, userB);
    expect(await database.readPendingExpenses(), hasLength(1));
  });
}

class _FakeFinanceRemote implements FinanceRemoteDataSource {
  bool offline = false;

  Never _failure() => throw DioException(
        requestOptions: RequestOptions(path: '/expenses'),
        type: DioExceptionType.connectionError,
      );

  @override
  Future<({Map<String, Money> balances, List<DebtTransfer> transfers})>
      balances(
    String squadId,
  ) async {
    if (offline) _failure();
    return (
      balances: const <String, Money>{},
      transfers: const <DebtTransfer>[],
    );
  }

  @override
  Future<SquadExpense> create(ExpenseDraft draft) async {
    if (offline) _failure();
    return SquadExpense(
      id: '00000000-0000-0000-0000-000000000100',
      clientRequestId: draft.clientRequestId,
      squadId: draft.squadId,
      paidByUserId: draft.paidByUserId,
      description: draft.description,
      amount: draft.amount,
      participants: draft.participants,
      createdAt: DateTime.utc(2026, 9, 23),
      pendingSync: false,
    );
  }

  @override
  Future<List<SquadExpense>> expenses(String squadId) async {
    if (offline) _failure();
    return const [];
  }
}
