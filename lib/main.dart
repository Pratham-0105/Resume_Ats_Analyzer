// The University of Texas at El Paso: Bryan Perez
// Modernized UI with Plus Jakarta Sans & Executive Design System

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/resume_provider.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/analysis_screen.dart';
import 'utils/scoring_rules.dart';
import 'widgets/animated_gradient_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate scoring constants & regex patterns at startup.
  ScoringRules.initialize(enableLogging: true);

  // Global error handler for uncaught build/render errors.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const SmartResumeAnalyzerApp());
}

/// The root widget of the Smart Resume Analyzer application.
class SmartResumeAnalyzerApp extends StatelessWidget {
  const SmartResumeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResumeViewModel()),
      ],
      child: MaterialApp(
        title: 'Smart Resume Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            primary: const Color(0xFF2E1065),
            secondary: const Color(0xFF9333EA),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAF5FF),
          textTheme: baseTextTheme.copyWith(
            displaySmall: baseTextTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            headlineSmall: baseTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            titleLarge: baseTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleMedium: baseTextTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF2E1065),
            elevation: 0,
            scrolledUnderElevation: 1,
            centerTitle: false,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          }),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/upload': (_) => const UploadScreen(),
          '/analysis': (_) => const AnalysisScreen(),
        },
      ),
    );
  }
}

/// A full‐screen splash that layers the animated gradient
/// behind the modern ATS badge before routing to HomeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..forward();

    // Auto-navigate after 2.5 seconds.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleController.drive(
                  CurveTween(curve: Curves.easeOutBack),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        size: 54,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Smart Resume Analyzer',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF2E1065),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AI & ATS SCORING ENGINE',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
