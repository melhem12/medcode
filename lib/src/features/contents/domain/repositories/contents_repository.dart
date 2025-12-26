import 'package:dartz/dartz.dart';
import '../entities/content_node.dart';
import '../../../../core/error/failures.dart';
import '../../../medical_codes/domain/entities/import_result.dart';

abstract class ContentsRepository {
  Future<Either<Failure, List<ContentNode>>> getContents();
  Future<List<Map<String, dynamic>>> exportContents();
  Future<Either<Failure, ImportResult>> importContents(String filePath);
  Future<Either<Failure, ContentNode>> createContent(Map<String, dynamic> data);
  Future<Either<Failure, ContentNode>> updateContent(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteContent(String id);
}


