import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/usecases/import_medical_codes_usecase.dart';

part 'admin_import_state.dart';

class AdminImportCubit extends Cubit<AdminImportState> {
  final ImportMedicalCodesUseCase importMedicalCodesUseCase;

  AdminImportCubit({required this.importMedicalCodesUseCase})
      : super(AdminImportInitial());

  Future<void> import(String filePath, String? contentId) async {
    emit(AdminImportLoading());
    final result = await importMedicalCodesUseCase(filePath, contentId);
    result.fold(
      (failure) => emit(AdminImportError(failure.message)),
      (importResult) => emit(AdminImportSuccess(importResult)),
    );
  }
}








