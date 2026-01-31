import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/user_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateProfileUseCase {
  final UserRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, User>> call(Map<String, dynamic> payload) {
    return repository.updateProfile(payload);
  }
}






















