import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../medical_codes/domain/usecases/manage_medical_codes_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';

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
      final rows = await exportUseCase();
      if (isClosed) return;
      final filePath = await FileExportHelper.exportToCsv(
        data: rows,
        fileName: 'medical_codes',
      );
      if (isClosed) return;
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminMedicalCodeExported(rows, filePath, displayPath));
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
    } catch (e) {
      if (isClosed) return;
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }
}

