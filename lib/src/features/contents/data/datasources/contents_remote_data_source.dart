import '../../domain/entities/content_node.dart';
import '../models/content_node_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';
import '../../../medical_codes/domain/entities/import_result.dart';
import '../../../medical_codes/data/models/import_result_model.dart';

abstract class ContentsRemoteDataSource {
  Future<List<ContentNode>> getContents();
  Future<List<Map<String, dynamic>>> exportContents();
  Future<ImportResult> importContents(String filePath);
  Future<ContentNode> createContent(Map<String, dynamic> data);
  Future<ContentNode> updateContent(String id, Map<String, dynamic> data);
  Future<void> deleteContent(String id);
}

class ContentsRemoteDataSourceImpl implements ContentsRemoteDataSource {
  final DioClient dioClient;

  ContentsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ContentNode>> getContents() async {
    try {
      final response = await dioClient.dio.get('/contents');
      final data = response.data as Map<String, dynamic>;
      final contents = (data['data'] as List<dynamic>?)
              ?.map((e) => ContentNodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return contents;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load contents');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportContents() async {
    try {
      final response = await dioClient.dio.get('/admin/export/contents');
      final data = response.data as Map<String, dynamic>;
      final rows = data['data'] as List<dynamic>? ?? [];
      return rows.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Export contents failed');
    }
  }

  @override
  Future<ImportResult> importContents(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response =
          await dioClient.dio.post('/admin/contents/import', data: formData);
      final data = response.data as Map<String, dynamic>;
      return ImportResultModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to import contents');
    }
  }

  @override
  Future<ContentNode> createContent(Map<String, dynamic> data) async {
    try {
      final response = await dioClient.dio.post('/admin/contents', data: data);
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to create content');
      }
      return ContentNodeModel.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to create content',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to create content: ${e.message}');
    }
  }

  @override
  Future<ContentNode> updateContent(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.dio.put('/admin/contents/$id', data: data);
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to update content');
      }
      return ContentNodeModel.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to update content',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to update content: ${e.message}');
    }
  }

  @override
  Future<void> deleteContent(String id) async {
    try {
      final response = await dioClient.dio.delete('/admin/contents/$id');
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to delete content');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to delete content',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to delete content: ${e.message}');
    }
  }
}


