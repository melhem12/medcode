part of 'admin_medical_codes_list_cubit.dart';

enum AdminMedicalCodesListStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class AdminMedicalCodesListState extends Equatable {
  final AdminMedicalCodesListStatus status;
  final List<MedicalCode> codes;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;
  final String? currentSearch;
  final String? currentContentId;
  final String? errorMessage;

  const AdminMedicalCodesListState({
    this.status = AdminMedicalCodesListStatus.initial,
    this.codes = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasMore = false,
    this.currentSearch,
    this.currentContentId,
    this.errorMessage,
  });

  AdminMedicalCodesListState copyWith({
    AdminMedicalCodesListStatus? status,
    List<MedicalCode>? codes,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? hasMore,
    String? currentSearch,
    String? currentContentId,
    String? errorMessage,
  }) {
    return AdminMedicalCodesListState(
      status: status ?? this.status,
      codes: codes ?? this.codes,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      currentSearch: currentSearch ?? this.currentSearch,
      currentContentId: currentContentId ?? this.currentContentId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        codes,
        currentPage,
        totalPages,
        total,
        hasMore,
        currentSearch,
        currentContentId,
        errorMessage,
      ];
}



















