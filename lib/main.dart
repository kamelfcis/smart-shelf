import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — fonts are bundled as assets.
  // Remove this line if you want google_fonts to auto-download fonts on device.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  // The custom URL scheme `io.smartshelf://login-callback/` is registered in
  // AndroidManifest.xml so Supabase redirects back into this app after email
  // confirmation.  Register the same value in the Supabase Dashboard under
  // Authentication → URL Configuration → Redirect URLs.
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(
    const ProviderScope(
      child: SmartShelfApp(),
    ),
  );
}

class SmartShelfApp extends ConsumerWidget {
  const SmartShelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Disable AnimatedTheme interpolation — our AppTypography styles use
      // inherit:true while resolved theme styles use inherit:false; lerping
      // between them crashes. Instant swap avoids the lerp entirely and also
      // prevents the GlobalKey-reuse error that fires during the transition.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
    );
  }
}
