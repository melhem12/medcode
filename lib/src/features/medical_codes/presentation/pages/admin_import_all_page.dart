import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../cubit/admin_import_all_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../data/datasources/medical_codes_local_data_source.dart';
import '../../domain/usecases/import_all_medical_codes_usecase.dart';

class AdminImportAllPage extends StatefulWidget {
  const AdminImportAllPage({super.key});

  @override
  State<AdminImportAllPage> createState() => _AdminImportAllPageState();
}

class _AdminImportAllPageState extends State<AdminImportAllPage> {
  String? _medicalCodesFilePath;
  String? _contentsFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          final cubit = context.read<AdminImportAllCubit>();
          if (!cubit.isClosed && cubit.state is! AdminImportAllLoading) {
            cubit.reset();
          }
        } catch (e) {
          debugPrint('Could not reset cubit in initState: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider<AdminImportAllCubit>(
      create: (_) => AdminImportAllCubit(
        importAllMedicalCodesUseCase: di.sl<ImportAllMedicalCodesUseCase>(),
      ),
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (!didPop) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/home');
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Import All'),
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
          body: BlocConsumer<AdminImportAllCubit, AdminImportAllState>(
            listener: (context, state) async {
              if (state is AdminImportAllSuccess) {
                try {
                  final localDataSource = di.sl<MedicalCodesLocalDataSource>();
                  await localDataSource.cacheMedicalCodes([]);
                } catch (e) {
                  debugPrint('Error clearing cache: $e');
                }

                final shouldRefresh = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Import Complete'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medical Codes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Imported: ${state.result.medicalCodes.imported}\n'
                            'Updated: ${state.result.medicalCodes.updated}\n'
                            'Skipped: ${state.result.medicalCodes.skipped}',
                          ),
                          if (state.result.contents != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Contents:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Imported: ${state.result.contents!.imported}\n'
                              'Updated: ${state.result.contents!.updated}\n'
                              'Skipped: ${state.result.contents!.skipped}',
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              'Contents: Extracted from medical codes file',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ) ?? true;

                if (context.mounted) {
                  try {
                    final cubit = context.read<AdminImportAllCubit>();
                    if (!cubit.isClosed) {
                      cubit.reset();
                    }
                  } catch (e) {
                    debugPrint('Could not reset cubit after success: $e');
                  }
                }

                if (shouldRefresh && context.mounted) {
                  context.go('/admin/home');
                }
              } else if (state is AdminImportAllError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                if (context.mounted) {
                  try {
                    final cubit = context.read<AdminImportAllCubit>();
                    if (!cubit.isClosed) {
                      cubit.reset();
                    }
                  } catch (e) {
                    debugPrint('Could not reset cubit after error: $e');
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is AdminImportAllLoading) {
                return const LoadingIndicator(
                  message: 'Importing all data...',
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Import All',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Import medical codes and contents from Excel files. Contents can be extracted from the medical codes file if it contains section hierarchy data (Section_Detected, Subsection_Detected, etc.).',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: This will delete all existing medical codes and contents!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFileSelector(
                      context,
                      label: 'Medical Codes File (Required)',
                      filePath: _medicalCodesFilePath,
                      onFileSelected: (path) {
                        setState(() {
                          _medicalCodesFilePath = path;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFileSelector(
                      context,
                      label: 'Contents File (Optional)',
                      filePath: _contentsFilePath,
                      onFileSelected: (path) {
                        setState(() {
                          _contentsFilePath = path;
                        });
                      },
                      isOptional: true,
                    ),
                    if (_medicalCodesFilePath != null && _contentsFilePath == null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Contents will be extracted from the medical codes file if it contains section hierarchy columns.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _medicalCodesFilePath != null
                            ? () => _importAll(context)
                            : null,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import All'),
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
      ),
    );
  }

  Widget _buildFileSelector(
    BuildContext context, {
    required String label,
    String? filePath,
    required Function(String?) onFileSelected,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFile(context, onFileSelected),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  filePath != null ? Icons.check_circle : Icons.description_outlined,
                  color: filePath != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    filePath != null
                        ? filePath.split('/').last
                        : isOptional
                            ? 'No file selected (optional)'
                            : 'Select file...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: filePath != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (filePath != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onFileSelected(null),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    Function(String?) onFileSelected,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.single;
      String? filePath;

      if (picked.bytes != null && picked.bytes!.isNotEmpty) {
        filePath = await _savePickedFile(picked);
      }

      if (filePath == null && picked.path != null && picked.path!.isNotEmpty) {
        if (picked.path!.startsWith('content://')) {
          filePath = await _readContentUriToTemp(picked);
        } else {
          try {
            final file = File(picked.path!);
            if (await file.exists()) {
              filePath = picked.path;
            }
          } catch (e) {
            debugPrint('Error checking file path: $e');
          }
        }
      }

      if (filePath != null) {
        final finalFile = File(filePath);
        if (await finalFile.exists()) {
          onFileSelected(filePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found. Please try selecting the file again.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access file. Please try selecting the file again.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _readContentUriToTemp(PlatformFile picked) async {
    try {
      if (picked.path == null || !picked.path!.startsWith('content://')) {
        return null;
      }

      try {
        final sourceFile = File(picked.path!);
        final bytes = await sourceFile.readAsBytes();

        if (bytes.isEmpty) {
          return null;
        }

        final tempDir = await getTemporaryDirectory();
        final fileName = picked.name.isNotEmpty
            ? picked.name
            : 'import_file.${picked.extension ?? 'xlsx'}';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = '${timestamp}_$fileName';
        final destFile = File('${tempDir.path}/$uniqueFileName');

        await destFile.writeAsBytes(bytes, flush: true);
        return destFile.path;
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> _savePickedFile(PlatformFile picked) async {
    try {
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = picked.name.isNotEmpty
          ? picked.name
          : 'import_file.${picked.extension ?? 'xlsx'}';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final file = File('${tempDir.path}/$uniqueFileName');

      await file.writeAsBytes(bytes, flush: true);

      if (await file.exists()) {
        return file.path;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _importAll(BuildContext context) async {
    if (_medicalCodesFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medical codes file'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import All'),
        content: const Text(
          'This will delete all existing medical codes and contents. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final contentsPath = _contentsFilePath != null && 
          _contentsFilePath!.isNotEmpty 
          ? _contentsFilePath 
          : null;
      
      debugPrint('🚀 Starting import all...');
      debugPrint('📄 Medical codes file: $_medicalCodesFilePath');
      debugPrint('📄 Contents file: $contentsPath');
      
      context.read<AdminImportAllCubit>().importAll(
            medicalCodesFilePath: _medicalCodesFilePath!,
            contentsFilePath: contentsPath,
          );
    }
  }
}

