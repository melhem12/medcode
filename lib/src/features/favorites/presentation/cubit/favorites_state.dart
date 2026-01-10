import 'package:equatable/equatable.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<MedicalCode> favorites;

  const FavoritesLoaded(this.favorites);

  @override
  List<Object> get props => [favorites];
}

class FavoriteOperationSuccess extends FavoritesState {
  final String message;
  final List<MedicalCode> favorites;

  const FavoriteOperationSuccess(this.message, this.favorites);

  @override
  List<Object> get props => [message, favorites];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object> get props => [message];
}




















