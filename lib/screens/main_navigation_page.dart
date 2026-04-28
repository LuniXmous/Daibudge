import 'package:flutter/material.dart';
import 'add_transaction_page.dart';
import 'home_page.dart';
import 'kantong_page.dart';
import 'monthly_budget_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;

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

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
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
      body: currentPage,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: openAddTransaction,
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(255, 23, 23, 23)
              : const Color.fromARGB(255, 255, 255, 255),
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