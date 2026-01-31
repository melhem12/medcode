import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken; // In-memory token cache to avoid race conditions

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
    
    // Initialize token cache from storage (async, but won't block)
    _initializeTokenCache();

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
          // Don't add Authorization header for login/register endpoints
          final isAuthEndpoint = options.uri.path.contains('/auth/login') || 
                                  options.uri.path.contains('/auth/register');
          
          if (!isAuthEndpoint) {
            // Use cached token first, then fallback to storage
            String? token = _cachedToken;
            if (token == null) {
              token = await _storage.read(key: 'auth_token');
              _cachedToken = token; // Cache it for next time
            }
            if (token != null) {
              // Send in standard Authorization header
              options.headers['Authorization'] = 'Bearer $token';
              // Also send in custom header as fallback (Apache sometimes strips Authorization)
              options.headers['X-Auth-Token'] = token;
              if (kDebugMode) {
                debugPrint('🔑 Using token from: ${_cachedToken == token ? "memory cache" : "storage"}');
              }
            } else {
              if (kDebugMode) {
                debugPrint('⚠️ No token available for request to ${options.uri.path}');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint('🔓 Skipping Authorization header for auth endpoint: ${options.uri.path}');
            }
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
          
          // Handle 401 Unauthorized - clear token if it's invalid
          if (error.response?.statusCode == 401) {
            // Check if it's an auth endpoint (login/register) - if so, don't clear token
            final isAuthEndpoint = error.requestOptions.uri.path.contains('/auth/login') || 
                                   error.requestOptions.uri.path.contains('/auth/register');
            if (!isAuthEndpoint) {
              // For protected endpoints, 401 means token is invalid - clear it
              if (kDebugMode) {
                debugPrint('⚠️ 401 Unauthorized - clearing invalid token');
              }
              // Clear token from memory and storage
              _cachedToken = null;
              await _storage.delete(key: 'auth_token');
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

  /// Set the authentication token in memory and storage
  /// This should be called immediately after login to avoid race conditions
  Future<void> setAuthToken(String token) async {
    // Set in memory first (synchronously) to ensure immediate availability
    _cachedToken = token;
    if (kDebugMode) {
      debugPrint('🔑 Token cached in memory: ${token.substring(0, 20)}...');
    }
    // Then persist to storage (asynchronously)
    await _storage.write(key: 'auth_token', value: token);
    if (kDebugMode) {
      debugPrint('🔑 Token saved to storage');
    }
  }

  /// Clear the authentication token from memory and storage
  Future<void> clearAuthToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'auth_token');
  }

  /// Get the current authentication token
  Future<String?> getAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }
    _cachedToken = await _storage.read(key: 'auth_token');
    return _cachedToken;
  }

  /// Initialize token cache from storage
  Future<void> _initializeTokenCache() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _cachedToken = token;
        if (kDebugMode) {
          debugPrint('🔑 Token loaded from storage on initialization');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error loading token from storage: $e');
      }
    }
  }

  Dio get dio => _dio;
}



