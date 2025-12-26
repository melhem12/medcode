import 'package:dartz/dartz.dart';
import '../entities/content_node.dart';
import '../repositories/contents_repository.dart';
import '../../../../core/error/failures.dart';

class GetContentsUseCase {
  final ContentsRepository repository;

  GetContentsUseCase(this.repository);

  Future<Either<Failure, List<ContentNode>>> call() {
    return repository.getContents();
  }
}



