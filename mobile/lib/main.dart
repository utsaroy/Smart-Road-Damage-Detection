import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme.dart';
import 'core/models.dart';
import 'core/report_repository.dart';
import 'screens/home_screen.dart';
import 'screens/captures_screen.dart';
import 'screens/camera_capture_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Hydrate local repository from SQLite database
  await ReportRepository.instance.init();

  runApp(const SmartRoadApp());
}

class SmartRoadApp extends StatelessWidget {
  const SmartRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Road',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [HomeScreen(), CapturesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Center(
            heightFactor: 1.0,
            child: Container(
              height: 68,
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(38),
                border: Border.all(
                  color: const Color.fromARGB(255, 230, 230, 230),
                  width: 1,
                ),
                boxShadow: AppTheme.frostedDockShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Tab: "Home"
                  Expanded(
                    child: _buildDockTab(
                      index: 0,
                      label: 'Home',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      activeGradient: AppTheme.jellyBlue,
                    ),
                  ),

                  // Center Action: Elevated Pitch Black Circular '+' Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final dynamic res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CameraCaptureScreen(),
                          ),
                        );

                        if (res != null && mounted) {
                          DetectionResult? result;
                          if (res is DetectionResult) {
                            result = res;
                          }

                          if (!context.mounted) return;

                          if (result != null) {
                            // Switch to Saved (Captures) tab so user sees their new capture immediately
                            setState(() => _currentIndex = 1);

                            final isNoDamage =
                                result.report.damageType.toLowerCase() ==
                                    'no damage detected' ||
                                result.report.damageType.toLowerCase() ==
                                    'clear road';

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      isNoDamage
                                          ? Icons.check_circle_outline
                                          : Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        isNoDamage
                                            ? 'Scan complete: No road damage detected'
                                            : 'Detected ${result.report.damageType} (${(result.report.confidenceScore * 100).toInt()}% confidence)!',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: isNoDamage
                                    ? AppTheme.severityLow
                                    : AppTheme.severityHigh,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Tab: "Saved" (Captures)
                  Expanded(
                    child: _buildDockTab(
                      index: 1,
                      label: 'Saved',
                      icon: Icons.history,
                      activeIcon: Icons.history,
                      activeGradient: AppTheme.jellyBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required LinearGradient activeGradient,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 25 : 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        84,
                        9,
                        182,
                      ).withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: isActive
                    ? const Color.fromRGBO(1, 22, 2, 1)
                    : AppTheme.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
