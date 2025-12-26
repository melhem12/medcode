import '../repositories/medical_codes_repository.dart';

class ExportMedicalCodesUseCase {
  final MedicalCodesRepository repository;

  ExportMedicalCodesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call() {
    return repository.exportMedicalCodes();
  }
}


