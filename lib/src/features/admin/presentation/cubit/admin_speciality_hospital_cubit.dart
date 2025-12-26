import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_simple_item.dart';
import '../../domain/usecases/manage_specialities_hospitals_usecases.dart';

part 'admin_speciality_hospital_state.dart';

class AdminSpecialityHospitalCubit extends Cubit<AdminSpecialityHospitalState> {
  final CreateSpecialityUseCase createSpeciality;
  final UpdateSpecialityUseCase updateSpeciality;
  final DeleteSpecialityUseCase deleteSpeciality;
  final CreateHospitalUseCase createHospital;
  final UpdateHospitalUseCase updateHospital;
  final DeleteHospitalUseCase deleteHospital;

  AdminSpecialityHospitalCubit({
    required this.createSpeciality,
    required this.updateSpeciality,
    required this.deleteSpeciality,
    required this.createHospital,
    required this.updateHospital,
    required this.deleteHospital,
  }) : super(AdminSpecialityHospitalInitial());

  Future<void> addSpeciality(String name) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      final item = await createSpeciality(name);
      emit(AdminSpecialityHospitalSuccess(item, 'Speciality added'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }

  Future<void> editSpeciality(int id, String name) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      final item = await updateSpeciality(id, name);
      emit(AdminSpecialityHospitalSuccess(item, 'Speciality updated'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }

  Future<void> removeSpeciality(int id) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      await deleteSpeciality(id);
      emit(AdminSpecialityHospitalDeleted('Speciality deleted'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }

  Future<void> addHospital(String name) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      final item = await createHospital(name);
      emit(AdminSpecialityHospitalSuccess(item, 'Hospital added'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }

  Future<void> editHospital(int id, String name) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      final item = await updateHospital(id, name);
      emit(AdminSpecialityHospitalSuccess(item, 'Hospital updated'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }

  Future<void> removeHospital(int id) async {
    emit(AdminSpecialityHospitalLoading());
    try {
      await deleteHospital(id);
      emit(AdminSpecialityHospitalDeleted('Hospital deleted'));
    } catch (e) {
      emit(AdminSpecialityHospitalError(e.toString()));
    }
  }
}
