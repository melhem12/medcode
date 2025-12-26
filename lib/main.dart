import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'src/app/app.dart';
import 'src/app/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };
  
  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };
  
  try {
    // Initialize dependency injection
    await di.init();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(const App());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error during initialization: $e');
      print('Stack trace: $stackTrace');
    }
    // Run app anyway to show error screen instead of white screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (kDebugMode) ...[
                  Text('Error: $e'),
                  const SizedBox(height: 8),
                  Text('Stack: $stackTrace'),
                ] else
                  const Text('Please restart the app'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


