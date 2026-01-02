import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../contents/presentation/cubit/contents_cubit.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../../../contents/data/datasources/contents_local_data_source.dart';
import '../cubit/admin_content_crud_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;

class ManageContentsPage extends StatefulWidget {
  const ManageContentsPage({super.key});

  @override
  State<ManageContentsPage> createState() => _ManageContentsPageState();
}

class _ManageContentsPageState extends State<ManageContentsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure contents load when landing on this page so empty state can render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentsCubit = context.read<ContentsCubit>();
      final state = contentsCubit.state;
      if (state is! ContentsLoaded) {
        contentsCubit.fetchContents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminContentCrudCubit>(
      create: (_) => di.sl<AdminContentCrudCubit>(),
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
          title: const Text('Manage Contents'),
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/home');
              }
            },
          ),
        actions: [
          BlocBuilder<AdminContentCrudCubit, AdminContentCrudState>(
            builder: (context, state) {
              if (state is AdminContentCrudLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () => _pickAndImportFile(context),
                    tooltip: 'Import Contents (.xlsx, .xls, .csv)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      context.read<AdminContentCrudCubit>().export();
                    },
                    tooltip: 'Export Contents',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AdminContentCrudCubit, AdminContentCrudState>(
            listener: (context, state) async {
              if (state is AdminContentExported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported to: ${state.displayPath}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is AdminContentImported) {
                // Clear local cache to ensure fresh data
                try {
                  final localDataSource = di.sl<ContentsLocalDataSource>();
                  await localDataSource.cacheContents([]); // Clear cache
                } catch (e) {
                  debugPrint('Error clearing contents cache: $e');
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Import successful!\n'
                      'Imported: ${state.result.imported}\n'
                      'Updated: ${state.result.updated}\n'
                      'Skipped: ${state.result.skipped}',
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
                // Reload contents after import
                context.read<ContentsCubit>().fetchContents();
              } else if (state is AdminContentCrudError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AdminContentCrudCubit, AdminContentCrudState>(
              listener: (context, state) {
                if (state is AdminContentCrudSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  context.read<ContentsCubit>().fetchContents();
                } else if (state is AdminContentCrudDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content deleted successfully')),
                  );
                  context.read<ContentsCubit>().fetchContents();
                }
              },
            ),
          ],
          child: BlocBuilder<ContentsCubit, ContentsState>(
            builder: (context, state) {
              if (state is ContentsLoading || state is ContentsInitial) {
                return const LoadingIndicator(message: 'Loading contents...');
              }

              if (state is ContentsError) {
                return ErrorView(
                  message: state.message,
                  onRetry: () {
                    context.read<ContentsCubit>().fetchContents();
                  },
                );
              }

              if (state is ContentsLoaded) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _showContentForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Content'),
                      ),
                    ),
                    Expanded(child: _buildContentsList(context, state.contents)),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
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
      context.read<AdminContentCrudCubit>().import(filePath);
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

  Widget _buildContentsList(BuildContext context, List<ContentNode> contents) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No contents available'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final content = contents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(content.title),
            subtitle: Text('Level: ${content.level}${content.parentId != null ? ' (Parent: ${content.parentId})' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showContentForm(context, content: content),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, content.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContentForm(BuildContext context, {ContentNode? content}) {
    final titleController = TextEditingController(text: content?.title ?? '');
    final sectionLabelController = TextEditingController(text: content?.sectionLabel ?? '');
    final pageMarkerController = TextEditingController(text: content?.pageMarker ?? '');
    final codeHintController = TextEditingController(text: content?.codeHint ?? '');
    
    String? selectedLevel = content?.level ?? 'section';
    int? selectedParentId = content?.parentId;
    
    // Get flat list of sections for parent selection
    final sections = _getSections(context);
    
    // Capture cubit reference before showing dialog
    final crudCubit = context.read<AdminContentCrudCubit>();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(content == null ? 'Add Content' : 'Edit Content'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Level *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'section', child: Text('Section')),
                    DropdownMenuItem(value: 'subcategory', child: Text('Subcategory')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLevel = value;
                      if (value == 'section') {
                        selectedParentId = null; // Sections can't have parents
                      }
                    });
                  },
                ),
                if (selectedLevel == 'subcategory') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedParentId,
                    decoration: const InputDecoration(
                      labelText: 'Parent Section',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      ...sections.map((s) => DropdownMenuItem<int?>(
                        value: int.tryParse(s.id),
                        child: Text(s.title),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedParentId = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: sectionLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Section Label',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pageMarkerController,
                  decoration: const InputDecoration(
                    labelText: 'Page Marker',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeHintController,
                  decoration: const InputDecoration(
                    labelText: 'Code Hint',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty || selectedLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and level are required')),
                  );
                  return;
                }
                
                final data = <String, dynamic>{
                  'title': titleController.text.trim(),
                  'level': selectedLevel,
                  if (sectionLabelController.text.trim().isNotEmpty)
                    'section_label': sectionLabelController.text.trim(),
                  if (pageMarkerController.text.trim().isNotEmpty)
                    'page_marker': pageMarkerController.text.trim(),
                  if (codeHintController.text.trim().isNotEmpty)
                    'code_hint': codeHintController.text.trim(),
                  if (selectedParentId != null) 'parent_id': selectedParentId,
                };
                
                Navigator.of(ctx).pop();
                
                if (content == null) {
                  crudCubit.create(data);
                } else {
                  crudCubit.update(content.id, data);
                }
              },
              child: Text(content == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  List<ContentNode> _getSections(BuildContext context) {
    final contentsState = context.read<ContentsCubit>().state;
    if (contentsState is ContentsLoaded) {
      return _flattenContents(contentsState.contents)
          .where((c) => c.level == 'section')
          .toList();
    }
    return [];
  }

  List<ContentNode> _flattenContents(List<ContentNode> contents) {
    final List<ContentNode> result = [];
    for (final content in contents) {
      result.add(content);
      if (content.children.isNotEmpty) {
        result.addAll(_flattenContents(content.children));
      }
    }
    return result;
  }

  void _confirmDelete(BuildContext context, String id) {
    final crudCubit = context.read<AdminContentCrudCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              crudCubit.delete(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
