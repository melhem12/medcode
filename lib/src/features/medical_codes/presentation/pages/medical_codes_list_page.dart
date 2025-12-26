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
        context.read<CodeListBloc>().add(const LoadMedicalCodesEvent());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    context.read<CodeListBloc>().add(
          LoadMedicalCodesEvent(search: query.isEmpty ? null : query),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Codes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search codes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
        ),
      ),
      body: BlocBuilder<CodeListBloc, CodeListState>(
        builder: (context, state) {
          if (state is CodeListLoading && state is! CodeListLoadingMore) {
            return const LoadingIndicator(message: 'Loading medical codes...');
          }

          if (state is CodeListError) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<CodeListBloc>().add(const LoadMedicalCodesEvent());
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

            return ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes[index];
                return MedicalCodeListTile(
                  code: code,
                  onTap: () {
                    context.go('/medical-codes/${code.id}');
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }
}
