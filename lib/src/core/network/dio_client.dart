import 'package:dio/dio.dart';
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
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
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timeout. Please check your internet connection.');
    } else if (error.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection. Please check your network settings.');
    }
    return NetworkException(error.message ?? 'An unexpected error occurred');
  }

  Dio get dio => _dio;
}


