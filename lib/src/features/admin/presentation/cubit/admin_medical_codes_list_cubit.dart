import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../medical_codes/data/models/medical_code_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';

part 'admin_medical_codes_list_state.dart';

class AdminMedicalCodesListCubit extends Cubit<AdminMedicalCodesListState> {
  final DioClient dioClient;

  AdminMedicalCodesListCubit({required this.dioClient})
      : super(const AdminMedicalCodesListState());

  Future<void> loadMedicalCodes({
    int page = 1,
    String? search,
    String? contentId,
    bool refresh = false,
  }) async {
    if (isClosed) return;

    // If refreshing, reset to page 1
    final targetPage = refresh ? 1 : page;

    emit(state.copyWith(
      status: targetPage == 1
          ? AdminMedicalCodesListStatus.loading
          : AdminMedicalCodesListStatus.loadingMore,
      currentSearch: search,
      currentContentId: contentId,
    ));

    try {
      final queryParams = <String, dynamic>{
        'page': targetPage,
        'per_page': 20,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (contentId != null && contentId.isNotEmpty) {
        queryParams['content_id'] = contentId;
      }

      final response = await dioClient.dio.get(
        '/admin/medical-codes',
        queryParameters: queryParams,
      );

      if (isClosed) return;

      final data = response.data as Map<String, dynamic>;
      final codesJson = data['data'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final codes = codesJson
          .map((e) => MedicalCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final currentPage = pagination['page'] as int? ?? 1;
      final totalPages = pagination['total_pages'] as int? ?? 1;
      final total = pagination['total'] as int? ?? codes.length;

      // If loading more, append to existing codes
      final allCodes = targetPage == 1 ? codes : [...state.codes, ...codes];

      emit(state.copyWith(
        status: AdminMedicalCodesListStatus.loaded,
        codes: allCodes,
        currentPage: currentPage,
        totalPages: totalPages,
        total: total,
        hasMore: currentPage < totalPages,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AdminMedicalCodesListStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AdminMedicalCodesListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.status == AdminMedicalCodesListStatus.loadingMore) return;
    if (!state.hasMore) return;

    await loadMedicalCodes(
      page: state.currentPage + 1,
      search: state.currentSearch,
      contentId: state.currentContentId,
    );
  }

  Future<void> refresh() async {
    await loadMedicalCodes(
      page: 1,
      search: state.currentSearch,
      contentId: state.currentContentId,
      refresh: true,
    );
  }

  void search(String query) {
    loadMedicalCodes(
      page: 1,
      search: query.isEmpty ? null : query,
      contentId: state.currentContentId,
      refresh: true,
    );
  }
}


