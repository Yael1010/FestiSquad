import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/squad.dart';

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  return ApiSquadRepository(ref.watch(apiClientProvider));
});

abstract interface class SquadRepository {
  Future<List<Squad>> listMine();

  Future<Squad> create(String name);

  Future<Squad> join(String code);
}

class ApiSquadRepository implements SquadRepository {
  ApiSquadRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Squad>> listMine() async {
    final response = await _api.get('/squads');
    return (response.data as List)
        .map((item) => _parse(item))
        .toList(growable: false);
  }

  @override
  Future<Squad> create(String name) async {
    final response = await _api.post('/squads', data: {'name': name});
    return _parse(response.data);
  }

  @override
  Future<Squad> join(String code) async {
    final response = await _api.post(
      '/squads/join',
      data: {'code': code.trim().toUpperCase()},
    );
    return _parse(response.data);
  }

  Squad _parse(dynamic data) {
    return Squad.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
