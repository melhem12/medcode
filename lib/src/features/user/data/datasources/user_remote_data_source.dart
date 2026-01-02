import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';

abstract class UserRemoteDataSource {
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> payload);
  Future<String> uploadAvatar(String filePath);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl(this.dioClient);

  @override
  Future<User> getProfile() async {
    try {
      final response = await dioClient.dio.get('/users/me');
      final data = response.data as Map<String, dynamic>;
      
      // Backend returns: {'status': 'success', 'user': {...}}
      // Handle both response formats
      final userData = data['user'] ?? data['data'];
      if (userData == null) {
        throw ApiException('User data is null');
      }
      
      // Handle both Map and direct user object
      if (userData is Map<String, dynamic>) {
        return UserModel.fromJson(userData);
      } else {
        // If data is the user object directly
        return UserModel.fromJson(data);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final responseData = e.response?.data;
      final uri = e.requestOptions.uri;
      final method = e.requestOptions.method;
      final authHeader = e.requestOptions.headers['Authorization'];
      final message = (responseData is Map<String, dynamic> && responseData['message'] is String)
          ? responseData['message'] as String
          : (e.message ?? 'Failed to load profile');
      debugPrint(
        'getProfile failed [$status] $method $uri -> $message | auth: $authHeader | data: $responseData',
      );
      throw e.error is Exception
          ? e.error as Exception
          : ApiException(message, statusCode: status);
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> payload) async {
    try {
      final response = await dioClient.dio.put('/users/me', data: payload);
      final data = response.data as Map<String, dynamic>;
      
      // Backend returns: {'status': 'success', 'user': {...}}
      // Handle both response formats
      final userData = data['user'] ?? data['data'];
      if (userData == null) {
        throw ApiException('User data is null');
      }
      
      // Handle both Map and direct user object
      if (userData is Map<String, dynamic>) {
        return UserModel.fromJson(userData);
      } else {
        // If data is the user object directly
        return UserModel.fromJson(data);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final responseData = e.response?.data;
      final uri = e.requestOptions.uri;
      final method = e.requestOptions.method;
      final authHeader = e.requestOptions.headers['Authorization'];
      final message = (responseData is Map<String, dynamic> && responseData['message'] is String)
          ? responseData['message'] as String
          : (e.message ?? 'Failed to update profile');
      debugPrint(
        'updateProfile failed [$status] $method $uri -> $message | auth: $authHeader | data: $responseData',
      );
      throw e.error is Exception
          ? e.error as Exception
          : ApiException(message, statusCode: status);
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await dioClient.dio.post('/users/me/avatar', data: formData);
      final data = response.data as Map<String, dynamic>;
      
      // Handle different response formats
      // Backend returns: {'status': 'success', 'user': {'avatar_url': '...'}} or {'status': 'success', 'avatar_url': '...'}
      final avatarUrl = data['avatar_url'] ?? 
                       data['user']?['avatar_url'] ?? 
                       data['data']?['avatar_url'];
      if (avatarUrl == null || avatarUrl is! String) {
        debugPrint('Avatar upload response: $data');
        throw ApiException('Invalid avatar URL in response: $data');
      }
      
      return avatarUrl;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final responseData = e.response?.data;
      final message = (responseData is Map<String, dynamic> && responseData['message'] is String)
          ? responseData['message'] as String
          : (e.message ?? 'Failed to upload avatar');
      debugPrint(
        'uploadAvatar failed [$status] POST /users/me/avatar -> $message | data: $responseData',
      );
      throw e.error is Exception
          ? e.error as Exception
          : ApiException(message, statusCode: status);
    }
  }
}
