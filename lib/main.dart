import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_navigation_page.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const DailyBudgetingApp());
}

class DailyBudgetingApp extends StatelessWidget {
  const DailyBudgetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Daibudge',
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16A34A),
              brightness: Brightness.light,
            ),
            
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Colors.black12,
                  width: 0.8,
                ),
              ),
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAFC),
              foregroundColor: Colors.black,
              elevation: 0,
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),

            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),

            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            cardColor: const Color(0xFF1A1A1A),
            cardTheme: CardTheme(
              color: const Color(0xFF1A1A1A),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Colors.white12,
                  width: 0.8,
                ),
              ),
            ),

            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D0D0D),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),

            bottomAppBarTheme: const BottomAppBarTheme(
              color: Color(0xFF121212),
            ),

          ),
          home: const MainNavigationPage(),
        );
      },
    );
  }
}