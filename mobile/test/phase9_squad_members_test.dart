import 'package:festisquad/core/offline/offline_state.dart';
import 'package:festisquad/features/squads/data/squad_repository.dart';
import 'package:festisquad/features/squads/domain/squad.dart';
import 'package:festisquad/features/squads/presentation/squad_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('member list fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          squadRepositoryProvider.overrideWithValue(_MembersRepository()),
        ],
        child: const MaterialApp(
          home: SquadMembersScreen(
            squadId: 'squad-1',
            name: 'Festival Squad',
            code: 'ABC123',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 integrantes'), findsOneWidget);
    expect(find.textContaining('Yael'), findsOneWidget);
    expect(find.text('Propietario'), findsOneWidget);
    expect(find.byTooltip('Acciones de integrante'), findsOneWidget);
    final layoutError = tester.takeException();
    expect(layoutError, isNull);
  });
}

class _MembersRepository implements SquadRepository {
  @override
  Future<OfflineData<List<SquadMemberProfile>>> loadMembers(
    String squadId,
  ) async {
    return OfflineData(
      [
        SquadMemberProfile(
          userId: 'user-1',
          name: 'Yael Flores',
          role: 'admin',
          joinedAt: DateTime.utc(2026, 9, 1),
          isOwner: true,
          isCurrentUser: true,
        ),
        SquadMemberProfile(
          userId: 'user-2',
          name: 'Mariana Hernández con nombre largo',
          role: 'member',
          joinedAt: DateTime.utc(2026, 9, 2),
          isOwner: false,
          isCurrentUser: false,
        ),
      ],
      fromCache: false,
    );
  }

  @override
  Future<void> deleteSquad(String squadId) async {}

  @override
  Future<void> removeMember(String squadId, String userId) async {}

  @override
  Future<void> transferOwnership(String squadId, String userId) async {}

  @override
  Future<void> updateRole(String squadId, String userId, String role) async {}

  @override
  Future<Squad> create(String name) => throw UnimplementedError();

  @override
  Future<Squad> join(String code) => throw UnimplementedError();

  @override
  Future<OfflineData<List<Squad>>> loadMine() => throw UnimplementedError();
}
