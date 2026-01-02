import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../cubit/admin_import_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../data/datasources/medical_codes_local_data_source.dart';
import '../../domain/usecases/import_medical_codes_usecase.dart';

class AdminImportPage extends StatefulWidget {
  final String? contentId;

  const AdminImportPage({super.key, this.contentId});

  @override
  State<AdminImportPage> createState() => _AdminImportPageState();
}

class _AdminImportPageState extends State<AdminImportPage> {
  @override
  void initState() {
    super.initState();
    // Reset cubit state when page is initialized to allow multiple imports
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          final cubit = context.read<AdminImportCubit>();
          if (!cubit.isClosed && cubit.state is! AdminImportLoading) {
            cubit.reset();
          }
        } catch (e) {
          // Cubit might not be available yet, ignore
          debugPrint('Could not reset cubit in initState: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider<AdminImportCubit>(
      create: (_) => AdminImportCubit(
        importMedicalCodesUseCase: di.sl<ImportMedicalCodesUseCase>(),
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
          listener: (context, state) async {
            if (state is AdminImportSuccess) {
              // Clear local cache to ensure fresh data
              try {
                final localDataSource = di.sl<MedicalCodesLocalDataSource>();
                await localDataSource.cacheMedicalCodes([]); // Clear cache
              } catch (e) {
                debugPrint('Error clearing cache: $e');
              }
              
              // Show success dialog
              final shouldRefresh = await showDialog<bool>(
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
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ) ?? true;
              
              // Reset cubit state immediately to allow another import
              // This must happen before navigation to ensure state is reset
              if (context.mounted) {
                try {
                  final cubit = context.read<AdminImportCubit>();
                  if (!cubit.isClosed) {
                    cubit.reset();
                  }
                } catch (e) {
                  debugPrint('Could not reset cubit after success: $e');
                }
              }
              
              // Navigate back - the manage page will refresh when route is rebuilt
              if (shouldRefresh && context.mounted) {
                // Always use go() to force route rebuild which will recreate the cubit and load fresh data
                context.go('/admin/medical-codes');
              } else if (context.mounted) {
                // If user stays on page, state is already reset, ready for next import
              }
            } else if (state is AdminImportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              // Reset state after showing error to allow retry
              if (context.mounted) {
                try {
                  final cubit = context.read<AdminImportCubit>();
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
                    'Select an Excel or CSV file to import medical codes',
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
                          child: Text('Supported: .xlsx, .xls, .csv'),
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
      ),
    );
  }

  Future<void> _pickAndImportFile(BuildContext context) async {
    try {
      debugPrint('📁 Starting file picker...');
      
      // Try withData first, fallback to withReadStream if needed
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('❌ No file selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      final picked = result.files.single;
      debugPrint('📄 File picked: name=${picked.name}, path=${picked.path}, size=${picked.size}, bytes=${picked.bytes?.length ?? 0}');
      
      String? filePath;

      // Strategy 1: Use bytes if available (most reliable)
      if (picked.bytes != null && picked.bytes!.isNotEmpty) {
        debugPrint('💾 Using bytes from file picker...');
        filePath = await _savePickedFile(picked);
        if (filePath != null) {
          debugPrint('✅ File saved from bytes: $filePath');
        }
      }

      // Strategy 2: Try using the path if bytes didn't work
      if (filePath == null && picked.path != null && picked.path!.isNotEmpty) {
        debugPrint('🔍 Trying to use file path: ${picked.path}');
        
        // Check if it's a content URI (Android)
        if (picked.path!.startsWith('content://')) {
          debugPrint('📱 Content URI detected, trying to read...');
          // Content URIs need special handling - try reading bytes from stream
          filePath = await _readContentUriToTemp(picked);
        } else {
          // Regular file path - check if it exists
          try {
            final file = File(picked.path!);
            if (await file.exists()) {
              debugPrint('✅ File exists at path: ${picked.path}');
              filePath = picked.path;
            } else {
              debugPrint('⚠️ File does not exist at path: ${picked.path}');
            }
          } catch (e) {
            debugPrint('⚠️ Error checking file path: $e');
          }
        }
      }

      if (filePath == null) {
        debugPrint('❌ Failed to get file path - all strategies failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access file. Please try selecting the file again.'),
          ),
        );
        return;
      }

      final finalFile = File(filePath);
      if (!await finalFile.exists()) {
        debugPrint('❌ File does not exist at final path: $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found. Please try selecting the file again.'),
          ),
        );
        return;
      }

      final fileSize = await finalFile.length();
      debugPrint('✅ File ready for import: $filePath (${fileSize} bytes)');
      context.read<AdminImportCubit>().import(filePath, widget.contentId);
    } catch (e, stackTrace) {
      debugPrint('❌ Error picking file: $e');
      debugPrint('Stack trace: $stackTrace');
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
      debugPrint('📋 Reading content URI to temp file...');
      
      if (picked.path == null || !picked.path!.startsWith('content://')) {
        return null;
      }

      // Try to read the file using the path
      try {
        final sourceFile = File(picked.path!);
        final bytes = await sourceFile.readAsBytes();
        
        if (bytes.isEmpty) {
          debugPrint('⚠️ Content URI file is empty');
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
        debugPrint('✅ Content URI read and saved to: ${destFile.path}');
        return destFile.path;
      } catch (e) {
        debugPrint('⚠️ Failed to read content URI: $e');
        // Content URIs can't be read directly with File() on Android
        // This is expected to fail, bytes should have been used instead
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error reading content URI: $e');
      return null;
    }
  }

  Future<String?> _savePickedFile(PlatformFile picked) async {
    try {
      debugPrint('💾 _savePickedFile: name=${picked.name}, size=${picked.size}');
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint('❌ File bytes are null or empty. bytes length: ${bytes?.length ?? 0}');
        return null;
      }

      debugPrint('📦 Bytes available: ${bytes.length} bytes');
      final tempDir = await getTemporaryDirectory();
      debugPrint('📂 Temp directory: ${tempDir.path}');
      
      final fileName = picked.name.isNotEmpty 
          ? picked.name 
          : 'import_file.${picked.extension ?? 'xlsx'}';
      
      // Ensure unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final file = File('${tempDir.path}/$uniqueFileName');
      
      debugPrint('💾 Writing file to: ${file.path}');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('✅ File written, checking existence...');
      
      // Verify file was written successfully
      if (await file.exists()) {
        final fileSize = await file.length();
        debugPrint('✅ File saved successfully: ${file.path}, size: $fileSize bytes');
        return file.path;
      } else {
        debugPrint('❌ File was not created at: ${file.path}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving picked file: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
