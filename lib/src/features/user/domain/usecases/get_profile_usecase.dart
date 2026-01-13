import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/user_repository.dart';
import '../../../../core/error/failures.dart';

class GetProfileUseCase {
  final UserRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<Failure, User>> call() {
    return repository.getProfile();
  }
}





















