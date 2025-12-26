import '../repositories/contents_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../medical_codes/domain/entities/import_result.dart';
import '../entities/content_node.dart';

class ExportContentsUseCase {
  final ContentsRepository repository;

  ExportContentsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call() {
    return repository.exportContents();
  }
}

class ImportContentsUseCase {
  final ContentsRepository repository;

  ImportContentsUseCase(this.repository);

  Future<Either<Failure, ImportResult>> call(String filePath) {
    return repository.importContents(filePath);
  }
}

class CreateContentUseCase {
  final ContentsRepository repository;

  CreateContentUseCase(this.repository);

  Future<Either<Failure, ContentNode>> call(Map<String, dynamic> data) {
    return repository.createContent(data);
  }
}

class UpdateContentUseCase {
  final ContentsRepository repository;

  UpdateContentUseCase(this.repository);

  Future<Either<Failure, ContentNode>> call(String id, Map<String, dynamic> data) {
    return repository.updateContent(id, data);
  }
}

class DeleteContentUseCase {
  final ContentsRepository repository;

  DeleteContentUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteContent(id);
  }
}


