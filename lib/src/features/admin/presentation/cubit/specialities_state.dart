part of 'specialities_cubit.dart';

abstract class SpecialitiesState extends Equatable {
  const SpecialitiesState();

  @override
  List<Object> get props => [];
}

class SpecialitiesInitial extends SpecialitiesState {}

class SpecialitiesLoading extends SpecialitiesState {}

class SpecialitiesError extends SpecialitiesState {
  final String message;
  const SpecialitiesError(this.message);

  @override
  List<Object> get props => [message];
}

class SpecialitiesLoaded extends SpecialitiesState {
  final List<Speciality> specialities;
  const SpecialitiesLoaded(this.specialities);

  @override
  List<Object> get props => [specialities];
}







