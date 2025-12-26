import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_code.dart';
import '../../domain/usecases/get_medical_codes_usecase.dart';

part 'code_list_event.dart';
part 'code_list_state.dart';

class CodeListBloc extends Bloc<CodeListEvent, CodeListState> {
  final GetMedicalCodesUseCase getMedicalCodesUseCase;

  CodeListBloc({required this.getMedicalCodesUseCase})
      : super(CodeListInitial()) {
    on<LoadMedicalCodesEvent>(_onLoadMedicalCodes);
  }

  Future<void> _onLoadMedicalCodes(
    LoadMedicalCodesEvent event,
    Emitter<CodeListState> emit,
  ) async {
    emit(CodeListLoading());
    final result = await getMedicalCodesUseCase(
      page: event.page,
      search: event.search,
      category: event.category,
      contentId: event.contentId,
    );
    result.fold(
      (failure) => emit(CodeListError(failure.message)),
      (codes) => emit(CodeListLoaded(codes)),
    );
  }
}


