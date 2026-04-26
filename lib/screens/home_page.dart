import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../widgets/summary_item.dart';
import 'add_transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TransactionModel> transactions = [];

  List<List<Map<String, dynamic>>> chunkWallets(
    List<Map<String, dynamic>> wallets,
    int chunkSize,
  ) {
    final List<List<Map<String, dynamic>>> chunks = [];
    for (int i = 0; i < wallets.length; i += chunkSize) {
      chunks.add(
        wallets.sublist(
          i,
          i + chunkSize > wallets.length ? wallets.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  Future<void> loadWalletMethods() async {
    final data = await DatabaseHelper.instance.getWalletMethods();
    setState(() {
      walletMethods = data;
    });
  }

  final PageController pageController = PageController(viewportFraction: 0.94);
  List<Map<String, dynamic>> walletMethods = [];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadTransactions();
    loadWalletMethods();

    pageController.addListener(() {
      final page = pageController.page?.round() ?? 0;
      if (page != currentPage) {
        setState(() {
          currentPage = page;
        });
      }
    });
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageBgColor =>
      isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F2);
  Color get softCardColor =>
      isDark ? const Color(0xFF161616) : Colors.white;
  Color get saldoCardColor =>
      isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
  Color get dividerColor =>
      isDark ? Colors.white24 : Colors.grey.shade400;
  Color get primaryTextColor => isDark ? Colors.white : Colors.black;
  Color get secondaryTextColor =>
      isDark ? Colors.white70 : Colors.black54;

  Widget buildWalletGridPage(List<Map<String, dynamic>> wallets) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        return buildHomeMethodCard(wallets[index]);
      },
    );
  }

  Widget buildHomeMethodCard(Map<String, dynamic> wallet) {
    final method = wallet['name'] as String;
    final amount = getMethodBalance(method);
    final icon = getMethodIcon(method);
    final color = Color(wallet['color']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  method,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatRupiah(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  Color getMethodColor(String method) {
    switch (method) {
      case 'Cash':
        return Colors.pink.shade700;
      case 'E-Wallet':
        return Colors.cyan.shade700;
      case 'QRIS':
        return Colors.deepPurple.shade600;
      case 'Transfer':
        return Colors.orange.shade700;
      case 'Tabungan':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> loadTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('transactions', orderBy: 'id DESC');
    setState(() {
      transactions.clear();
      transactions.addAll(result.map((e) => TransactionModel.fromMap(e)));
    });
  }

  Future<void> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await loadTransactions();
  }

  void showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin mau hapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteTransaction(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> goToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionPage()),
    );
    if (result == true) await loadTransactions();
  }

  Future<void> goToEditTransaction(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(transaction: transaction),
      ),
    );
    if (result == true) await loadTransactions();
  }

  double get totalIncome => transactions
      .where((t) => t.type == 'Pemasukan')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'Pengeluaran')
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  String formatRupiah(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  DateTime parseDate(String date) {
    final parts = date.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  String formatDisplayDate(String date) {
    final parsedDate = parseDate(date);
    return DateFormat('dd MMM yyyy', 'id_ID').format(parsedDate);
  }

  Color getTransactionColor(String type) {
    if (type == 'Pemasukan') return Colors.green;
    if (type == 'Pengeluaran') return Colors.red;
    return Colors.blue;
  }

  IconData getTransactionIcon(String type) {
    if (type == 'Pemasukan') return Icons.arrow_downward_rounded;
    if (type == 'Pengeluaran') return Icons.arrow_upward_rounded;
    return Icons.swap_horiz_rounded;
  }

  String getTransactionPrefix(String type) {
    if (type == 'Pemasukan') return '+ ';
    if (type == 'Pengeluaran') return '- ';
    return '';
  }

  String getTransactionSubtitle(TransactionModel transaction) {
    if (transaction.type == 'Transfer Internal') {
      return 'Transfer antar saldo • ${transaction.paymentMethod}';
    }
    return transaction.paymentMethod;
  }

  Map<String, List<TransactionModel>> groupTransactionsByDate() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final transaction in transactions) {
      if (!grouped.containsKey(transaction.date)) {
        grouped[transaction.date] = [];
      }
      grouped[transaction.date]!.add(transaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = groupTransactionsByDate();
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: pageBgColor,
        surfaceTintColor: pageBgColor,
        title: const Text('Daily Budgeting'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryItem(
                    title: 'Pemasukan',
                    amount: formatRupiah(totalIncome),
                    bgColor: isDark
                        ? const Color(0xFF1A2A1D)
                        : Colors.green.shade50,
                    textColor: Colors.green.shade400,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                Expanded(
                  child: SummaryItem(
                    title: 'Pengeluaran',
                    amount: formatRupiah(totalExpense),
                    bgColor: isDark
                        ? const Color(0xFF2A1A1A)
                        : Colors.red.shade50,
                    textColor: Colors.red.shade400,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: saldoCardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saldo Saya',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(balance),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.black54,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            if (walletMethods.isNotEmpty) ...[
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: chunkWallets(walletMethods, 4).length,
                  itemBuilder: (context, index) {
                    final walletPages = chunkWallets(walletMethods, 4);
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == walletPages.length - 1 ? 0 : 10,
                      ),
                      child: buildWalletGridPage(walletPages[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  chunkWallets(walletMethods, 4).length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark
                              ? Colors.white24
                              : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else
              const SizedBox.shrink(),
            const SizedBox(height: 20),
            Expanded(
              child: transactions.isEmpty
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tekan tombol + untuk menambahkan transaksi baru.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];
                        final items = groupedTransactions[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: dividerColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    formatDisplayDate(date),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: dividerColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...items.map((t) {
                              final color = getTransactionColor(t.type);
                              final prefix = getTransactionPrefix(t.type);
                              final icon = getTransactionIcon(t.type);

                              return Card(
                                color: softCardColor,
                                elevation: 0.8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  onTap: () => goToEditTransaction(t),
                                  onLongPress: () {
                                    if (t.id != null) {
                                      showDeleteDialog(t.id!);
                                    }
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        color.withOpacity(0.12),
                                    child: Icon(icon, color: color),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$prefix${formatRupiah(t.amount)}',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTransactionSubtitle(t),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          t.note.isEmpty ? '-' : t.note,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        if (t.type == 'Transfer Internal')
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.blue
                                                        .withOpacity(0.15)
                                                    : Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10),
                                              ),
                                              child: Text(
                                                'Transfer Internal',
                                                style: TextStyle(
                                                  color:
                                                      Colors.blue.shade800,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}