import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../../../contents/domain/usecases/manage_contents_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';
import '../../../medical_codes/domain/entities/import_result.dart';

part 'admin_content_crud_state.dart';

class AdminContentCrudCubit extends Cubit<AdminContentCrudState> {
  final ExportContentsUseCase exportUseCase;
  final ImportContentsUseCase importUseCase;
  final CreateContentUseCase createUseCase;
  final UpdateContentUseCase updateUseCase;
  final DeleteContentUseCase deleteUseCase;

  AdminContentCrudCubit({
    required this.exportUseCase,
    required this.importUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(AdminContentCrudInitial());

  Future<void> export() async {
    emit(AdminContentCrudLoading());
    try {
      final rows = await exportUseCase();
      final filePath = await FileExportHelper.exportToCsv(
        data: rows,
        fileName: 'contents',
      );
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminContentExported(rows, filePath, displayPath));
    } catch (e) {
      emit(AdminContentCrudError(e.toString()));
    }
  }

  Future<void> import(String filePath) async {
    emit(AdminContentCrudLoading());
    try {
      final result = await importUseCase(filePath);
      result.fold(
        (failure) => emit(AdminContentCrudError(failure.message)),
        (importResult) => emit(AdminContentImported(importResult)),
      );
    } catch (e) {
      emit(AdminContentCrudError(e.toString()));
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    if (isClosed) return;
    emit(AdminContentCrudLoading());
    try {
      final result = await createUseCase(data);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminContentCrudError(failure.message)),
        (content) => emit(AdminContentCrudSuccess(content, 'Content created successfully')),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AdminContentCrudError(e.toString()));
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    if (isClosed) return;
    emit(AdminContentCrudLoading());
    try {
      final result = await updateUseCase(id, data);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminContentCrudError(failure.message)),
        (content) => emit(AdminContentCrudSuccess(content, 'Content updated successfully')),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AdminContentCrudError(e.toString()));
    }
  }

  Future<void> delete(String id) async {
    if (isClosed) return;
    emit(AdminContentCrudLoading());
    try {
      final result = await deleteUseCase(id);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminContentCrudError(failure.message)),
        (_) => emit(AdminContentCrudDeleted()),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AdminContentCrudError(e.toString()));
    }
  }
}

