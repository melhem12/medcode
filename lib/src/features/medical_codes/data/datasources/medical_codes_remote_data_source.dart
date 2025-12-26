import '../../domain/entities/medical_code.dart';
import '../../domain/entities/import_result.dart';
import '../models/medical_code_model.dart';
import '../models/import_result_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class MedicalCodesRemoteDataSource {
  Future<List<MedicalCode>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
  });
  Future<MedicalCode> getMedicalCodeById(String id);
  Future<ImportResult> importMedicalCodes(String filePath, String? contentId);
  Future<List<Map<String, dynamic>>> exportMedicalCodes();
}

class MedicalCodesRemoteDataSourceImpl implements MedicalCodesRemoteDataSource {
  final DioClient dioClient;

  MedicalCodesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<MedicalCode>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await dioClient.dio.get(
        '/medical-codes',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final codes = (data['data'] as List<dynamic>?)
              ?.map((e) => MedicalCodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return codes;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load medical codes');
    }
  }

  @override
  Future<MedicalCode> getMedicalCodeById(String id) async {
    try {
      final response = await dioClient.dio.get('/medical-codes/$id');
      final data = response.data as Map<String, dynamic>;
      return MedicalCodeModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load medical code');
    }
  }

  @override
  Future<ImportResult> importMedicalCodes(
      String filePath, String? contentId) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (contentId != null) 'content_id': contentId,
      });

      final response =
          await dioClient.dio.post('/admin/import/medical-codes', data: formData);
      final data = response.data as Map<String, dynamic>;
      return ImportResultModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to import medical codes');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportMedicalCodes() async {
    try {
      final response = await dioClient.dio.get('/admin/export/medical-codes');
      final data = response.data as Map<String, dynamic>;
      final rows = data['data'] as List<dynamic>? ?? [];
      return rows.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Export medical codes failed');
    }
  }
}


