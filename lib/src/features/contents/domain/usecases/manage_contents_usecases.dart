import '../repositories/contents_repository.dart';

class ExportContentsUseCase {
  final ContentsRepository repository;

  ExportContentsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call() {
    return repository.exportContents();
  }
}


