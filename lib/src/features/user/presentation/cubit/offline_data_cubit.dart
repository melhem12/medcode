import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/offline_data_local_data_source.dart';
import 'offline_data_state.dart';

class OfflineDataCubit extends Cubit<OfflineDataState> {
  final OfflineDataLocalDataSource localDataSource;

  OfflineDataCubit({required this.localDataSource})
      : super(OfflineDataInitial()) {
    loadOfflineDataStatus();
  }

  Future<void> loadOfflineDataStatus() async {
    emit(OfflineDataLoading());
    try {
      final syncStatus = await localDataSource.getSyncStatus();
      final downloadedCategories =
          await localDataSource.getDownloadedCategories();
      emit(OfflineDataLoaded(
        syncStatus: syncStatus,
        downloadedCategories: downloadedCategories,
      ));
    } catch (e) {
      emit(OfflineDataError(e.toString()));
    }
  }

  Future<void> syncAllData() async {
    emit(OfflineDataLoading());
    try {
      await localDataSource.setSyncStatus({
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': false,
      });
      await loadOfflineDataStatus();
    } catch (e) {
      emit(OfflineDataError(e.toString()));
    }
  }

  Future<void> downloadCategory(String category) async {
    try {
      await localDataSource.setCategoryDownloaded(category, true);
      await localDataSource.setCategorySize(category, 100); // Mock size
      await loadOfflineDataStatus();
    } catch (e) {
      emit(OfflineDataError(e.toString()));
    }
  }

  Future<void> clearCache() async {
    try {
      // Clear cache logic here
      await loadOfflineDataStatus();
    } catch (e) {
      emit(OfflineDataError(e.toString()));
    }
  }

  Future<void> deleteAllOfflineData() async {
    try {
      await localDataSource.clearAllOfflineData();
      await loadOfflineDataStatus();
    } catch (e) {
      emit(OfflineDataError(e.toString()));
    }
  }
}


