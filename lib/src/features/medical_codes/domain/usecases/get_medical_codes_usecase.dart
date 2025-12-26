import 'package:dartz/dartz.dart';
import '../entities/medical_code.dart';
import '../repositories/medical_codes_repository.dart';
import '../../../../core/error/failures.dart';

class GetMedicalCodesUseCase {
  final MedicalCodesRepository repository;

  GetMedicalCodesUseCase(this.repository);

  Future<Either<Failure, List<MedicalCode>>> call({
    int page = 1,
    String? search,
    String? category,
    String? contentId,
  }) {
    return repository.getMedicalCodes(
      page: page,
      search: search,
      category: category,
      contentId: contentId,
    );
  }
}


