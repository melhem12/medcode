import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../app/di/injection_container.dart' as di;
import '../../domain/entities/medical_code.dart';
import '../bloc/code_detail_bloc.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';

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
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: true,
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
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (code.category != null)
                    Text(
                      code.category!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description as heading
                  Text(
                    code.description,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Pill-shaped tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (code.category != null)
                        Chip(
                          label: Text(code.category!),
                          backgroundColor: DesignTokens.primaryLight.withOpacity(0.2),
                        ),
                      if (code.pageMarker != null)
                        Chip(
                          label: Text('Page ${code.pageMarker}'),
                          backgroundColor: DesignTokens.primaryLight.withOpacity(0.2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description with highlighted code
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: _buildHighlightedText(
                        code.description,
                        code.code,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<bool>(
                          future: context.read<FavoritesCubit>().isFavorite(code.id),
                          builder: (context, snapshot) {
                            final isFavorite = snapshot.data ?? false;
                            return ElevatedButton.icon(
                              onPressed: () {
                                context.read<FavoritesCubit>().toggleFavorite(code.id);
                              },
                              icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                              label: Text(isFavorite ? 'Bookmarked' : 'Book Mark'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Related Codes section
                  Text(
                    'Related Codes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Related codes would be loaded here
                  const Text('No related codes available'),
                ],
              ),
            ),
          ),
        ],
      ),
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
