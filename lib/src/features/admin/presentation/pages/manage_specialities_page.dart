import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/user_type_rules.dart';
import '../../presentation/cubit/admin_speciality_hospital_cubit.dart';
import '../../presentation/cubit/specialities_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;

class ManageSpecialitiesPage extends StatefulWidget {
  const ManageSpecialitiesPage({super.key});

  @override
  State<ManageSpecialitiesPage> createState() => _ManageSpecialitiesPageState();
}

class _ManageSpecialitiesPageState extends State<ManageSpecialitiesPage> {
  @override
  void initState() {
    super.initState();
  }

  void _openForm(BuildContext providerContext, {int? id, String? name}) {
    final controller = TextEditingController(text: name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Add Speciality' : 'Edit Speciality'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              if (id == null) {
                await providerContext
                    .read<AdminSpecialityHospitalCubit>()
                    .addSpeciality(controller.text.trim());
              } else {
                await providerContext
                    .read<AdminSpecialityHospitalCubit>()
                    .editSpeciality(id, controller.text.trim());
              }
              if (mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text(id == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext providerContext, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Speciality'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await providerContext.read<AdminSpecialityHospitalCubit>().removeSpeciality(id);
              if (mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated &&
        UserTypeRules.isAdmin(authState.user.userType, authState.user.adminSubType);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Specialities')),
        body: const Center(child: Text('Access denied')),
      );
    }

    return BlocProvider<SpecialitiesCubit>(
      create: (_) => di.sl<SpecialitiesCubit>(),
      child: BlocProvider<AdminSpecialityHospitalCubit>(
        create: (_) => di.sl<AdminSpecialityHospitalCubit>(),
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
          child: Builder(
            builder: (providerContext) => Scaffold(
      appBar: AppBar(
        title: const Text('Manage Specialities'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/home');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(providerContext),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<AdminSpecialityHospitalCubit, AdminSpecialityHospitalState>(
        listener: (context, state) {
          if (state is AdminSpecialityHospitalError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AdminSpecialityHospitalSuccess ||
              state is AdminSpecialityHospitalDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state is AdminSpecialityHospitalSuccess
                    ? state.message
                    : (state as AdminSpecialityHospitalDeleted).message),
              ),
            );
            // Reload specialities after successful operation
            context.read<SpecialitiesCubit>().loadSpecialities();
          }
        },
        builder: (context, crudState) {
          return BlocBuilder<SpecialitiesCubit, SpecialitiesState>(
            builder: (context, state) {
              // Load specialities when state is initial
              if (state is SpecialitiesInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<SpecialitiesCubit>().loadSpecialities();
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SpecialitiesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SpecialitiesError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<SpecialitiesCubit>().loadSpecialities(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is SpecialitiesLoaded) {
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.specialities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.specialities[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openForm(context, id: item.id, name: item.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(context, item.id),
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
          );
        },
      ),
            ),
          ),
        ),
      ),
    );
  }
}
