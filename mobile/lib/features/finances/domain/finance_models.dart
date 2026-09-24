import 'money.dart';

class ExpenseShare {
  const ExpenseShare({required this.userId, required this.amount});

  final String userId;
  final Money amount;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'share_amount': amount.toDecimalString(),
      };

  factory ExpenseShare.fromJson(Map<String, dynamic> json) => ExpenseShare(
        userId: json['user_id'] as String,
        amount: Money.parse(json['share_amount'].toString()),
      );
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.clientRequestId,
    required this.squadId,
    required this.paidByUserId,
    required this.description,
    required this.amount,
    required this.participants,
  });

  final String clientRequestId;
  final String squadId;
  final String paidByUserId;
  final String description;
  final Money amount;
  final List<ExpenseShare> participants;

  Map<String, dynamic> toJson() => {
        'client_request_id': clientRequestId,
        'squad_id': squadId,
        'paid_by_user_id': paidByUserId,
        'description': description,
        'amount': amount.toDecimalString(),
        'participants': participants.map((item) => item.toJson()).toList(),
      };
}

class SquadExpense {
  const SquadExpense({
    required this.id,
    required this.clientRequestId,
    required this.squadId,
    required this.paidByUserId,
    required this.description,
    required this.amount,
    required this.participants,
    required this.createdAt,
    required this.pendingSync,
  });

  final String id;
  final String clientRequestId;
  final String squadId;
  final String paidByUserId;
  final String description;
  final Money amount;
  final List<ExpenseShare> participants;
  final DateTime createdAt;
  final bool pendingSync;

  factory SquadExpense.fromJson(Map<String, dynamic> json) => SquadExpense(
        id: json['id'] as String,
        clientRequestId: json['client_request_id'] as String,
        squadId: json['squad_id'] as String,
        paidByUserId: json['paid_by_user_id'] as String,
        description: json['description'] as String,
        amount: Money.parse(json['amount'].toString()),
        participants: (json['participants'] as List)
            .map((item) => ExpenseShare.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(growable: false),
        createdAt: DateTime.parse(json['created_at'] as String),
        pendingSync: false,
      );
}

class DebtTransfer {
  const DebtTransfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  final String fromUserId;
  final String toUserId;
  final Money amount;
}

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.expenses,
    required this.netBalances,
    required this.transfers,
    required this.fromCache,
  });

  final List<SquadExpense> expenses;
  final Map<String, Money> netBalances;
  final List<DebtTransfer> transfers;
  final bool fromCache;
}
