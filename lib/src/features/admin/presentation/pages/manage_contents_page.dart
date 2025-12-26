import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../contents/presentation/cubit/contents_cubit.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../cubit/admin_content_crud_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;

class ManageContentsPage extends StatelessWidget {
  const ManageContentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminContentCrudCubit>(
      create: (_) => di.sl<AdminContentCrudCubit>(),
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Manage Contents'),
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
              return IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  context.read<AdminContentCrudCubit>().export();
                },
                tooltip: 'Export Contents',
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AdminContentCrudCubit, AdminContentCrudState>(
            listener: (context, state) {
              if (state is AdminContentExported) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported to: ${state.displayPath}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
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
              return _buildContentsList(context, state.contents);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      ),
    );
  }

  Widget _buildContentsList(BuildContext context, List<ContentNode> contents) {
    if (contents.isEmpty) {
      return const Center(child: Text('No contents available'));
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
            subtitle: Text('Level: ${content.level}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Edit functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // Delete functionality
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
