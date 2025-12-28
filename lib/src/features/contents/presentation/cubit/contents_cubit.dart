import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/content_node.dart';
import '../../domain/usecases/get_contents_usecase.dart';

part 'contents_state.dart';

class ContentsCubit extends Cubit<ContentsState> {
  final GetContentsUseCase getContentsUseCase;

  ContentsCubit({required this.getContentsUseCase}) : super(ContentsInitial());

  Future<void> fetchContents() async {
    emit(ContentsLoading());
    final result = await getContentsUseCase();
    result.fold(
      (failure) => emit(ContentsError(failure.message)),
      (contents) => emit(ContentsLoaded(contents)),
    );
  }
}




