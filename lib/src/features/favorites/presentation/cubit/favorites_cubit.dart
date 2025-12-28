import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../medical_codes/domain/repositories/medical_codes_repository.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository favoritesRepository;
  final MedicalCodesRepository medicalCodesRepository;

  FavoritesCubit({
    required this.favoritesRepository,
    required this.medicalCodesRepository,
  }) : super(FavoritesInitial());

  Future<void> loadFavorites() async {
    emit(FavoritesLoading());
    try {
      final favoriteIds = await favoritesRepository.getFavoriteCodeIds();
      final favorites = <MedicalCode>[];
      
      for (final id in favoriteIds) {
        final result = await medicalCodesRepository.getMedicalCodeById(id);
        result.fold(
          (_) => null,
          (code) => favorites.add(code),
        );
      }
      
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> toggleFavorite(String codeId) async {
    final isFavorite = await favoritesRepository.isFavorite(codeId);
    
    if (isFavorite) {
      await favoritesRepository.removeFavorite(codeId);
      await loadFavorites();
      final currentState = state;
      if (currentState is FavoritesLoaded) {
        emit(FavoriteOperationSuccess('Removed from favorites', currentState.favorites));
        emit(FavoritesLoaded(currentState.favorites));
      }
    } else {
      await favoritesRepository.addFavorite(codeId);
      await loadFavorites();
      final currentState = state;
      if (currentState is FavoritesLoaded) {
        emit(FavoriteOperationSuccess('Added to favorites', currentState.favorites));
        emit(FavoritesLoaded(currentState.favorites));
      }
    }
  }

  Future<void> addFavorite(String codeId) async {
    await favoritesRepository.addFavorite(codeId);
    await loadFavorites();
  }

  Future<void> removeFavorite(String codeId) async {
    await favoritesRepository.removeFavorite(codeId);
    await loadFavorites();
  }

  Future<bool> isFavorite(String codeId) async {
    return await favoritesRepository.isFavorite(codeId);
  }

  Future<void> clearFavorites() async {
    await favoritesRepository.clearFavorites();
    emit(FavoritesInitial());
  }
}



