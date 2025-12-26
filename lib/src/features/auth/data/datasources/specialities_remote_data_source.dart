import '../../domain/entities/speciality.dart';
import '../models/speciality_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class SpecialitiesRemoteDataSource {
  Future<List<Speciality>> getSpecialities();
}

class SpecialitiesRemoteDataSourceImpl implements SpecialitiesRemoteDataSource {
  final DioClient dioClient;

  SpecialitiesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<Speciality>> getSpecialities() async {
    try {
      final response = await dioClient.dio.get('/specialities');
      final data = response.data as Map<String, dynamic>;
      
      // Check if response has the expected structure
      if (data['status'] != 'success') {
        throw ApiException(data['message'] as String? ?? 'Failed to load specialities');
      }
      
      final specialities = (data['data'] as List<dynamic>?)
              ?.map((e) => SpecialityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return specialities;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to load specialities',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load specialities: ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw ApiException('Failed to load specialities: $e');
    }
  }
}


