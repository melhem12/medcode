part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final User user;

  const UserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}

class UserValidationError extends UserState {
  final String message;
  final Map<String, List<String>> fieldErrors;

  const UserValidationError(this.message, this.fieldErrors);

  @override
  List<Object> get props => [message, fieldErrors];
}




