import 'package:dio/dio.dart';
import '../../domain/entities/auth_response.dart';
import '../models/auth_response_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(Map<String, dynamic> payload);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      print('Login response: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return AuthResponseModel.fromJson(data);
      } else {
        throw ApiException(data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      print('Login DioException: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}');
      
      // Handle different types of DioExceptions
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? 'Login failed';
          final statusCode = e.response!.statusCode;
          throw ApiException(message, statusCode: statusCode);
        }
      }
      
      // Network or other errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Network error: ${e.message}');
      }
      
      throw ApiException('Login failed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> register(Map<String, dynamic> payload) async {
    try {
      print('Register payload: $payload');
      final response = await dioClient.dio.post(
        '/auth/register',
        data: payload,
      );
      print('Register response: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'success') {
        return AuthResponseModel.fromJson(data);
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        throw ValidationException(
          data['message'] ?? 'Registration failed',
          errors?.map((k, v) {
            // Handle both List and single string values
            if (v is List) {
              return MapEntry(k, v.map((e) => e.toString()).toList());
            } else {
              return MapEntry(k, [v.toString()]);
            }
          }) ?? {},
        );
      }
    } on DioException catch (e) {
      print('Register DioException: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}');
      
      // Handle validation errors (422)
      if (e.response != null && e.response!.statusCode == 422) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          final errors = responseData['errors'] as Map<String, dynamic>?;
          throw ValidationException(
            responseData['message'] ?? 'Validation failed',
            errors?.map((k, v) {
              if (v is List) {
                return MapEntry(k, v.map((e) => e.toString()).toList());
              } else {
                return MapEntry(k, [v.toString()]);
              }
            }) ?? {},
          );
        }
      }
      
      // Handle other API errors
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? 'Registration failed';
          final statusCode = e.response!.statusCode;
          throw ApiException(message, statusCode: statusCode);
        }
      }
      
      // Network or other errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Network error: ${e.message}');
      }
      
      throw ApiException('Registration failed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is ValidationException) {
        rethrow;
      }
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }
}

