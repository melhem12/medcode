import '../../domain/entities/import_result.dart';

class ImportResultModel extends ImportResult {
  ImportResultModel({
    required super.imported,
    required super.updated,
    required super.skipped,
    required super.errors,
  });

  factory ImportResultModel.fromJson(Map<String, dynamic> json) {
    return ImportResultModel(
      imported: json['imported'] as int? ?? 0,
      updated: json['updated'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

