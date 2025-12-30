import 'package:dartz/dartz.dart';
import '../entities/import_result.dart';
import '../repositories/medical_codes_repository.dart';
import '../../../../core/error/failures.dart';

class ImportMedicalCodesUseCase {
  final MedicalCodesRepository repository;

  ImportMedicalCodesUseCase(this.repository);

  Future<Either<Failure, ImportResult>> call(String filePath, String? contentId) {
    return repository.importMedicalCodes(filePath, contentId);
  }
}








