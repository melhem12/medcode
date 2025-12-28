import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
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
    return BlocProvider(
      create: (context) => CodeDetailBloc(
        getMedicalCodeByIdUseCase: di.sl(),
      )..add(LoadMedicalCodeEvent(codeId)),
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
                            if (code.category != null)
                              _buildTag(code.category!),
                            if (code.bodySystem != null)
                              _buildTag(code.bodySystem!),
                            if (code.pageMarker != null)
                              _buildTag('Page ${code.pageMarker}'),
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
                        Row(
                          children: [
                            Expanded(
                              child: FutureBuilder<bool>(
                                future: context.read<FavoritesCubit>().isFavorite(code.id),
                                builder: (context, snapshot) {
                                  final isFavorite = snapshot.data ?? false;
                                  return _buildGradientButton(
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

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F9CB5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21B9C7), Color(0xFF0F9CB5)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
    return FutureBuilder<List<MedicalCode>>(
      future: localDataSource.getCachedMedicalCodes(),
      builder: (context, snapshot) {
        final cached = snapshot.data ?? [];
        final related = cached
            .where((item) =>
                item.id != code.id &&
                (code.category != null && item.category == code.category))
            .take(3)
            .toList();

        if (related.isEmpty) {
          return _buildRelatedPlaceholder(context);
        }

        return Column(
          children: related
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                              maxLines: 1,
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
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF0D9BB5),
                      ),
                    ],
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
