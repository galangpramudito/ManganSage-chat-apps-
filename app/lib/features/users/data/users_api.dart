import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user.dart';

/// HTTP wrapper untuk endpoint users (technical-spec.md §2.2).
class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  /// GET /api/users — global contact list (exclude self).
  Future<List<User>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiConstants.users);
    final data = (res.data?['data'] as List?) ?? const [];
    return data
        .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }
}

final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(dioProvider)),
);
