import '../../domain/entities/admin_simple_item.dart';
import '../../data/sources/admin_speciality_hospital_remote_data_source.dart';

class CreateSpecialityUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  CreateSpecialityUseCase(this.remote);
  Future<AdminSimpleItem> call(String name) => remote.createSpeciality(name);
}

class UpdateSpecialityUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  UpdateSpecialityUseCase(this.remote);
  Future<AdminSimpleItem> call(int id, String name) =>
      remote.updateSpeciality(id, name);
}

class DeleteSpecialityUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  DeleteSpecialityUseCase(this.remote);
  Future<void> call(int id) => remote.deleteSpeciality(id);
}

class CreateHospitalUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  CreateHospitalUseCase(this.remote);
  Future<AdminSimpleItem> call(String name) => remote.createHospital(name);
}

class UpdateHospitalUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  UpdateHospitalUseCase(this.remote);
  Future<AdminSimpleItem> call(int id, String name) =>
      remote.updateHospital(id, name);
}

class DeleteHospitalUseCase {
  final AdminSpecialityHospitalRemoteDataSource remote;
  DeleteHospitalUseCase(this.remote);
  Future<void> call(int id) => remote.deleteHospital(id);
}
