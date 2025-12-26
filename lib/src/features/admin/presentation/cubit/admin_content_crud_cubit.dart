import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../../../contents/domain/usecases/manage_contents_usecases.dart';
import '../../../../core/utils/file_export_helper.dart';

part 'admin_content_crud_state.dart';

class AdminContentCrudCubit extends Cubit<AdminContentCrudState> {
  final ExportContentsUseCase exportUseCase;

  AdminContentCrudCubit({required this.exportUseCase})
      : super(AdminContentCrudInitial());

  Future<void> export() async {
    emit(AdminContentCrudLoading());
    try {
      final rows = await exportUseCase();
      final filePath = await FileExportHelper.exportToCsv(
        data: rows,
        fileName: 'contents',
      );
      final displayPath = FileExportHelper.getDisplayPath(filePath);
      emit(AdminContentExported(rows, filePath, displayPath));
    } catch (e) {
      emit(AdminContentCrudError(e.toString()));
    }
  }
}

