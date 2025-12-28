part of 'code_list_bloc.dart';

abstract class CodeListState extends Equatable {
  const CodeListState();

  @override
  List<Object> get props => [];
}

class CodeListInitial extends CodeListState {}

class CodeListLoading extends CodeListState {}

class CodeListLoaded extends CodeListState {
  final List<MedicalCode> codes;
  final int page;
  final bool hasMore;
  final String? search;
  final String? contentId;

  const CodeListLoaded({
    required this.codes,
    required this.page,
    required this.hasMore,
    this.search,
    this.contentId,
  });

  @override
  List<Object> get props => [
        codes,
        page,
        hasMore,
        search ?? '',
        contentId ?? '',
      ];
}

class CodeListLoadingMore extends CodeListState {
  final List<MedicalCode> codes;
  final int page;
  final bool hasMore;
  final String? search;
  final String? contentId;

  const CodeListLoadingMore({
    required this.codes,
    required this.page,
    required this.hasMore,
    this.search,
    this.contentId,
  });

  @override
  List<Object> get props => [
        codes,
        page,
        hasMore,
        search ?? '',
        contentId ?? '',
      ];
}

class CodeListError extends CodeListState {
  final String message;

  const CodeListError(this.message);

  @override
  List<Object> get props => [message];
}



