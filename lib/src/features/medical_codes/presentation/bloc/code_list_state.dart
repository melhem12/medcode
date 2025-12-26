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

  const CodeListLoaded(this.codes);

  @override
  List<Object> get props => [codes];
}

class CodeListLoadingMore extends CodeListState {
  final List<MedicalCode> codes;

  const CodeListLoadingMore(this.codes);

  @override
  List<Object> get props => [codes];
}

class CodeListError extends CodeListState {
  final String message;

  const CodeListError(this.message);

  @override
  List<Object> get props => [message];
}



