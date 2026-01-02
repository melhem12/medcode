import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/admin_simple_item.dart';

class AdminSpecialityHospitalRemoteDataSource {
  final DioClient dioClient;
  AdminSpecialityHospitalRemoteDataSource(this.dioClient);

  Future<AdminSimpleItem> createSpeciality(String name) async {
    try {
      final res = await dioClient.dio.post('/admin/specialities', data: {'name': name});
      final data = res.data as Map<String, dynamic>;
      final item = data['data'] as Map<String, dynamic>? ?? {};
      return AdminSimpleItem((item['id'] as num).toInt(), item['name'] as String);
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to create speciality');
    }
  }

  Future<AdminSimpleItem> updateSpeciality(int id, String name) async {
    try {
      final res = await dioClient.dio.put('/admin/specialities/$id', data: {'name': name});
      final data = res.data as Map<String, dynamic>;
      final item = data['data'] as Map<String, dynamic>? ?? {};
      return AdminSimpleItem((item['id'] as num).toInt(), item['name'] as String);
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to update speciality');
    }
  }

  Future<void> deleteSpeciality(int id) async {
    try {
      await dioClient.dio.delete('/admin/specialities/$id');
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to delete speciality');
    }
  }

  Future<AdminSimpleItem> createHospital(String name) async {
    try {
      final res = await dioClient.dio.post('/admin/hospitals', data: {'name': name});
      final data = res.data as Map<String, dynamic>;
      final item = data['data'] as Map<String, dynamic>? ?? {};
      return AdminSimpleItem((item['id'] as num).toInt(), item['name'] as String);
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to create hospital');
    }
  }

  Future<AdminSimpleItem> updateHospital(int id, String name) async {
    try {
      final res = await dioClient.dio.put('/admin/hospitals/$id', data: {'name': name});
      final data = res.data as Map<String, dynamic>;
      final item = data['data'] as Map<String, dynamic>? ?? {};
      return AdminSimpleItem((item['id'] as num).toInt(), item['name'] as String);
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to update hospital');
    }
  }

  Future<void> deleteHospital(int id) async {
    try {
      await dioClient.dio.delete('/admin/hospitals/$id');
    } on DioException catch (e) {
      throw e.error is Exception ? e.error as Exception : ApiException('Failed to delete hospital');
    }
  }
}
