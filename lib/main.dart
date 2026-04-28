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
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F2),
            cardColor: Colors.white,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.green;
                return Colors.grey;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.green.withOpacity(0.35);
                }
                return Colors.grey.withOpacity(0.35);
              }),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              floatingLabelStyle: TextStyle(color: Colors.green),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F2),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),
            bottomAppBarTheme: const BottomAppBarTheme(
              color: Color(0xFFF5F5F2),
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