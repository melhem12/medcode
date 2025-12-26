import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../contents/presentation/cubit/contents_cubit.dart';
import '../../../contents/domain/entities/content_node.dart';
import '../../../../core/utils/user_type_rules.dart';

class ContentsHomePage extends StatefulWidget {
  const ContentsHomePage({super.key});

  @override
  State<ContentsHomePage> createState() => _ContentsHomePageState();
}

class _ContentsHomePageState extends State<ContentsHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentsCubit>().fetchContents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E), // Dark blue
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: DesignTokens.primary, // Teal color
            onPressed: () {
              context.go('/medical-codes');
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                final isSuperAdmin = UserTypeRules.isSuperAdmin(
                  authState.user.userType,
                  authState.user.adminSubType,
                );
                
                // Only show admin icon for super_admin
                if (isSuperAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    color: DesignTokens.primary, // Teal color
                    tooltip: 'Admin Dashboard',
                    onPressed: () => context.go('/admin/home'),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ContentsCubit, ContentsState>(
        builder: (context, state) {
          if (state is ContentsLoading || state is ContentsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ContentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ContentsCubit>().fetchContents();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ContentsLoaded) {
            return _buildContentGrid(context, state.contents);
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildContentGrid(BuildContext context, List<ContentNode> contents) {
    return Container(
      color: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final content = contents[index];
          return _buildContentCard(context, content);
        },
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, ContentNode content) {
    // Get icon based on title or use default
    final icon = _getIconForCategory(content.title);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          context.go('/medical-codes?contentId=${content.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with circular background (light blue outline)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignTokens.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Title (bold dark blue)
              Text(
                content.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1A237E), // Dark blue
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description (using sectionLabel or a default description)
              Text(
                content.sectionLabel ?? _getDescriptionForCategory(content.title),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Code and Page reference
              if (content.codeHint != null || content.pageMarker != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _buildCodeReference(content),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String title) {
    final lowerTitle = title.toLowerCase();
    
    // Specific icons for certain categories
    if (lowerTitle.contains('anesthesia')) {
      return Icons.medical_services_outlined;
    } else if (lowerTitle.contains('integumentary') || lowerTitle.contains('skin')) {
      return Icons.face_outlined;
    } else if (lowerTitle.contains('musculoskeletal') || lowerTitle.contains('bone')) {
      return Icons.accessibility_new_outlined;
    } else if (lowerTitle.contains('respiratory') || lowerTitle.contains('lung')) {
      return Icons.air_outlined;
    } else if (lowerTitle.contains('cardiovascular') || lowerTitle.contains('heart')) {
      return Icons.favorite_outline;
    } else if (lowerTitle.contains('hemic') || lowerTitle.contains('lymphatic') || lowerTitle.contains('blood')) {
      return Icons.water_drop_outlined;
    } else if (lowerTitle.contains('mediastinum') || lowerTitle.contains('diaphragm')) {
      return Icons.show_chart_outlined;
    } else if (lowerTitle.contains('digestive') || lowerTitle.contains('gastro')) {
      return Icons.restaurant_outlined;
    } else if (lowerTitle.contains('urinary')) {
      return Icons.water_drop_outlined;
    } else if (lowerTitle.contains('male genital')) {
      return Icons.male_outlined;
    } else if (lowerTitle.contains('female genital')) {
      return Icons.female_outlined;
    } else if (lowerTitle.contains('laparoscopy') || lowerTitle.contains('hysteroscopy')) {
      return Icons.medical_information_outlined;
    } else if (lowerTitle.contains('endocrine')) {
      return Icons.insights_outlined;
    } else if (lowerTitle.contains('nervous')) {
      return Icons.psychology_outlined;
    } else if (lowerTitle.contains('eye') || lowerTitle.contains('ocular')) {
      return Icons.remove_red_eye_outlined;
    } else if (lowerTitle.contains('auditory') || lowerTitle.contains('ear')) {
      return Icons.hearing_outlined;
    } else if (lowerTitle.contains('medicine')) {
      return Icons.medication_outlined;
    }
    
    // Default: folder icon for all other categories
    return Icons.folder_outlined;
  }

  String _getDescriptionForCategory(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('anesthesia')) {
      return 'Anesthesia procedures and services.';
    } else if (lowerTitle.contains('integumentary') || lowerTitle.contains('skin')) {
      return 'Skin, breast, and related procedures.';
    } else if (lowerTitle.contains('musculoskeletal') || lowerTitle.contains('bone')) {
      return 'Bones, joints, muscles, and related procedures.';
    } else if (lowerTitle.contains('respiratory') || lowerTitle.contains('lung')) {
      return 'Lungs, airways, and breathing-related procedures.';
    } else if (lowerTitle.contains('cardiovascular') || lowerTitle.contains('heart')) {
      return 'Heart, blood vessels, and circulation.';
    } else if (lowerTitle.contains('hemic') || lowerTitle.contains('lymphatic') || lowerTitle.contains('blood')) {
      return 'Blood and lymph system procedures.';
    } else if (lowerTitle.contains('mediastinum') || lowerTitle.contains('diaphragm')) {
      return 'Chest cavity procedures.';
    } else if (lowerTitle.contains('digestive') || lowerTitle.contains('gastro')) {
      return 'Gastrointestinal and digestive procedures.';
    }
    return 'Medical procedures and services.';
  }

  String _buildCodeReference(ContentNode content) {
    final parts = <String>[];
    if (content.codeHint != null && content.codeHint!.isNotEmpty) {
      parts.add(content.codeHint!);
    }
    if (content.pageMarker != null && content.pageMarker!.isNotEmpty) {
      parts.add('Page: ${content.pageMarker}');
    }
    return parts.join(' ');
  }
}
