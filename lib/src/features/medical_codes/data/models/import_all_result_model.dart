import '../../domain/entities/import_all_result.dart';
import 'import_result_model.dart';

class ImportAllResultModel extends ImportAllResult {
  ImportAllResultModel({
    required super.medicalCodes,
    super.contents,
  });

  factory ImportAllResultModel.fromJson(Map<String, dynamic> json) {
    return ImportAllResultModel(
      medicalCodes: ImportResultModel.fromJson(
        json['medical_codes'] as Map<String, dynamic>,
      ),
      contents: json['contents'] != null
          ? ImportResultModel.fromJson(
              json['contents'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

