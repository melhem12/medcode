abstract class FavoritesRepository {
  Future<void> addFavorite(String codeId);
  Future<void> removeFavorite(String codeId);
  Future<bool> isFavorite(String codeId);
  Future<List<String>> getFavoriteCodeIds();
  Future<void> clearFavorites();
}

















