import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../../../contents/domain/usecases/manage_contents_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';
import '../../../../core/utils/export_data_transformer.dart';
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
      final rawRows = await exportUseCase();
      // Transform to match import format:
      // Column A = section_label, B = system_title, C = category_title, 
      // D = subcategory_title, E = code_hint, F = page_marker
      final transformedRows = ExportDataTransformer.transformContents(rawRows);
      final directoryPath = await FileExportHelper.getAndroidExportDirectoryPath(
        subDir: 'contents',
      );
      final filePath = await FileExportHelper.exportToCsv(
        data: transformedRows,
        fileName: 'contents',
        directoryPath: directoryPath,
        includeHeaders: false, // Contents import does NOT skip header row, so we don't include headers
      );
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminContentExported(transformedRows, filePath, displayPath));
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
