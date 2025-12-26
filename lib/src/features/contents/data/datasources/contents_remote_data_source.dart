import '../../domain/entities/content_node.dart';
import '../models/content_node_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class ContentsRemoteDataSource {
  Future<List<ContentNode>> getContents();
  Future<List<Map<String, dynamic>>> exportContents();
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
}


