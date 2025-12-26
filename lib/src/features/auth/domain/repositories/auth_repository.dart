import '../entities/auth_response.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login(String email, String password);
  Future<Either<Failure, AuthResponse>> register(Map<String, dynamic> payload);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> checkAuthStatus();
}


