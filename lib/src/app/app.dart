import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di/injection_container.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/user/presentation/cubit/theme_cubit.dart';
import '../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../features/user/presentation/cubit/offline_data_cubit.dart';
import '../features/user/presentation/bloc/user_bloc.dart';
import '../features/contents/presentation/cubit/contents_cubit.dart';
import '../features/medical_codes/presentation/bloc/code_list_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>()..loadThemeMode(),
        ),
        BlocProvider<FavoritesCubit>(
          create: (_) => sl<FavoritesCubit>(),
        ),
        BlocProvider<OfflineDataCubit>(
          create: (_) => sl<OfflineDataCubit>(),
        ),
        BlocProvider<UserBloc>(
          create: (_) => sl<UserBloc>(),
        ),
        BlocProvider<ContentsCubit>(
          create: (_) => sl<ContentsCubit>(),
        ),
        BlocProvider<CodeListBloc>(
          create: (_) => sl<CodeListBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            key: ValueKey(themeMode),
            title: 'MedCode',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

