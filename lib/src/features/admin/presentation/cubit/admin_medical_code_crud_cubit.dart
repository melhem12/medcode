import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../medical_codes/domain/usecases/manage_medical_codes_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';

part 'admin_medical_code_crud_state.dart';

class AdminMedicalCodeCrudCubit extends Cubit<AdminMedicalCodeCrudState> {
  final ExportMedicalCodesUseCase exportUseCase;

  AdminMedicalCodeCrudCubit({required this.exportUseCase})
      : super(AdminMedicalCodeCrudInitial());

  Future<void> export() async {
    emit(AdminMedicalCodeCrudLoading());
    try {
      final rows = await exportUseCase();
      final filePath = await FileExportHelper.exportToCsv(
        data: rows,
        fileName: 'medical_codes',
      );
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminMedicalCodeExported(rows, filePath, displayPath));
    } catch (e) {
      emit(AdminMedicalCodeCrudError(e.toString()));
    }
  }
}

