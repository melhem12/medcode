import 'package:equatable/equatable.dart';

abstract class OfflineDataState extends Equatable {
  const OfflineDataState();

  @override
  List<Object> get props => [];
}

class OfflineDataInitial extends OfflineDataState {}

class OfflineDataLoading extends OfflineDataState {}

class OfflineDataLoaded extends OfflineDataState {
  final Map<String, dynamic> syncStatus;
  final List<String> downloadedCategories;

  const OfflineDataLoaded({
    required this.syncStatus,
    required this.downloadedCategories,
  });

  @override
  List<Object> get props => [syncStatus, downloadedCategories];
}

class OfflineDataError extends OfflineDataState {
  final String message;

  const OfflineDataError(this.message);

  @override
  List<Object> get props => [message];
}








