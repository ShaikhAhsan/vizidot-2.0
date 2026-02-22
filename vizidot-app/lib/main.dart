import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/bindings/initial_bindings.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// The entry point of the Vizidot application.
///
/// This function initializes essential services like Firebase, 
/// environment variables, and the Flutter engine before starting the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress Flutter Inspector "Id does not exist" when a selected widget is disposed (e.g. after navigation).
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exception.toString();
      final stack = details.stack?.toString() ?? '';
      if (msg.contains('Id does not exist') && stack.contains('WidgetInspectorService')) {
        return;
      }
      FlutterError.presentError(details);
    };
  }
  
  // Initialize Firebase with platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load environment variables from a .env file.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Silently fail if .env is missing.
  }
  
  runApp(const App());
}

/// The root widget of the application.
///
/// It configures the [GetMaterialApp] with the application's theme,
/// routing, and initial bindings.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vizidot',
      initialBinding: InitialBindings(),
      getPages: AppPages.routes,
      initialRoute: AppRoutes.splash,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Ignore SafeArea globally to allow for full-screen custom layouts.
        return MediaQuery.removePadding(
          context: context,
          // removeTop: true,
          // removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
