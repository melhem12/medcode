import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource localDataSource;

  FavoritesRepositoryImpl(this.localDataSource);

  @override
  Future<void> addFavorite(String codeId) => localDataSource.addFavorite(codeId);

  @override
  Future<void> removeFavorite(String codeId) =>
      localDataSource.removeFavorite(codeId);

  @override
  Future<bool> isFavorite(String codeId) => localDataSource.isFavorite(codeId);

  @override
  Future<List<String>> getFavoriteCodeIds() =>
      localDataSource.getFavoriteCodeIds();
}



