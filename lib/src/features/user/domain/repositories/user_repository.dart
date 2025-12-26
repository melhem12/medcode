import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> payload);
  Future<Either<Failure, String>> uploadAvatar(String filePath);
}


