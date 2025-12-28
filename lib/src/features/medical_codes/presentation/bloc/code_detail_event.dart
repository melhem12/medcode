part of 'code_detail_bloc.dart';

abstract class CodeDetailEvent extends Equatable {
  const CodeDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadMedicalCodeEvent extends CodeDetailEvent {
  final String id;

  const LoadMedicalCodeEvent(this.id);

  @override
  List<Object> get props => [id];
}




