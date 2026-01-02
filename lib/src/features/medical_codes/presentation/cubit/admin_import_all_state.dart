part of 'admin_import_all_cubit.dart';

abstract class AdminImportAllState extends Equatable {
  const AdminImportAllState();

  @override
  List<Object?> get props => [];
}

class AdminImportAllInitial extends AdminImportAllState {}

class AdminImportAllLoading extends AdminImportAllState {}

class AdminImportAllSuccess extends AdminImportAllState {
  final ImportAllResult result;

  const AdminImportAllSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class AdminImportAllError extends AdminImportAllState {
  final String message;

  const AdminImportAllError(this.message);

  @override
  List<Object?> get props => [message];
}





