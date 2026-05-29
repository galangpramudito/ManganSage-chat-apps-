import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

/// Dio singleton — base URL dari `ApiConstants` + `AuthInterceptor`.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      // Default validateStatus (hanya 2xx valid) → 4xx/5xx jadi DioException.
      // AuthInterceptor butuh ini agar 401 ter-trigger di onError.
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));

  return dio;
});
