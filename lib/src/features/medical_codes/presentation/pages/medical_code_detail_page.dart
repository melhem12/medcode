import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/services/recent_searches_service.dart';
import '../../../../core/services/code_popularity_service.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../domain/entities/medical_code.dart';
import '../bloc/code_detail_bloc.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../../data/datasources/medical_codes_local_data_source.dart';

class MedicalCodeDetailPage extends StatelessWidget {
  final String codeId;

  const MedicalCodeDetailPage({super.key, required this.codeId});

  @override
  Widget build(BuildContext context) {
    final recentSearchesService = di.sl<RecentSearchesService>();
    final popularityService = di.sl<CodePopularityService>();
    return BlocProvider(
      create: (context) => CodeDetailBloc(
        getMedicalCodeByIdUseCase: di.sl(),
      )..add(LoadMedicalCodeEvent(codeId)),
      child: BlocListener<CodeDetailBloc, CodeDetailState>(
        listener: (context, state) {
          // Save to recent searches and track popularity when code is loaded
          if (state is CodeDetailLoaded) {
            recentSearchesService.saveSearch(
              codeId: state.code.id,
              code: state.code.code,
              description: state.code.description,
              pageMarker: state.code.pageMarker,
            );
            // Increment popularity count
            popularityService.incrementViewCount(state.code.id);
          }
        },
        child: PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (!didPop) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/medical-codes');
              }
            }
          },
          child: Scaffold(
            body: BlocBuilder<CodeDetailBloc, CodeDetailState>(
              builder: (context, state) {
                if (state is CodeDetailLoading) {
                  return const LoadingIndicator(message: 'Loading code details...');
                }

                if (state is CodeDetailError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () {
                      context.read<CodeDetailBloc>().add(LoadMedicalCodeEvent(codeId));
                    },
                  );
                }

                if (state is CodeDetailLoaded) {
                  return _buildDetailView(context, state.code);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, MedicalCode code) {
    return BlocListener<FavoritesCubit, FavoritesState>(
      listener: (context, favoritesState) {
        if (favoritesState is FavoriteOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(favoritesState.message)),
          );
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/medical-codes');
                }
              },
            ),
            title: Text(
              '${code.code} ${code.category ?? ''}'.trim(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A237E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1B53),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Builder(
                              builder: (context) {
                                final tags = <Widget>[];
                                // Show section, subsection, sub-subsection, and level4 as badges
                                if (code.sectionDetected != null && code.sectionDetected!.isNotEmpty) {
                                  tags.add(_buildTag('Section', code.sectionDetected!));
                                }
                                if (code.subsectionDetected != null && code.subsectionDetected!.isNotEmpty) {
                                  tags.add(_buildTag('Subsection', code.subsectionDetected!));
                                }
                                if (code.subsubsectionDetected != null && code.subsubsectionDetected!.isNotEmpty) {
                                  tags.add(_buildTag('Sub-subsection', code.subsubsectionDetected!));
                                }
                                if (code.level4Detected != null && code.level4Detected!.isNotEmpty) {
                                  tags.add(_buildTag('Level 4', code.level4Detected!));
                                }
                                // Fallback to category/bodySystem if hierarchy fields are not available
                                if (tags.isEmpty) {
                                  if (code.category != null && code.category!.isNotEmpty) {
                                    tags.add(_buildTag('Category', code.category!));
                                  }
                                  if (code.bodySystem != null && code.bodySystem!.isNotEmpty) {
                                    tags.add(_buildTag('Body System', code.bodySystem!));
                                  }
                                }
                                if (code.pageMarker != null) {
                                  tags.add(_buildTag('Page', code.pageMarker!));
                                }
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: tags,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F1B53),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF4A5568),
                            ),
                            children: _buildHighlightedText(
                              code.description,
                              code.code,
                              const Color(0xFFFFA45B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Additional Details Section
                        if (code.flags != null ||
                            code.aValue != null ||
                            code.sValue != null ||
                            code.sectionDetected != null ||
                            code.subsectionDetected != null ||
                            code.subsubsectionDetected != null ||
                            code.level4Detected != null) ...[
                          const Text(
                            'Additional Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1B53),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (code.flags != null && code.flags!.isNotEmpty)
                                _buildClickableDetailTag(
                                  context,
                                  'Flags',
                                  code.flags!,
                                  _getFlagHint(code.flags!),
                                ),
                              if (code.aValue != null)
                                _buildClickableDetailTag(
                                  context,
                                  'A Value',
                                  code.aValue!.toStringAsFixed(2),
                                  'Means the anesthesiologist',
                                ),
                              if (code.sValue != null)
                                _buildClickableDetailTag(
                                  context,
                                  'S Value',
                                  code.sValue!.toStringAsFixed(2),
                                  'Means the surgeon',
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Hierarchy Section
                          if (code.sectionDetected != null ||
                              code.subsectionDetected != null ||
                              code.subsubsectionDetected != null ||
                              code.level4Detected != null) ...[
                            const Text(
                              'Content Hierarchy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1B53),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildHierarchyItem('Section', code.sectionDetected),
                            if (code.subsectionDetected != null && code.subsectionDetected!.isNotEmpty)
                              _buildHierarchyItem('Subsection', code.subsectionDetected),
                            if (code.subsubsectionDetected != null && code.subsubsectionDetected!.isNotEmpty)
                              _buildHierarchyItem('Sub-subsection', code.subsubsectionDetected),
                            if (code.level4Detected != null && code.level4Detected!.isNotEmpty)
                              _buildHierarchyItem('Level 4', code.level4Detected),
                          ],
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                                builder: (context, favState) {
                                  var isFavorite = false;
                                  if (favState is FavoritesLoaded) {
                                    isFavorite = favState.favorites.any((favorite) => favorite.id == code.id);
                                  } else if (favState is FavoriteOperationSuccess) {
                                    isFavorite = favState.favorites.any((favorite) => favorite.id == code.id);
                                  }
                                  return _buildOutlineButton(
                                    label: isFavorite ? 'Bookmarked' : 'Book Mark',
                                    icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                                    onTap: () => context.read<FavoritesCubit>().toggleFavorite(code.id),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOutlineButton(
                                label: 'Copy Code',
                                icon: Icons.copy_outlined,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: code.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied to clipboard')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Related Codes section
                  Row(
                    children: const [
                      Icon(Icons.description_outlined, color: Color(0xFF0F1B53)),
                      SizedBox(width: 8),
                      Text(
                        'Related Codes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1B53),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRelatedList(context, code),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0F9CB5).withOpacity(0.2)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF0F9CB5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableDetailTag(
    BuildContext context,
    String label,
    String value,
    String? hint,
  ) {
    final hasHint = hint != null && hint.isNotEmpty;
    return GestureDetector(
      onTap: hasHint
          ? () => _showHintDialog(context, label, value, hint)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasHint
                ? const Color(0xFF0F9CB5).withOpacity(0.5)
                : const Color(0xFF0F9CB5).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Color(0xFF4A5568),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (hasHint) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF0F9CB5).withOpacity(0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _getFlagHint(String flag) {
    switch (flag.trim()) {
      case 'E':
        return 'Work that requires prior approval or agreement';
      case '**':
        return 'Work whose health coverage is not currently covered by social security';
      default:
        return null;
    }
  }

  void _showHintDialog(
    BuildContext context,
    String label,
    String value,
    String hint,
  ) {
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
                    color: const Color(0xFF0F9CB5).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outlined,
                    size: 32,
                    color: Color(0xFF0F9CB5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$label: $value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1B53),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9CB5),
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

  Widget _buildHierarchyItem(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F1B53),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFF0F9CB5);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: accent),
      label: Text(
        label,
        style: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: accent),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildRelatedPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'No related codes available',
        style: TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildRelatedList(BuildContext context, MedicalCode code) {
    final localDataSource = di.sl<MedicalCodesLocalDataSource>();
    final recentSearchesService = di.sl<RecentSearchesService>();
    
    return FutureBuilder<List<MedicalCode>>(
      future: localDataSource.getCachedMedicalCodes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildRelatedPlaceholder(context);
        }

        final cached = snapshot.data ?? [];
        
        // Find related codes by multiple criteria:
        // 1. Same contentId (same category/subcategory)
        // 2. Same category
        // 3. Same bodySystem
        final related = <MedicalCode>[];
        
        // First priority: Same contentId
        if (code.contentId != null) {
          final sameContent = cached
              .where((item) =>
                  item.id != code.id &&
                  item.contentId == code.contentId)
              .take(3)
              .toList();
          related.addAll(sameContent);
        }
        
        // Second priority: Same category
        if (related.length < 3 && code.category != null) {
          final sameCategory = cached
              .where((item) =>
                  item.id != code.id &&
                  item.category == code.category &&
                  !related.any((r) => r.id == item.id))
              .take(3 - related.length)
              .toList();
          related.addAll(sameCategory);
        }
        
        // Third priority: Same bodySystem
        if (related.length < 3 && code.bodySystem != null) {
          final sameBodySystem = cached
              .where((item) =>
                  item.id != code.id &&
                  item.bodySystem == code.bodySystem &&
                  !related.any((r) => r.id == item.id))
              .take(3 - related.length)
              .toList();
          related.addAll(sameBodySystem);
        }

        if (related.isEmpty) {
          return _buildRelatedPlaceholder(context);
        }

        return Column(
          children: related
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      // Save to recent searches
                      await recentSearchesService.saveSearch(
                        codeId: item.id,
                        code: item.code,
                        description: item.description,
                        pageMarker: item.pageMarker,
                      );
                      // Navigate to detail page
                      if (context.mounted) {
                        context.push('/medical-codes/${item.id}');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.code,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                                if (item.pageMarker != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Page ${item.pageMarker}',
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
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF0D9BB5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<TextSpan> _buildHighlightedText(
    String text,
    String highlight,
    Color highlightColor,
  ) {
    final List<TextSpan> spans = [];
    final textLower = text.toLowerCase();
    final highlightLower = highlight.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = textLower.indexOf(highlightLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + highlight.length),
          style: TextStyle(
            backgroundColor: highlightColor.withOpacity(0.2),
            fontWeight: FontWeight.bold,
            color: highlightColor,
          ),
        ),
      );

      start = index + highlight.length;
    }

    return spans;
  }
}
