part of 'admin_medical_code_crud_cubit.dart';

abstract class AdminMedicalCodeCrudState extends Equatable {
  const AdminMedicalCodeCrudState();

  @override
  List<Object> get props => [];
}

class AdminMedicalCodeCrudInitial extends AdminMedicalCodeCrudState {}

class AdminMedicalCodeCrudLoading extends AdminMedicalCodeCrudState {}

class AdminMedicalCodeCrudSuccess extends AdminMedicalCodeCrudState {
  final MedicalCode code;
  final String message;

  AdminMedicalCodeCrudSuccess(this.code, this.message);

  @override
  List<Object> get props => [code, message];
}

class AdminMedicalCodeCrudDeleted extends AdminMedicalCodeCrudState {}

class AdminMedicalCodeExported extends AdminMedicalCodeCrudState {
  final List<Map<String, dynamic>> rows;
  final String filePath;
  final String displayPath;

  AdminMedicalCodeExported(this.rows, this.filePath, this.displayPath);

  @override
  List<Object> get props => [rows, filePath, displayPath];
}

class AdminMedicalCodeCrudError extends AdminMedicalCodeCrudState {
  final String message;

  AdminMedicalCodeCrudError(this.message);

  @override
  List<Object> get props => [message];
}





















