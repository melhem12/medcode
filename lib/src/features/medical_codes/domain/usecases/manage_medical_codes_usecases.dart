import '../repositories/medical_codes_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/medical_code.dart';

class ExportMedicalCodesUseCase {
  final MedicalCodesRepository repository;

  ExportMedicalCodesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call() {
    return repository.exportMedicalCodes();
  }
}

class CreateMedicalCodeUseCase {
  final MedicalCodesRepository repository;

  CreateMedicalCodeUseCase(this.repository);

  Future<Either<Failure, MedicalCode>> call(Map<String, dynamic> data) {
    return repository.createMedicalCode(data);
  }
}

class UpdateMedicalCodeUseCase {
  final MedicalCodesRepository repository;

  UpdateMedicalCodeUseCase(this.repository);

  Future<Either<Failure, MedicalCode>> call(String id, Map<String, dynamic> data) {
    return repository.updateMedicalCode(id, data);
  }
}

class DeleteMedicalCodeUseCase {
  final MedicalCodesRepository repository;

  DeleteMedicalCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteMedicalCode(id);
  }
}


