part of 'admin_speciality_hospital_cubit.dart';

abstract class AdminSpecialityHospitalState {}

class AdminSpecialityHospitalInitial extends AdminSpecialityHospitalState {}

class AdminSpecialityHospitalLoading extends AdminSpecialityHospitalState {}

class AdminSpecialityHospitalSuccess extends AdminSpecialityHospitalState {
  final AdminSimpleItem item;
  final String message;
  AdminSpecialityHospitalSuccess(this.item, this.message);
}

class AdminSpecialityHospitalDeleted extends AdminSpecialityHospitalState {
  final String message;
  AdminSpecialityHospitalDeleted(this.message);
}

class AdminSpecialityHospitalError extends AdminSpecialityHospitalState {
  final String message;
  AdminSpecialityHospitalError(this.message);
}
