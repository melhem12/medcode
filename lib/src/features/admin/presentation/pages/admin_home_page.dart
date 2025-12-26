import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/user_type_rules.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E), // Dark blue
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                final isSuperAdmin = UserTypeRules.isSuperAdmin(
                  authState.user.userType,
                  authState.user.adminSubType,
                );

                if (isSuperAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    color: DesignTokens.primary, // Teal color
                    tooltip: 'Super Admin',
                    onPressed: () {
                      // Super admin actions can be added here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Super Admin Panel'),
                        ),
                      );
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isSuperAdmin = authState is AuthAuthenticated &&
              UserTypeRules.isSuperAdmin(
                authState.user.userType,
                authState.user.adminSubType,
              );

          final List<Widget> cards = [
            _buildAdminCard(
              context,
              title: 'Manage Contents',
              icon: Icons.folder_outlined,
              onTap: () => context.go('/admin/contents'),
            ),
            _buildAdminCard(
              context,
              title: 'Manage Medical Codes',
              icon: Icons.medical_services_outlined,
              onTap: () => context.go('/admin/medical-codes'),
            ),
            _buildAdminCard(
              context,
              title: 'Import Codes',
              icon: Icons.upload_file_outlined,
              onTap: () => context.go('/admin/import'),
            ),
          ];

          // Add super-admin only cards
          if (isSuperAdmin) {
            cards.add(
              _buildAdminCard(
                context,
                title: 'Manage Specialities',
                icon: Icons.badge_outlined,
                onTap: () => context.go('/admin/specialities'),
              ),
            );
            cards.add(
              _buildAdminCard(
                context,
                title: 'Manage Hospitals',
                icon: Icons.local_hospital_outlined,
                onTap: () => context.go('/admin/hospitals'),
              ),
            );
          }

          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: cards,
          );
        },
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: DesignTokens.primaryLight.withOpacity(0.2),
                child: Icon(
                  icon,
                  size: 36,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
