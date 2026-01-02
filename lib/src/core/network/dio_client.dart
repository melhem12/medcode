import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor for debugging
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
          error: true,
          logPrint: (object) {
            debugPrint('🌐 Dio: $object');
          },
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Remove Content-Type header for FormData to let Dio set multipart/form-data automatically
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
            debugPrint('📥 Response: ${response.statusCode} ${response.requestOptions.uri}');
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
          
          // Handle 401 Unauthorized - but don't delete token automatically
          // Tokens don't expire, so 401 means invalid credentials or server issue
          // Only delete token if it's explicitly an authentication error
          if (error.response?.statusCode == 401) {
            // Check if it's a login endpoint - if so, don't delete token
            final isLoginEndpoint = error.requestOptions.uri.path.contains('/auth/login');
            if (!isLoginEndpoint) {
              // For non-login endpoints, token might be invalid - but we'll keep it
              // and let the app handle the error (user can logout manually)
              if (kDebugMode) {
                debugPrint('⚠️ 401 Unauthorized - token may be invalid, but keeping it for user to logout manually');
              }
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
              parsedFieldErrors![key] = value.map((e) => e.toString()).toList();
            } else {
              parsedFieldErrors![key] = [value.toString()];
            }
          });
        }
        
        debugPrint(
          'API error [$status] $method $uri -> $message',
        );
        return ApiException(
          message,
          statusCode: error.response!.statusCode,
          fieldErrors: parsedFieldErrors,
        );
      }
      debugPrint(
        'API error [$status] $method $uri -> Server error: ${error.response!.statusCode}',
      );
      return ApiException(
        'Server error: ${error.response!.statusCode}',
        statusCode: error.response!.statusCode,
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      debugPrint('Network timeout $method $uri');
      return NetworkException('Connection timeout. Please check your internet connection.');
    } else if (error.type == DioExceptionType.connectionError) {
      debugPrint('Network connection error $method $uri -> ${error.message}');
      return NetworkException('No internet connection. Please check your network settings.');
    }
    debugPrint('Unexpected error $method $uri -> ${error.message}');
    return NetworkException(error.message ?? 'An unexpected error occurred');
  }

  Dio get dio => _dio;
}




