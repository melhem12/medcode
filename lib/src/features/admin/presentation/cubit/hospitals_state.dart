part of 'hospitals_cubit.dart';

abstract class HospitalsState extends Equatable {
  const HospitalsState();

  @override
  List<Object> get props => [];
}

class HospitalsInitial extends HospitalsState {}

class HospitalsLoading extends HospitalsState {}

class HospitalsError extends HospitalsState {
  final String message;
  const HospitalsError(this.message);

  @override
  List<Object> get props => [message];
}

class HospitalsLoaded extends HospitalsState {
  final List<Hospital> hospitals;
  const HospitalsLoaded(this.hospitals);

  @override
  List<Object> get props => [hospitals];
}


