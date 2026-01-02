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
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/contents');
          }
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/contents');
            }
          },
        ),
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
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: theme.colorScheme.secondary,
                    ),
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
              onTap: () => _showComingSoonDialog(context),
              isLocked: true,
            ),
            _buildAdminCard(
              context,
              title: 'Manage Medical Codes',
              icon: Icons.medical_services_outlined,
              onTap: () => _showComingSoonDialog(context),
              isLocked: true,
            ),
            _buildAdminCard(
              context,
              title: 'Import Codes',
              icon: Icons.upload_file_outlined,
              onTap: () => _showComingSoonDialog(context),
              isLocked: true,
            ),
            _buildAdminCard(
              context,
              title: 'Import All',
              icon: Icons.upload_outlined,
              onTap: () => context.push('/admin/import-all'),
            ),
          ];

          // Add super-admin only cards
          if (isSuperAdmin) {
            cards.add(
              _buildAdminCard(
                context,
                title: 'Manage Specialities',
                icon: Icons.badge_outlined,
                onTap: () => context.push('/admin/specialities'),
              ),
            );
            cards.add(
              _buildAdminCard(
                context,
                title: 'Manage Hospitals',
                icon: Icons.local_hospital_outlined,
                onTap: () => context.push('/admin/hospitals'),
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
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (isDark 
                        ? theme.colorScheme.secondary.withOpacity(0.2) 
                        : DesignTokens.primaryLight.withOpacity(0.2)),
                    child: Icon(
                      icon,
                      size: 36,
                      color: isLocked 
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked 
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (isLocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outlined,
                    size: 32,
                    color: DesignTokens.primaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Coming Soon',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This feature is currently under development and will be available in a future update.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
