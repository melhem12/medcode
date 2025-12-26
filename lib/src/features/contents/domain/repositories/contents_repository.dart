import 'package:dartz/dartz.dart';
import '../entities/content_node.dart';
import '../../../../core/error/failures.dart';

abstract class ContentsRepository {
  Future<Either<Failure, List<ContentNode>>> getContents();
  Future<List<Map<String, dynamic>>> exportContents();
}


