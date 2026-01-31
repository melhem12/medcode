import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> clearAuthToken();
  Future<void> cacheUser(User user);
  Future<User?> getCachedUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.sharedPreferences,
  });

  @override
  Future<void> cacheAuthToken(String token) async {
    await secureStorage.write(key: 'auth_token', value: token);
  }

  @override
  Future<String?> getAuthToken() async {
    return await secureStorage.read(key: 'auth_token');
  }

  @override
  Future<void> clearAuthToken() async {
    await secureStorage.delete(key: 'auth_token');
  }

  @override
  Future<void> cacheUser(User user) async {
    final userJson = UserModel.fromEntity(user).toJson();
    await sharedPreferences.setString('cached_user', jsonEncode(userJson));
  }

  @override
  Future<User?> getCachedUser() async {
    final userJsonString = sharedPreferences.getString('cached_user');
    if (userJsonString == null) return null;
    try {
      final Map<String, dynamic> jsonMap =
          jsonDecode(userJsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await sharedPreferences.remove('cached_user');
  }
}






















