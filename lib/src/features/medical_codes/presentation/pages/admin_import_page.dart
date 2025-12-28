import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../cubit/admin_import_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;

class AdminImportPage extends StatelessWidget {
  final String? contentId;

  const AdminImportPage({super.key, this.contentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider<AdminImportCubit>(
      create: (_) => di.sl<AdminImportCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Medical Codes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/home');
              }
            },
          ),
        ),
        body: BlocConsumer<AdminImportCubit, AdminImportState>(
          listener: (context, state) {
            if (state is AdminImportSuccess) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Import Complete'),
                  content: Text(
                    'Imported: ${state.result.imported}\n'
                    'Updated: ${state.result.updated}\n'
                    'Skipped: ${state.result.skipped}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            } else if (state is AdminImportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AdminImportLoading) {
              return const LoadingIndicator(
                message: 'Importing medical codes...',
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.upload_file,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Import Medical Codes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an Excel file to import medical codes',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Supported: .xlsx, .xls'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndImportFile(context),
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      context.read<AdminImportCubit>().import(filePath, contentId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }
}
