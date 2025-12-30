import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_code.dart';
import '../../domain/usecases/get_medical_code_by_id_usecase.dart';

part 'code_detail_event.dart';
part 'code_detail_state.dart';

class CodeDetailBloc extends Bloc<CodeDetailEvent, CodeDetailState> {
  final GetMedicalCodeByIdUseCase getMedicalCodeByIdUseCase;

  CodeDetailBloc({required this.getMedicalCodeByIdUseCase})
      : super(CodeDetailInitial()) {
    on<LoadMedicalCodeEvent>(_onLoadMedicalCode);
  }

  Future<void> _onLoadMedicalCode(
    LoadMedicalCodeEvent event,
    Emitter<CodeDetailState> emit,
  ) async {
    emit(CodeDetailLoading());
    final result = await getMedicalCodeByIdUseCase(event.id);
    result.fold(
      (failure) => emit(CodeDetailError(failure.message)),
      (code) => emit(CodeDetailLoaded(code)),
    );
  }
}








