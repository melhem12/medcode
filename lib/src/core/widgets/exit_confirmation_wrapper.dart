import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/design_tokens.dart';

class ExitConfirmationWrapper extends StatefulWidget {
  final Widget child;

  const ExitConfirmationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ExitConfirmationWrapper> createState() => _ExitConfirmationWrapperState();
}

class _ExitConfirmationWrapperState extends State<ExitConfirmationWrapper> {
  Future<bool> _showExitDialog() async {
    if (!mounted) return false;
    
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return shouldExit == true;
  }

  bool _isRootRoute(String location) {
    // Define root routes where exit dialog should appear
    const rootRoutes = [
      '/contents',
      '/medical-codes',
      '/favorites',
      '/profile',
      '/admin/home',
    ];
    return rootRoutes.contains(location);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop && mounted) {
          final router = GoRouter.maybeOf(context);
          
          if (router == null) {
            return;
          }

          // Try to pop first - this handles normal navigation stack
          if (router.canPop()) {
            router.pop();
            return;
          }

          // Get current location
          final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
          
          // Check if we're at a root route
          if (_isRootRoute(currentLocation)) {
            // At root route - show exit dialog
            final shouldExit = await _showExitDialog();
            if (shouldExit && mounted) {
              if (Platform.isAndroid) {
                SystemNavigator.pop();
              } else if (Platform.isIOS) {
                exit(0);
              }
            }
          } else {
            // Not at root route but can't pop
            // Try to navigate back to a safe root route
            // This handles cases where navigation stack is inconsistent
            if (mounted) {
              // Check if we can navigate to a parent route
              // For detail pages, try to go back to the list
              if (currentLocation.startsWith('/medical-codes/')) {
                router.go('/medical-codes');
              } else if (currentLocation.startsWith('/admin/')) {
                router.go('/admin/home');
              } else {
                router.go('/contents');
              }
            }
          }
        }
      },
      child: widget.child,
    );
  }
}
