import 'package:dio/dio.dart';
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
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load profile');
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
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to update profile');
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
      return data['avatar_url'] as String;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to upload avatar');
    }
  }
}


