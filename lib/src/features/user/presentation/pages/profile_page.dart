import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/user_bloc.dart';
import '../cubit/theme_cubit.dart';
import '../cubit/offline_data_cubit.dart';
import '../cubit/offline_data_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingAvatar = false;
  Map<String, List<String>>? _fieldErrors;
  String? _localAvatarPath;
  String? _lastSyncTime;
  DateTime? _lastSyncDateTime;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserBloc>().add(const GetProfileEvent());
      _loadLastSyncTime();
    });
  }

  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final statusJson = prefs.getString('sync_status');
      if (statusJson != null) {
        final status = jsonDecode(statusJson) as Map<String, dynamic>;
        final lastSyncString = status['last_sync'] as String?;
        if (lastSyncString != null) {
          _lastSyncDateTime = DateTime.parse(lastSyncString);
          _updateSyncTimeDisplay();
          // Start timer to update display every minute
          _updateTimer?.cancel();
          _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
            if (mounted && _lastSyncDateTime != null) {
              _updateSyncTimeDisplay();
            }
          });
        } else {
          setState(() {
            _lastSyncTime = 'Never';
            _lastSyncDateTime = null;
          });
        }
      } else {
        setState(() {
          _lastSyncTime = 'Never';
          _lastSyncDateTime = null;
        });
      }
    } catch (e) {
      setState(() {
        _lastSyncTime = 'Never';
        _lastSyncDateTime = null;
      });
    }
  }

  void _updateSyncTimeDisplay() {
    if (_lastSyncDateTime != null && mounted) {
      setState(() {
        _lastSyncTime = _formatTimeAgo(_lastSyncDateTime!);
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  String? _getFieldError(String fieldName) {
    if (_fieldErrors == null) return null;
    final errors = _fieldErrors![fieldName];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  String _getAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final baseDomain = AppConfig.baseUrl.replaceAll('/api', '');
    return '$baseDomain$path';
  }

  String _formatUserType(String userType, String? adminSubType) {
    // Format user type for display
    switch (userType) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
      case 'administrative':
        if (adminSubType != null && adminSubType.isNotEmpty) {
          // Capitalize first letter of admin sub type
          final formattedSubType = adminSubType[0].toUpperCase() + 
              (adminSubType.length > 1 ? adminSubType.substring(1) : '');
          return 'Admin ($formattedSubType)';
        }
        return 'Admin';
      case 'resident':
        return 'Resident';
      case 'physician':
        return 'Physician';
      default:
        // Capitalize first letter and replace underscores with spaces
        return userType
            .split('_')
            .map((word) => word[0].toUpperCase() + 
                (word.length > 1 ? word.substring(1) : ''))
            .join(' ');
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _localAvatarPath = path;
        _isUploadingAvatar = true;
      });
      context.read<UserBloc>().add(UploadAvatarEvent(path));
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };
      if (_licenseController.text.trim().isNotEmpty) {
        payload['licence_number'] = _licenseController.text.trim();
      }
      context.read<UserBloc>().add(UpdateProfileEvent(payload));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditing,
      onPopInvoked: (didPop) {
        if (!didPop && _isEditing) {
          // If editing, cancel edit mode
          setState(() {
            _isEditing = false;
          });
          context.read<UserBloc>().add(const GetProfileEvent());
        }
        // Otherwise, let ExitConfirmationWrapper handle back navigation
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                  context.read<UserBloc>().add(const GetProfileEvent());
                },
              )
            : null,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, dynamic>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.go('/login');
              }
            },
          ),
          BlocListener<OfflineDataCubit, OfflineDataState>(
            listener: (context, state) {
              if (state is OfflineDataLoaded) {
                final lastSyncString = state.syncStatus['last_sync'] as String?;
                if (lastSyncString != null) {
                  _lastSyncDateTime = DateTime.parse(lastSyncString);
                  _updateSyncTimeDisplay();
                  // Restart timer to update display every minute
                  _updateTimer?.cancel();
                  _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
                    if (mounted && _lastSyncDateTime != null) {
                      _updateSyncTimeDisplay();
                    }
                  });
                } else {
                  setState(() {
                    _lastSyncTime = 'Never';
                    _lastSyncDateTime = null;
                  });
                  _updateTimer?.cancel();
                }
              }
            },
          ),
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state is UserLoaded) {
                if (!_isEditing) {
                  _nameController.text = state.user.name;
                  _emailController.text = state.user.email;
                  _licenseController.text = state.user.licenceNumber ?? '';
                  _localAvatarPath = null;
                } else {
                  setState(() {
                    _isEditing = false;
                    _fieldErrors = null;
                    _localAvatarPath = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                }
                setState(() {
                  _isUploadingAvatar = false;
                });
              } else if (state is UserValidationError) {
                setState(() {
                  _fieldErrors = state.fieldErrors;
                  _isUploadingAvatar = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else if (state is UserError) {
                setState(() {
                  _isUploadingAvatar = false;
                });
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
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading && !_isEditing) {
              return const LoadingIndicator(message: 'Loading profile...');
            }

            if (state is UserError && !_isEditing) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<UserBloc>().add(const GetProfileEvent());
                },
              );
            }

            if (state is UserLoaded || _isEditing) {
              final user = state is UserLoaded ? state.user : null;

              if (_isEditing) {
                return _buildEditView(context, state);
              } else {
                return _buildViewMode(context, user!);
              }
            }

            return const SizedBox.shrink();
          },
        ),
      ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context, user) {
    return SingleChildScrollView(
      key: const ValueKey('profile_view_mode'),
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const ValueKey('profile_view_column'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: DesignTokens.primaryLight.withOpacity(0.2),
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!))
                        : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(_getAvatarUrl(user.avatarUrl!))
                            : null) as ImageProvider<Object>?,
                    child: (user.avatarUrl == null &&
                            (_localAvatarPath == null ||
                                _localAvatarPath!.isEmpty))
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DesignTokens.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'User Type: ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DesignTokens.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              _formatUserType(user.userType, user.adminSubType),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DesignTokens.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        if (user.licenceNumber != null &&
                            user.licenceNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'License Number: ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DesignTokens.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                user.licenceNumber!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DesignTokens.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: DesignTokens.primaryLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Settings Section
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: DesignTokens.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Manage Offline Data
          Card(
            key: const ValueKey('manage_offline_data_card'),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              key: const ValueKey('manage_offline_data_list_tile'),
              leading: Icon(
                Icons.download_outlined,
                color: DesignTokens.primaryLight,
              ),
              title: const Text('Manage Offline Data'),
              subtitle: const Text('Clear cache or sync manually'),
              trailing: Icon(
                Icons.chevron_right,
                color: DesignTokens.primary,
              ),
              onTap: () {
                context.push('/manage-offline-data');
              },
            ),
          ),
          const SizedBox(height: 8),

          // Dark Mode
          Card(
            key: const ValueKey('dark_mode_card'),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Builder(
              builder: (context) {
                final isDark = context.select<ThemeCubit, bool>(
                  (cubit) => cubit.state == ThemeMode.dark,
                );
                return ListTile(
                  key: const ValueKey('dark_mode_list_tile'),
                  leading: Icon(
                    Icons.palette_outlined,
                    color: DesignTokens.primaryLight,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch to dark theme'),
                  trailing: Switch(
                    key: const ValueKey('dark_mode_switch'),
                    value: isDark,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                    activeColor: DesignTokens.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Sync Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.primaryLight.withOpacity(0.1),
              border: Border.all(
                color: DesignTokens.primaryLight.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.primaryLight.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: DesignTokens.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All data synced',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last synced: ${_lastSyncTime ?? 'Never'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView(BuildContext context, UserState state) {
    return SingleChildScrollView(
      key: const ValueKey('profile_edit_mode'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: DesignTokens.primaryLight.withOpacity(0.2),
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!))
                        : (state is UserLoaded &&
                                state.user.avatarUrl != null &&
                                state.user.avatarUrl!.isNotEmpty)
                            ? NetworkImage(_getAvatarUrl(state.user.avatarUrl!))
                            : null as ImageProvider<Object>?,
                    child: (state is! UserLoaded ||
                            state.user.avatarUrl == null &&
                                _localAvatarPath == null)
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.primary,
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickAvatar,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Name',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Name'),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: DesignTokens.primaryLight,
                ),
                hintText: 'User Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.primary,
                    width: 2,
                  ),
                ),
                errorText: _getFieldError('name'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: DesignTokens.primaryLight,
                ),
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.primary,
                    width: 2,
                  ),
                ),
                errorText: _getFieldError('email'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'License Number',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _licenseController,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  color: DesignTokens.primaryLight,
                ),
                hintText: 'MD-2025-12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignTokens.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.primary,
                    DesignTokens.primaryLight,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: state is UserLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  state is UserLoading ? 'Saving...' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
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
  }
}
