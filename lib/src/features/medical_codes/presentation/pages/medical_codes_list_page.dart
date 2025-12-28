import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../bloc/code_list_bloc.dart';
import '../widgets/medical_code_list_tile.dart';

class MedicalCodesListPage extends StatefulWidget {
  const MedicalCodesListPage({super.key});

  @override
  State<MedicalCodesListPage> createState() => _MedicalCodesListPageState();
}

class _MedicalCodesListPageState extends State<MedicalCodesListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if contentId is provided in query parameters
        final uri = GoRouterState.of(context).uri;
        final contentId = uri.queryParameters['contentId'];
        context.read<CodeListBloc>().add(
          LoadMedicalCodesEvent(contentId: contentId),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // Get contentId from current route if available
    final uri = GoRouterState.of(context).uri;
    final contentId = uri.queryParameters['contentId'];
    
    context.read<CodeListBloc>().add(
          LoadMedicalCodesEvent(
            search: query.isEmpty ? null : query,
            contentId: contentId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            color: const Color(0xFF0D9BB5),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
      body: BlocBuilder<CodeListBloc, CodeListState>(
        builder: (context, state) {
          if (state is CodeListLoading && state is! CodeListLoadingMore) {
            return const LoadingIndicator(message: 'Loading medical codes...');
          }

          if (state is CodeListError) {
            // Get contentId from current route if available
            final uri = GoRouterState.of(context).uri;
            final contentId = uri.queryParameters['contentId'];
            
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<CodeListBloc>().add(
                  LoadMedicalCodesEvent(contentId: contentId),
                );
              },
            );
          }

          if (state is CodeListLoaded || state is CodeListLoadingMore) {
            final codes = state is CodeListLoaded
                ? state.codes
                : (state as CodeListLoadingMore).codes;

            if (codes.isEmpty) {
              return const Center(
                child: Text('No medical codes found'),
              );
            }

            final recentCodes = codes.take(3).toList();
            final popularCodes = codes.length > 3
                ? codes.skip(3).take(3).toList()
                : <dynamic>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(theme),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    icon: Icons.history,
                    title: 'Recent Searches',
                  ),
                  const SizedBox(height: 12),
                  ...recentCodes.map((code) => _buildCodeCard(context, code)),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    icon: Icons.trending_up,
                    title: 'Popular code',
                  ),
                  const SizedBox(height: 12),
                  if (popularCodes.isEmpty)
                    _buildEmptyCard('No popular codes available')
                  else
                    ...popularCodes.map((code) => _buildCodeCard(context, code)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by code, name, or category...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF9AA3B2),
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            color: const Color(0xFF0D9BB5),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D9BB5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(BuildContext context, dynamic code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => context.go('/medical-codes/${code.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  if (code.pageMarker != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Page ${code.pageMarker}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFA45B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF0D9BB5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 15,
        ),
      ),
    );
  }
}
