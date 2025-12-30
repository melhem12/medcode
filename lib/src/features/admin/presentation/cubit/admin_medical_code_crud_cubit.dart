import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../medical_codes/domain/usecases/manage_medical_codes_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';
import '../../../../core/utils/export_data_transformer.dart';
import '../../../../core/error/exceptions.dart';

part 'admin_medical_code_crud_state.dart';

class AdminMedicalCodeCrudCubit extends Cubit<AdminMedicalCodeCrudState> {
  final ExportMedicalCodesUseCase exportUseCase;
  final CreateMedicalCodeUseCase createUseCase;
  final UpdateMedicalCodeUseCase updateUseCase;
  final DeleteMedicalCodeUseCase deleteUseCase;

  AdminMedicalCodeCrudCubit({
    required this.exportUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(AdminMedicalCodeCrudInitial());

  Future<void> export() async {
    if (isClosed) return;
    emit(AdminMedicalCodeCrudLoading());
    try {
      final rawRows = await exportUseCase();
      // Transform to match import format: Column A = code, Column B = description
      final transformedRows = ExportDataTransformer.transformMedicalCodes(rawRows);
      if (isClosed) return;
      final directoryPath = await FileExportHelper.getAndroidExportDirectoryPath(
        subDir: 'medical_codes',
      );
      final filePath = await FileExportHelper.exportToCsv(
        data: transformedRows,
        fileName: 'medical_codes',
        directoryPath: directoryPath,
        includeHeaders: true, // Medical codes import skips header row
      );
      if (isClosed) return;
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminMedicalCodeExported(transformedRows, filePath, displayPath));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    if (isClosed) return;
    emit(AdminMedicalCodeCrudLoading());
    try {
      final result = await createUseCase(data);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminMedicalCodeCrudError(failure.message)),
        (code) => emit(AdminMedicalCodeCrudSuccess(code, 'Medical code created successfully')),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    if (isClosed) return;
    emit(AdminMedicalCodeCrudLoading());
    try {
      final result = await updateUseCase(id, data);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminMedicalCodeCrudError(failure.message)),
        (code) => emit(AdminMedicalCodeCrudSuccess(code, 'Medical code updated successfully')),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }

  Future<void> delete(String id) async {
    if (isClosed) return;
    emit(AdminMedicalCodeCrudLoading());
    try {
      final result = await deleteUseCase(id);
      if (isClosed) return;
      result.fold(
        (failure) => emit(AdminMedicalCodeCrudError(failure.message)),
        (_) => emit(AdminMedicalCodeCrudDeleted()),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }
}
