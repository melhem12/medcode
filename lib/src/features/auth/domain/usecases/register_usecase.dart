import 'package:dartz/dartz.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, AuthResponse>> call(Map<String, dynamic> payload) {
    return repository.register(payload);
  }
}






















