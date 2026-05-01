import 'package:flutter/material.dart';
import 'add_transaction_page.dart';
import 'home_page.dart';
import 'kantong_page.dart';
import 'monthly_budget_page.dart';
import 'profile_page.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;
  bool isFabOpen = false;

  Widget get currentPage {
    switch (selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const KantongPage();
      case 3:
        return const MonthlyBudgetPage();
      case 4:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  void onItemTapped(int index) async {
    if (isFabOpen) {
      setState(() => isFabOpen = false);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    setState(() {
      selectedIndex = index;
    });
  }
  

  Future<void> openScanReceipt() async {
    // 🔥 MINTA PERMISSION DULU
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      print("Permission kamera ditolak");
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);

    if (file == null) return;

    final inputImage = InputImage.fromFilePath(file.path);
    final textRecognizer = TextRecognizer();

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;

    final parsed = parseReceipt(text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(
          initialAmount: parsed['amount'],
          initialMethod: parsed['method'],
          initialDate: parsed['date'],   // tambahan
        ),
      ),
    );
  }

  Future<void> openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (isFabOpen) {
            setState(() {
              isFabOpen = false;
            });
          }
        },
        child: currentPage,
      ),
      // 🔥 FAB EXPAND
      floatingActionButton: SizedBox(
        width: 67,
        height: 78,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              left: isFabOpen ? -37 : 16,
              bottom: isFabOpen ? 58 : 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isFabOpen ? 1 : 0,
                child: FloatingActionButton.small(
                  heroTag: "scan",
                  shape: const CircleBorder(),
                  onPressed: isFabOpen
                  ? () {
                      print("SCAN DIKLIK");
                      openScanReceipt();
                    }
                  : null,
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              right: isFabOpen ? 10 : 16,
              bottom: isFabOpen ? 78 : 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isFabOpen ? 1 : 0,
                child: FloatingActionButton.small(
                  heroTag: "add",
                  shape: const CircleBorder(),  
                  onPressed: () {
                    openAddTransaction();
                  },
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              right: isFabOpen ? -37 : 16,
              bottom: isFabOpen ? 58 : 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isFabOpen ? 1 : 0,
                child: FloatingActionButton.small(
                  heroTag: "edit",
                  shape: const CircleBorder(),
                  onPressed: isFabOpen ? openAddTransaction : null,
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.edit),
                ),
              ),
            ),
            Hero(
              tag: "monthly_add_fab",
              child: FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: () {
                  setState(() {
                    isFabOpen = !isFabOpen;
                  });
                },
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                child: AnimatedRotation(
                  turns: isFabOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
      ),


      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 🔥 NAVBAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.12,
              ),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(255, 23, 23, 23)
                : Colors.white,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  navItem(icon: Icons.home_outlined, label: 'Beranda', index: 0),
                  navItem(icon: Icons.account_balance_wallet_outlined, label: 'Kantong', index: 1),
                  const SizedBox(width: 56),
                  navItem(icon: Icons.calendar_month_outlined, label: 'Bulanan', index: 3),
                  navItem(icon: Icons.person_outline, label: 'Profil', index: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? Colors.white : Colors.black87;
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;

    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Malas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

Map<String, dynamic> parseReceipt(String text) {
  double amount = 0;
  String method = 'Cash';
  String store = '';
  String date = '';

  final months = {
    'jan': '01',
    'feb': '02',
    'mar': '03',
    'apr': '04',
    'mei': '05',
    'may': '05',
    'jun': '06',
    'jul': '07',
    'agu': '08',
    'aug': '08',
    'sep': '09',
    'okt': '10',
    'oct': '10',
    'nov': '11',
    'des': '12',
    'dec': '12',
  };

  final lines = text.split('\n');

  // ======================
  // 1. DETECT STORE
  // ======================
  for (var line in lines) {
    final clean = line.trim();
    final lower = clean.toLowerCase();

    if (clean.isEmpty) continue;

    if (lower.contains('receipt')) continue;
    if (lower.contains('order')) continue;
    if (lower.contains('total')) continue;
    if (lower.contains('rp')) continue;
    if (lower.contains('jl')) continue;
    if (lower.contains('id')) continue;
    if (lower.contains('collected')) continue;

    if (clean.length < 30) {
      store = clean;
      break;
    }
  }

  // ======================
  // 2. DETECT DATE (FIXED)
  // ======================
  final dateRegex = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})');

  for (var line in lines) {
    final match = dateRegex.firstMatch(line);

    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final monthText = match.group(2)!.toLowerCase();
      final year = match.group(3)!;

      final month = months[monthText] ?? '01';

      date = '$day/$month/$year';
      break;
    }
  }

  // ======================
  // 3. DETECT TOTAL (STRICT)
  // ======================
  for (var line in lines) {
    final lower = line.toLowerCase();

    if (lower.contains('total') &&
        !lower.contains('subtotal') &&
        !lower.contains('total item')) {

      final match = RegExp(r'[\d.,]+').firstMatch(line);

      if (match != null) {
        String raw = match.group(0)!;

        raw = raw.replaceAll('.', '').replaceAll(',', '.');

        final parsed = double.tryParse(raw);

        if (parsed != null) {
          amount = parsed;
          break;
        }
      }
    }
  }

  // ======================
  // 4. FALLBACK TOTAL
  // ======================
  if (amount == 0) {
    for (var line in lines) {
      final lower = line.toLowerCase();

      if (lower.contains('rp')) {
        final match = RegExp(r'[\d.,]+').firstMatch(line);

        if (match != null) {
          String raw = match.group(0)!;

          raw = raw.replaceAll('.', '').replaceAll(',', '.');

          final parsed = double.tryParse(raw);

          if (parsed != null && parsed > amount) {
            amount = parsed;
          }
        }
      }
    }
  }

  // ======================
  // 5. PAYMENT METHOD
  // ======================
  final lowerText = text.toLowerCase();

  if (lowerText.contains('bca') || lowerText.contains('qr')) {
    method = 'BCA';
  } else if (lowerText.contains('ovo') ||
      lowerText.contains('gopay') ||
      lowerText.contains('dana')) {
    method = 'E-Wallet';
  } else if (lowerText.contains('cash')) {
    method = 'Cash';
  }

  // ======================
  // FINAL RETURN
  // ======================
  return {
    'amount': amount,
    'method': method,
    'store': store,
    'date': date,
  };
}