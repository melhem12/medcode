import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../medical_codes/presentation/widgets/medical_code_list_tile.dart';
import '../../../medical_codes/domain/entities/medical_code.dart';
import '../../../contents/presentation/cubit/contents_cubit.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../cubit/admin_medical_code_crud_cubit.dart';
import '../cubit/admin_medical_codes_list_cubit.dart';

class ManageMedicalCodesPage extends StatefulWidget {
  const ManageMedicalCodesPage({super.key});

  @override
  State<ManageMedicalCodesPage> createState() => _ManageMedicalCodesPageState();
}

class _ManageMedicalCodesPageState extends State<ManageMedicalCodesPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminMedicalCodesListCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
        title: const Text('Manage Medical Codes'),
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
        actions: [
          BlocBuilder<AdminMedicalCodeCrudCubit, AdminMedicalCodeCrudState>(
            builder: (context, state) {
              if (state is AdminMedicalCodeCrudLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  context.read<AdminMedicalCodeCrudCubit>().export();
                },
                tooltip: 'Export Medical Codes',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search codes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AdminMedicalCodesListCubit>().search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {}); // Update clear button visibility
                context.read<AdminMedicalCodesListCubit>().search(value);
              },
            ),
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AdminMedicalCodeCrudCubit, AdminMedicalCodeCrudState>(
            listener: (context, state) {
              if (state is AdminMedicalCodeExported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported to: ${state.displayPath}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is AdminMedicalCodeCrudSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                // Refresh the list
                context.read<AdminMedicalCodesListCubit>().refresh();
              } else if (state is AdminMedicalCodeCrudDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medical code deleted successfully')),
                );
                // Refresh the list
                context.read<AdminMedicalCodesListCubit>().refresh();
              } else if (state is AdminMedicalCodeCrudError) {
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
        child: BlocBuilder<AdminMedicalCodesListCubit, AdminMedicalCodesListState>(
          builder: (context, state) {
            if (state.status == AdminMedicalCodesListStatus.loading) {
              return const LoadingIndicator(
                message: 'Loading medical codes...',
              );
            }

            if (state.status == AdminMedicalCodesListStatus.error) {
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load medical codes',
                onRetry: () {
                  context.read<AdminMedicalCodesListCubit>().loadMedicalCodes();
                },
              );
            }

            return Column(
              children: [
                // Header with count and add button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${state.total} codes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showMedicalCodeForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Code'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: state.codes.isEmpty
                      ? const Center(child: Text('No medical codes found'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AdminMedicalCodesListCubit>().refresh();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.codes.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.codes.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final code = state.codes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: MedicalCodeListTile(
                                  code: code,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showMedicalCodeForm(context, code: code),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _confirmDelete(context, code.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Pagination info
                if (state.codes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[100],
                    child: Text(
                      'Page ${state.currentPage} of ${state.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  // Helper to find content and its parent in tree
  ContentNode? _findContentById(List<ContentNode> contents, String id) {
    for (final content in contents) {
      if (content.id == id) return content;
      if (content.children.isNotEmpty) {
        final found = _findContentById(content.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  // Find parent content that contains a child with given id
  ContentNode? _findParentContent(List<ContentNode> contents, String childId) {
    for (final content in contents) {
      for (final child in content.children) {
        if (child.id == childId) return content;
        final found = _findParentContent([child], childId);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _showMedicalCodeForm(BuildContext context, {MedicalCode? code}) {
    final codeController = TextEditingController(text: code?.code ?? '');
    final descriptionController = TextEditingController(text: code?.description ?? '');
    final categoryController = TextEditingController(text: code?.category ?? '');
    final bodySystemController = TextEditingController(text: code?.bodySystem ?? '');
    final sourceFileController = TextEditingController(text: '');
    
    // Get root contents from cubit for dropdown
    final contentsState = context.read<ContentsCubit>().state;
    List<ContentNode> rootContents = [];
    if (contentsState is ContentsLoaded) {
      rootContents = contentsState.contents;
    }
    bool parentExists(String? id) =>
        id != null && rootContents.any((c) => c.id == id);

    // Initialize selected values based on existing code
    String? initialParentId;
    String? initialSubcategoryId;

    if (code?.contentId != null) {
      // Check if contentId is a root content or a subcategory
      final content = _findContentById(rootContents, code!.contentId!);
      if (content != null) {
        // Check if this content is a root level item
        final isRoot = rootContents.any((c) => c.id == code.contentId);
        if (isRoot) {
          initialParentId = code.contentId;
          initialSubcategoryId = null;
        } else {
          // It's a subcategory, find its parent
          final parent = _findParentContent(rootContents, code.contentId!);
          if (parent != null) {
            initialParentId = parent.id;
            initialSubcategoryId = code.contentId;
          }
        }
      }
    }
    // Ensure initial selections exist in the available options; otherwise reset to null
    if (!parentExists(initialParentId)) {
      initialParentId = null;
      initialSubcategoryId = null;
    }

    // Selected content (parent) and subcategory
    final selectedParentId = ValueNotifier<String?>(initialParentId);
    final selectedSubcategoryId = ValueNotifier<String?>(initialSubcategoryId);
    
    // Capture cubit reference before showing dialog
    final crudCubit = context.read<AdminMedicalCodeCrudCubit>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(code == null ? 'Add Medical Code' : 'Edit Medical Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodySystemController,
                decoration: const InputDecoration(
                  labelText: 'Body System',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Content (Parent) dropdown
              ValueListenableBuilder<String?>(
                valueListenable: selectedParentId,
                builder: (context, parentValue, _) {
                  final safeParentValue = parentExists(parentValue) ? parentValue : null;
                  return DropdownButtonFormField<String?>(
                    value: safeParentValue,
                    decoration: const InputDecoration(
                      labelText: 'Content Category',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (no category)'),
                      ),
                      ...rootContents.map((content) => DropdownMenuItem<String?>(
                        value: content.id,
                        child: Text(
                          content.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (newValue) {
                      selectedParentId.value = parentExists(newValue) ? newValue : null;
                      // Reset subcategory when parent changes
                      selectedSubcategoryId.value = null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Subcategory dropdown (only shown if parent has children)
              ValueListenableBuilder<String?>(
                valueListenable: selectedParentId,
                builder: (context, parentValue, _) {
                  if (parentValue == null) return const SizedBox.shrink();
                  
                  final selectedParent = _findContentById(rootContents, parentValue);
                  if (selectedParent == null || selectedParent.children.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return ValueListenableBuilder<String?>(
                    valueListenable: selectedSubcategoryId,
                    builder: (context, subcategoryValue, _) {
                      // Ensure selected value exists in children
                      final validSubcategoryValue = selectedParent.children
                          .any((c) => c.id == subcategoryValue) ? subcategoryValue : null;
                      
                      return DropdownButtonFormField<String?>(
                        value: validSubcategoryValue,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (use parent category)'),
                          ),
                          ...selectedParent.children.map((subcategory) => DropdownMenuItem<String?>(
                            value: subcategory.id,
                            child: Text(
                              subcategory.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (newValue) {
                          selectedSubcategoryId.value = newValue;
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sourceFileController,
                decoration: const InputDecoration(
                  labelText: 'Source File',
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
              if (codeController.text.trim().isEmpty || 
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code and description are required')),
                );
                return;
              }
              
              // Use subcategory if selected, otherwise use parent content
              final contentId = selectedSubcategoryId.value ?? selectedParentId.value;
              
              final data = <String, dynamic>{
                'code': codeController.text.trim(),
                'description': descriptionController.text.trim(),
                if (categoryController.text.trim().isNotEmpty)
                  'category': categoryController.text.trim(),
                if (bodySystemController.text.trim().isNotEmpty)
                  'body_system': bodySystemController.text.trim(),
                if (contentId != null)
                  'content_id': int.tryParse(contentId),
                if (sourceFileController.text.trim().isNotEmpty)
                  'source_file': sourceFileController.text.trim(),
              };
              
              Navigator.of(ctx).pop();
              
              if (code == null) {
                crudCubit.create(data);
              } else {
                crudCubit.update(code.id, data);
              }
            },
            child: Text(code == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    final crudCubit = context.read<AdminMedicalCodeCrudCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medical Code'),
        content: const Text('Are you sure you want to delete this medical code?'),
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
