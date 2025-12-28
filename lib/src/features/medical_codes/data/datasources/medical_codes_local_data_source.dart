import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/medical_code.dart';
import '../models/medical_code_model.dart';

abstract class MedicalCodesLocalDataSource {
  Future<void> cacheMedicalCodes(List<MedicalCode> codes);
  Future<List<MedicalCode>> getCachedMedicalCodes();
}

class MedicalCodesLocalDataSourceImpl implements MedicalCodesLocalDataSource {
  static const String _cacheKey = 'cached_medical_codes';
  final SharedPreferences prefs;

  MedicalCodesLocalDataSourceImpl(this.prefs);

  @override
  Future<void> cacheMedicalCodes(List<MedicalCode> codes) async {
    final payload = codes.map(_codeToJson).toList();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  @override
  Future<List<MedicalCode>> getCachedMedicalCodes() async {
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => MedicalCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _codeToJson(MedicalCode code) {
    return {
      'id': code.id,
      'code': code.code,
      'description': code.description,
      'category': code.category,
      'body_system': code.bodySystem,
      'content_id': code.contentId,
      'page_marker': code.pageMarker,
    };
  }
}
