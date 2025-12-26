import 'package:dartz/dartz.dart';
import '../entities/medical_code.dart';
import '../entities/import_result.dart';
import '../../../../core/error/failures.dart';

abstract class MedicalCodesRepository {
  Future<Either<Failure, List<MedicalCode>>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
    String? contentId,
  });
  Future<Either<Failure, MedicalCode>> getMedicalCodeById(String id);
  Future<Either<Failure, ImportResult>> importMedicalCodes(
    String filePath,
    String? contentId,
  );
  Future<List<Map<String, dynamic>>> exportMedicalCodes();
  Future<Either<Failure, MedicalCode>> createMedicalCode(Map<String, dynamic> data);
  Future<Either<Failure, MedicalCode>> updateMedicalCode(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteMedicalCode(String id);
}


