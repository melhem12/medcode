import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
          error: true,
          logPrint: (object) => debugPrint('🌐 Dio: $object'),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');

          // ✅ ONLY CHANGE: build headers dynamically
          final headers = await _buildHeaders(token: token);

          // Merge (keep request-specific headers if any)
          options.headers = {
            ...headers,
            ...options.headers,
          };

          // Let Dio set multipart headers automatically
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          if (kDebugMode) {
            debugPrint('📤 Request: ${options.method} ${options.uri}');
            debugPrint('📤 Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('📤 Body: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '📥 Response: ${response.statusCode} ${response.requestOptions.uri}',
            );
            debugPrint('📥 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint('❌ Error: ${error.type} - ${error.message}');
            debugPrint('❌ URL: ${error.requestOptions.uri}');
            if (error.response != null) {
              debugPrint('❌ Status: ${error.response?.statusCode}');
              debugPrint('❌ Response: ${error.response?.data}');
            }
          }

          if (error.response?.statusCode == 401) {
            final isLoginEndpoint =
                error.requestOptions.uri.path.contains('/auth/login');

            if (!isLoginEndpoint && kDebugMode) {
              debugPrint(
                '⚠️ 401 Unauthorized - token kept, user can logout manually',
              );
            }

            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error: 'Unauthorized',
              ),
            );
          }

          final exception = _handleError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: exception,
            ),
          );
        },
      ),
    );
  }

  // ✅ Dynamic headers (version + platform + bearer)
  Future<Map<String, String>> _buildHeaders({String? token}) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent':
          'Medcode-Mobile/${packageInfo.version} (Flutter; $platform)',
      'X-App-Version': packageInfo.version,
      'X-Platform': platform,
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Exception _handleError(DioException error) {
    final method = error.requestOptions.method;
    final uri = error.requestOptions.uri;
    final status = error.response?.statusCode;

    if (error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'] as String? ?? 'An error occurred';
        final fieldErrors = data['errors'] as Map<String, dynamic>?;

        Map<String, List<String>>? parsedFieldErrors;
        if (fieldErrors != null) {
          parsedFieldErrors = {};
          fieldErrors.forEach((key, value) {
            if (value is List) {
              parsedFieldErrors![key] =
                  value.map((e) => e.toString()).toList();
            } else {
              parsedFieldErrors![key] = [value.toString()];
            }
          });
        }

        debugPrint('API error [$status] $method $uri -> $message');

        return ApiException(
          message,
          statusCode: error.response!.statusCode,
          fieldErrors: parsedFieldErrors,
        );
      }

      return ApiException(
        'Server error: ${error.response!.statusCode}',
        statusCode: error.response!.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        'Connection timeout. Please check your internet connection.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return NetworkException(
        'No internet connection. Please check your network settings.',
      );
    }

    return NetworkException(error.message ?? 'An unexpected error occurred');
  }

  Dio get dio => _dio;
}
