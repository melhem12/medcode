import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/import_all_result.dart';
import '../../domain/usecases/import_all_medical_codes_usecase.dart';

part 'admin_import_all_state.dart';

class AdminImportAllCubit extends Cubit<AdminImportAllState> {
  final ImportAllMedicalCodesUseCase importAllMedicalCodesUseCase;

  AdminImportAllCubit({required this.importAllMedicalCodesUseCase})
      : super(AdminImportAllInitial());

  Future<void> importAll({
    required String medicalCodesFilePath,
    String? contentsFilePath,
    String? category,
    String? bodySystem,
  }) async {
    if (isClosed) return;
    emit(AdminImportAllLoading());
    final result = await importAllMedicalCodesUseCase(
      medicalCodesFilePath: medicalCodesFilePath,
      contentsFilePath: contentsFilePath,
      category: category,
      bodySystem: bodySystem,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdminImportAllError(failure.message)),
      (importAllResult) => emit(AdminImportAllSuccess(importAllResult)),
    );
  }

  void reset() {
    if (isClosed) return;
    emit(AdminImportAllInitial());
  }
}





