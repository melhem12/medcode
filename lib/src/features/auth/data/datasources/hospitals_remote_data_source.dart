import '../../domain/entities/hospital.dart';
import '../models/hospital_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class HospitalsRemoteDataSource {
  Future<List<Hospital>> getHospitals();
}

class HospitalsRemoteDataSourceImpl implements HospitalsRemoteDataSource {
  final DioClient dioClient;

  HospitalsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<Hospital>> getHospitals() async {
    try {
      final response = await dioClient.dio.get('/hospitals');
      final data = response.data as Map<String, dynamic>;
      
      // Check if response has the expected structure
      if (data['status'] != 'success') {
        throw ApiException(data['message'] as String? ?? 'Failed to load hospitals');
      }
      
      final hospitals = (data['data'] as List<dynamic>?)
              ?.map((e) => HospitalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return hospitals;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to load hospitals',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load hospitals: ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw ApiException('Failed to load hospitals: $e');
    }
  }
}


