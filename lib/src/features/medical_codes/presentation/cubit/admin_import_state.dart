part of 'admin_import_cubit.dart';

abstract class AdminImportState extends Equatable {
  const AdminImportState();

  @override
  List<Object> get props => [];
}

class AdminImportInitial extends AdminImportState {}

class AdminImportLoading extends AdminImportState {}

class AdminImportSuccess extends AdminImportState {
  final ImportResult result;

  const AdminImportSuccess(this.result);

  @override
  List<Object> get props => [result];
}

class AdminImportError extends AdminImportState {
  final String message;

  const AdminImportError(this.message);

  @override
  List<Object> get props => [message];
}





















