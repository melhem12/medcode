import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../medical_codes/presentation/bloc/code_list_bloc.dart';
import '../../../medical_codes/presentation/widgets/medical_code_list_tile.dart';
import '../cubit/admin_medical_code_crud_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;

class ManageMedicalCodesPage extends StatelessWidget {
  const ManageMedicalCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminMedicalCodeCrudCubit>(
      create: (_) => di.sl<AdminMedicalCodeCrudCubit>(),
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
        child: BlocBuilder<CodeListBloc, CodeListState>(
          builder: (context, state) {
            if (state is CodeListLoading && state is! CodeListLoadingMore) {
              return const LoadingIndicator(
                message: 'Loading medical codes...',
              );
            }

            if (state is CodeListError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<CodeListBloc>().add(const LoadMedicalCodesEvent());
                },
              );
            }

            if (state is CodeListLoaded || state is CodeListLoadingMore) {
              final codes = state is CodeListLoaded
                  ? state.codes
                  : (state as CodeListLoadingMore).codes;

              if (codes.isEmpty) {
                return const Center(child: Text('No medical codes available'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: codes.length,
                itemBuilder: (context, index) {
                  final code = codes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: MedicalCodeListTile(
                      code: code,
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

            return const SizedBox.shrink();
          },
        ),
      ),
      ),
    );
  }
}
