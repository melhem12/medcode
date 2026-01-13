part of 'contents_cubit.dart';

abstract class ContentsState extends Equatable {
  const ContentsState();

  @override
  List<Object> get props => [];
}

class ContentsInitial extends ContentsState {}

class ContentsLoading extends ContentsState {}

class ContentsLoaded extends ContentsState {
  final List<ContentNode> contents;

  const ContentsLoaded(this.contents);

  @override
  List<Object> get props => [contents];
}

class ContentsError extends ContentsState {
  final String message;

  const ContentsError(this.message);

  @override
  List<Object> get props => [message];
}





















