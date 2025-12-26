import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/design_tokens.dart';
import '../cubit/offline_data_cubit.dart';
import '../cubit/offline_data_state.dart';

class ManageOfflineDataPage extends StatelessWidget {
  const ManageOfflineDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offline Data'),
      ),
      body: BlocBuilder<OfflineDataCubit, OfflineDataState>(
        builder: (context, state) {
          if (state is OfflineDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OfflineDataError) {
            return Center(child: Text(state.message));
          }

          if (state is OfflineDataLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sync Status Section
                  _buildSectionHeader('Sync Status'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: DesignTokens.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last synced: ${state.syncStatus['last_sync'] ?? 'Never'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to sync now',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: DesignTokens.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              context.read<OfflineDataCubit>().syncAllData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Download for Offline Section
                  _buildSectionHeader('Download for Offline'),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.download_outlined,
                            color: DesignTokens.primaryLight,
                          ),
                          title: const Text('All Medical Codes'),
                          subtitle: const Text('Download all codes for offline access'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              context
                                  .read<OfflineDataCubit>()
                                  .downloadCategory('all');
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.folder_outlined,
                            color: DesignTokens.primaryLight,
                          ),
                          title: const Text('By Category'),
                          subtitle: const Text('Select specific categories'),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Storage Management Section
                  _buildSectionHeader('Storage Management'),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: const Text('Clear Cache'),
                          subtitle: const Text('Remove cached data'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Clear Cache'),
                                  content: const Text(
                                    'This will remove all cached data. Continue?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<OfflineDataCubit>()
                                            .clearCache();
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                          ),
                          title: const Text('Delete All Offline Data'),
                          subtitle: const Text('Remove all downloaded content'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete All Offline Data'),
                                  content: const Text(
                                    'This will delete all downloaded content. This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<OfflineDataCubit>()
                                            .deleteAllOfflineData();
                                        Navigator.of(ctx).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Automatic Sync Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: DesignTokens.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data will automatically sync when you have an internet connection',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
