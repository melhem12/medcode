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
    on<LoadMoreMedicalCodesEvent>(_onLoadMoreMedicalCodes);
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
      (codes) => emit(
        CodeListLoaded(
          codes: codes,
          page: event.page,
          hasMore: codes.length == 20,
          search: event.search,
          contentId: event.contentId,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreMedicalCodes(
    LoadMoreMedicalCodesEvent event,
    Emitter<CodeListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CodeListLoaded) return;
    if (!currentState.hasMore) return;

    emit(CodeListLoadingMore(
      codes: currentState.codes,
      page: currentState.page,
      hasMore: currentState.hasMore,
      search: currentState.search,
      contentId: currentState.contentId,
    ));

    final nextPage = currentState.page + 1;
    final result = await getMedicalCodesUseCase(
      page: nextPage,
      search: currentState.search,
      contentId: currentState.contentId,
    );
    result.fold(
      (_) => emit(CodeListLoaded(
            codes: currentState.codes,
            page: currentState.page,
            hasMore: currentState.hasMore,
            search: currentState.search,
            contentId: currentState.contentId,
          )),
      (codes) => emit(
        CodeListLoaded(
          codes: [...currentState.codes, ...codes],
          page: nextPage,
          hasMore: codes.length == 20,
          search: currentState.search,
          contentId: currentState.contentId,
        ),
      ),
    );
  }
}

