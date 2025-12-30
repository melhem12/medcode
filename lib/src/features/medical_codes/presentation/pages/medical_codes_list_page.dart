import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/services/recent_searches_service.dart';
import '../../../../core/services/code_popularity_service.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../data/datasources/medical_codes_local_data_source.dart';
import '../bloc/code_list_bloc.dart';
import '../../domain/entities/medical_code.dart';

class MedicalCodesListPage extends StatefulWidget {
  const MedicalCodesListPage({super.key});

  @override
  State<MedicalCodesListPage> createState() => _MedicalCodesListPageState();
}

class _MedicalCodesListPageState extends State<MedicalCodesListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _recentSearchesService = di.sl<RecentSearchesService>();
  final _popularityService = di.sl<CodePopularityService>();
  List<RecentSearchItem> _recentSearches = [];
  List<MedicalCode> _popularCodes = [];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if contentId is provided in query parameters
        final uri = GoRouterState.of(context).uri;
        final contentId = uri.queryParameters['contentId'];
        final hasContentId = contentId != null && contentId.isNotEmpty;
        
        context.read<CodeListBloc>().add(
          LoadMedicalCodesEvent(contentId: contentId),
        );
        
        // Only load recent searches and popular codes if NOT filtering by content/category
        if (!hasContentId) {
          // Load recent searches
          _loadRecentSearches();
          // Load popular codes
          _loadPopularCodes();
        }
      }
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _recentSearchesService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  Future<void> _loadPopularCodes() async {
    // Get top popular code IDs
    final popularCodeIds = await _popularityService.getTopPopularCodes(10);
    if (popularCodeIds.isEmpty) {
      setState(() {
        _popularCodes = [];
      });
      return;
    }

    // Load codes from local cache
    final localDataSource = di.sl<MedicalCodesLocalDataSource>();
    final allCodes = await localDataSource.getCachedMedicalCodes();
    
    // Create a map for quick lookup
    final codeMap = {for (var code in allCodes) code.id: code};
    
    // Get popular codes in order of popularity
    final popular = popularCodeIds
        .map((id) => codeMap[id])
        .whereType<MedicalCode>()
        .toList();

    if (mounted) {
      setState(() {
        _popularCodes = popular;
      });
    }
  }

  Future<void> _saveSearch(MedicalCode code) async {
    await _recentSearchesService.saveSearch(
      codeId: code.id,
      code: code.code,
      description: code.description,
      pageMarker: code.pageMarker,
    );
    // Track popularity
    await _popularityService.incrementViewCount(code.id);
    await _loadRecentSearches();
    await _loadPopularCodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    // Check if contentId is present in query parameters
    final uri = GoRouterState.of(context).uri;
    final contentId = uri.queryParameters['contentId'];
    final hasContentId = contentId != null && contentId.isNotEmpty;
    
    if (hasContentId) {
      // If accessed from home/subcategories, navigate back to contents page
      // Use pop() if possible, otherwise go to contents
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/contents');
      }
    } else {
      // Otherwise, allow default back navigation
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    // Get contentId from current route if available
    final uri = GoRouterState.of(context).uri;
    final contentId = uri.queryParameters['contentId'];
    
    context.read<CodeListBloc>().add(
          LoadMedicalCodesEvent(
            search: trimmed.isEmpty ? null : trimmed,
            contentId: contentId,
          ),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CodeListBloc>().add(const LoadMoreMedicalCodesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check if contentId is present in query parameters
    final uri = GoRouterState.of(context).uri;
    final contentId = uri.queryParameters['contentId'];
    final hasContentId = contentId != null && contentId.isNotEmpty;
    
    return PopScope(
      canPop: true, // Always allow pop - we'll handle navigation in onPopInvoked
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle Android back button
          _handleBackButton();
        }
      },
      child: Scaffold(
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
          leading: hasContentId
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFF1A237E),
                  onPressed: () => _handleBackButton(),
                )
              : null,
          automaticallyImplyLeading: false,
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

          // Reload popular codes when data is loaded (only if not filtering by content)
          if (state is CodeListLoaded) {
            final uri = GoRouterState.of(context).uri;
            final contentId = uri.queryParameters['contentId'];
            final hasContentId = contentId != null && contentId.isNotEmpty;
            
            if (!hasContentId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadPopularCodes();
              });
            }
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

            // Check if filtering by content/category
            final uri = GoRouterState.of(context).uri;
            final contentId = uri.queryParameters['contentId'];
            final hasContentId = contentId != null && contentId.isNotEmpty;

            if (codes.isEmpty && !hasContentId && _recentSearches.isEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSearchField(theme),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text('No medical codes found'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(theme),
                  const SizedBox(height: 20),
                  // Only show recent searches and popular codes when NOT filtering by content/category
                  if (!hasContentId) ...[
                    if (_recentSearches.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.history,
                            title: 'Recent Searches',
                          ),
                          TextButton(
                            onPressed: () async {
                              await _recentSearchesService.clearRecentSearches();
                              await _loadRecentSearches();
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0D9BB5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._recentSearches.take(5).map((search) => _buildRecentSearchCard(context, search)),
                      const SizedBox(height: 20),
                    ],
                    if (_popularCodes.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.trending_up,
                        title: 'Popular Codes',
                      ),
                      const SizedBox(height: 12),
                      ..._popularCodes.map((code) => _buildCodeCard(context, code)),
                      const SizedBox(height: 20),
                    ],
                  ],
                  // Show medical codes section
                  if (codes.isNotEmpty) ...[
                    // Only show header if not filtering by content (to avoid duplicate headers)
                    if (!hasContentId && (_popularCodes.isNotEmpty || _recentSearches.isNotEmpty)) ...[
                      _buildSectionHeader(
                        icon: Icons.medical_services_outlined,
                        title: 'Medical Codes',
                      ),
                      const SizedBox(height: 12),
                    ] else if (hasContentId) ...[
                      // Show header when filtering by content
                      _buildSectionHeader(
                        icon: Icons.medical_services_outlined,
                        title: 'Medical Codes',
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show all codes (not limited to 10 when filtering by content)
                    ...codes.map((code) => _buildCodeCard(context, code)),
                  ] else if (!hasContentId && _popularCodes.isEmpty && _recentSearches.isEmpty) ...[
                    // Show empty state only when not filtering
                    const Center(
                      child: Text('No medical codes found'),
                    ),
                  ],
                  if (state is CodeListLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
      ),
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
        onSubmitted: _performSearch,
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

  Widget _buildCodeCard(BuildContext context, MedicalCode code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () async {
          await _saveSearch(code);
          if (mounted) {
            context.push('/medical-codes/${code.id}');
          }
        },
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

  Widget _buildRecentSearchCard(BuildContext context, RecentSearchItem search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => context.push('/medical-codes/${search.codeId}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    search.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    search.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  if (search.pageMarker != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Page ${search.pageMarker}',
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
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF9AA3B2),
              ),
              onPressed: () async {
                await _recentSearchesService.removeSearch(search.codeId);
                await _loadRecentSearches();
              },
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

}
