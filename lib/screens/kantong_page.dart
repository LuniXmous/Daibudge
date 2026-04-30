import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import 'kantong_detail_page.dart';

class KantongPage extends StatefulWidget {
  const KantongPage({super.key});

  @override
  State<KantongPage> createState() => _KantongPageState();
}

class _KantongPageState extends State<KantongPage> {
  final List<TransactionModel> transactions = [];
  List<Map<String, dynamic>> walletMethods = [];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get pageBgColor => isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8FAFC);
  Color get saldoCardColor => isDark ? const Color(0xFF1E1E1E) : const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    loadTransactions();
    loadWalletMethods();
  }

  Future<void> loadTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'id DESC',
    );

    setState(() {
      transactions.clear();
      transactions.addAll(result.map((e) => TransactionModel.fromMap(e)));
    });
  }

  Future<void> loadWalletMethods() async {
    final data = await DatabaseHelper.instance.getWalletMethods();
    setState(() {
      walletMethods = data;
    });
  }

  Future<void> refreshAll() async {
    await loadTransactions();
    await loadWalletMethods();
  }

  double getMethodBalance(String method) {
    double total = 0;

    for (final t in transactions) {
      if (t.paymentMethod == method) {
        if (t.type == 'Pemasukan') {
          total += t.amount;
        } else if (t.type == 'Pengeluaran') {
          total -= t.amount;
        }
      }
    }

    return total;
  }

  String formatRupiah(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  IconData getMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.payments_rounded;
      case 'E-Wallet':
        return Icons.account_balance_wallet_rounded;
      case 'QRIS':
        return Icons.qr_code_rounded;
      case 'Transfer':
        return Icons.compare_arrows_rounded;
      case 'Tabungan':
        return Icons.savings_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  List<TransactionModel> getTransactionsByMethod(String method) {
    return transactions.where((t) => t.paymentMethod == method).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalSaldo = walletMethods.fold<double>(
      0,
      (sum, wallet) => sum + getMethodBalance(wallet['name'] as String),
    );

      return Scaffold(
        backgroundColor: pageBgColor,
        appBar: AppBar(
          backgroundColor: pageBgColor,
          surfaceTintColor: pageBgColor,
          title: const Text('Kantong'),
          centerTitle: true,
        ),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          Colors.white,
                          const Color.fromARGB(255, 232, 232, 232),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color.fromARGB(31, 240, 240, 240) : Colors.black12,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saldo Saya',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                         color: isDark ? Colors.white : Colors.black87
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(totalSaldo),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                       color: isDark ? Colors.white : Colors.black87
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isDark ? Colors.white : Colors.black87
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              itemCount: walletMethods.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final wallet = walletMethods[index];
                final method = wallet['name'] as String;
                final color = Color(wallet['color']);
                final balance = getMethodBalance(method);
                final icon = getMethodIcon(method);
                final logs = getTransactionsByMethod(method);

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KantongDetailPage(
                          method: method,
                          methodColor: color,
                          transactions: logs,
                        ),
                      ),
                    );
                    await refreshAll();
                  },
                  child: Container(
                   padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15), // 🔥 transparan
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0,6),
                        ),
                      ],
                      border: Border.all(
                        color: color.withOpacity(isDark ? 0.25 : 0.15),
                        width: 1,
                      ),
                    ),
                    child: Stack( 
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          right: -18,
                          top: -16,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.10),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          bottom: -24,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -8,
                          bottom: 8,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: color.withOpacity(0.06),
                            ),
                          ),
                        ),

                        // tambahan pola
                        Positioned(
                          left: -14,
                          top: 10,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.055),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: -18,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: color.withOpacity(0.045),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 42,
                          top: 18,
                          child: Transform.rotate(
                            angle: 0.7,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: color.withOpacity(0.045),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, size: 38, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                formatRupiah(balance),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}