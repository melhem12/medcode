part of 'admin_content_crud_cubit.dart';

abstract class AdminContentCrudState extends Equatable {
  const AdminContentCrudState();

  @override
  List<Object> get props => [];
}

class AdminContentCrudInitial extends AdminContentCrudState {}

class AdminContentCrudLoading extends AdminContentCrudState {}

class AdminContentCrudSuccess extends AdminContentCrudState {
  final ContentNode node;
  final String message;

  AdminContentCrudSuccess(this.node, this.message);

  @override
  List<Object> get props => [node, message];
}

class AdminContentCrudDeleted extends AdminContentCrudState {}

class AdminContentExported extends AdminContentCrudState {
  final List<Map<String, dynamic>> rows;
  final String filePath;
  final String displayPath;

  AdminContentExported(this.rows, this.filePath, this.displayPath);

  @override
  List<Object> get props => [rows, filePath, displayPath];
}

class AdminContentImported extends AdminContentCrudState {
  final ImportResult result;

  AdminContentImported(this.result);

  @override
  List<Object> get props => [result];
}

class AdminContentCrudError extends AdminContentCrudState {
  final String message;

  AdminContentCrudError(this.message);

  @override
  List<Object> get props => [message];
}


