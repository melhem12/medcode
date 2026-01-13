part of 'code_detail_bloc.dart';

abstract class CodeDetailState extends Equatable {
  const CodeDetailState();

  @override
  List<Object> get props => [];
}

class CodeDetailInitial extends CodeDetailState {}

class CodeDetailLoading extends CodeDetailState {}

class CodeDetailLoaded extends CodeDetailState {
  final MedicalCode code;

  const CodeDetailLoaded(this.code);

  @override
  List<Object> get props => [code];
}

class CodeDetailError extends CodeDetailState {
  final String message;

  const CodeDetailError(this.message);

  @override
  List<Object> get props => [message];
}





















