import 'package:dartz/dartz.dart';
import '../entities/medical_code.dart';
import '../repositories/medical_codes_repository.dart';
import '../../../../core/error/failures.dart';

class GetMedicalCodeByIdUseCase {
  final MedicalCodesRepository repository;

  GetMedicalCodeByIdUseCase(this.repository);

  Future<Either<Failure, MedicalCode>> call(String id) {
    return repository.getMedicalCodeById(id);
  }
}



