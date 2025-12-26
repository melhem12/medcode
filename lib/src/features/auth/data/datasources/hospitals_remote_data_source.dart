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
      final hospitals = (data['data'] as List<dynamic>?)
              ?.map((e) => HospitalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return hospitals;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load hospitals');
    }
  }
}


