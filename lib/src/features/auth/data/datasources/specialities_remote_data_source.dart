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
      final specialities = (data['data'] as List<dynamic>?)
              ?.map((e) => SpecialityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return specialities;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load specialities');
    }
  }
}


