import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/user_type_rules.dart';
import '../../presentation/cubit/admin_speciality_hospital_cubit.dart';
import '../../../../app/di/injection_container.dart' as di;
// TODO: Uncomment when HospitalsCubit is implemented
// import '../../../auth/presentation/cubit/hospitals_cubit.dart';

// Temporary stub classes until HospitalsCubit is implemented
class HospitalsCubit extends Cubit<HospitalsState> {
  HospitalsCubit() : super(HospitalsInitial());
  void loadHospitals() {}
}

abstract class HospitalsState {}

class HospitalsInitial extends HospitalsState {}

class HospitalsLoading extends HospitalsState {}

class HospitalsError extends HospitalsState {
  final String message;
  HospitalsError(this.message);
}

class HospitalsLoaded extends HospitalsState {
  final List<dynamic> hospitals;
  HospitalsLoaded(this.hospitals);
}

class ManageHospitalsPage extends StatefulWidget {
  const ManageHospitalsPage({super.key});

  @override
  State<ManageHospitalsPage> createState() => _ManageHospitalsPageState();
}

class _ManageHospitalsPageState extends State<ManageHospitalsPage> {
  @override
  void initState() {
    super.initState();
    context.read<HospitalsCubit>().loadHospitals();
  }

  void _openForm({int? id, String? name}) {
    final controller = TextEditingController(text: name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Add Hospital' : 'Edit Hospital'),
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
                await context
                    .read<AdminSpecialityHospitalCubit>()
                    .addHospital(controller.text.trim());
              } else {
                await context
                    .read<AdminSpecialityHospitalCubit>()
                    .editHospital(id, controller.text.trim());
              }
              if (mounted) {
                Navigator.of(ctx).pop();
                context.read<HospitalsCubit>().loadHospitals();
              }
            },
            child: Text(id == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AdminSpecialityHospitalCubit>().removeHospital(id);
              if (mounted) {
                Navigator.of(ctx).pop();
                context.read<HospitalsCubit>().loadHospitals();
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
        appBar: AppBar(title: const Text('Manage Hospitals')),
        body: const Center(child: Text('Access denied')),
      );
    }

    return BlocProvider<HospitalsCubit>(
      create: (_) => HospitalsCubit(),
      child: BlocProvider<AdminSpecialityHospitalCubit>(
        create: (_) => di.sl<AdminSpecialityHospitalCubit>(),
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hospitals'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
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
          }
        },
        builder: (context, crudState) {
          return BlocBuilder<HospitalsCubit, HospitalsState>(
            builder: (context, state) {
              if (state is HospitalsLoading || state is HospitalsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is HospitalsError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HospitalsCubit>().loadHospitals(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is HospitalsLoaded) {
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.hospitals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.hospitals[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openForm(id: item.id, name: item.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(item.id),
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
    );
  }
}
