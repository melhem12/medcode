import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/offline_data_local_data_source.dart';
import 'offline_data_state.dart';
import '../../../medical_codes/data/datasources/medical_codes_local_data_source.dart';
import '../../../medical_codes/data/datasources/medical_codes_remote_data_source.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../contents/data/datasources/contents_local_data_source.dart';
import '../../../contents/data/datasources/contents_remote_data_source.dart';

class OfflineDataCubit extends Cubit<OfflineDataState> {
  final OfflineDataLocalDataSource localDataSource;
  final MedicalCodesLocalDataSource medicalCodesLocalDataSource;
  final MedicalCodesRemoteDataSource medicalCodesRemoteDataSource;
  final ContentsLocalDataSource contentsLocalDataSource;
  final ContentsRemoteDataSource contentsRemoteDataSource;

  OfflineDataCubit({
    required this.localDataSource,
    required this.medicalCodesLocalDataSource,
    required this.medicalCodesRemoteDataSource,
    required this.contentsLocalDataSource,
    required this.contentsRemoteDataSource,
  }) : super(OfflineDataInitial()) {
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
        'is_syncing': true,
      });

      // Download all medical codes with pagination
      List<MedicalCode> allCodes = [];
      int page = 1;
      bool hasMore = true;
      
      while (hasMore) {
        final codes = await medicalCodesRemoteDataSource.getMedicalCodes(
          page: page,
        );
        allCodes.addAll(codes);
        hasMore = codes.length == 20; // If we got less than 20, we're done
        page++;
      }

      // Cache all medical codes
      await medicalCodesLocalDataSource.cacheMedicalCodes(allCodes);

      // Download all contents
      final contents = await contentsRemoteDataSource.getContents();
      await contentsLocalDataSource.cacheContents(contents);

      // Update sync status
      await localDataSource.setSyncStatus({
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': false,
        'total_codes': allCodes.length,
        'total_contents': contents.length,
      });

      await loadOfflineDataStatus();
    } catch (e) {
      await localDataSource.setSyncStatus({
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': false,
        'error': e.toString(),
      });
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


