part of 'code_list_bloc.dart';

abstract class CodeListEvent extends Equatable {
  const CodeListEvent();

  @override
  List<Object> get props => [];
}

class LoadMedicalCodesEvent extends CodeListEvent {
  final int page;
  final String? search;
  final String? category;

  const LoadMedicalCodesEvent({
    this.page = 1,
    this.search,
    this.category,
  });

  @override
  List<Object> get props => [page, search ?? '', category ?? ''];
}


