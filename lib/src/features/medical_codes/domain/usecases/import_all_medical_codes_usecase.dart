import 'package:dartz/dartz.dart';
import '../entities/import_all_result.dart';
import '../repositories/medical_codes_repository.dart';
import '../../../../core/error/failures.dart';

class ImportAllMedicalCodesUseCase {
  final MedicalCodesRepository repository;

  ImportAllMedicalCodesUseCase(this.repository);

  Future<Either<Failure, ImportAllResult>> call({
    required String medicalCodesFilePath,
    String? contentsFilePath,
    String? category,
    String? bodySystem,
  }) {
    return repository.importAll(
      medicalCodesFilePath: medicalCodesFilePath,
      contentsFilePath: contentsFilePath,
      category: category,
      bodySystem: bodySystem,
    );
  }
}





