import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class KantongDetailPage extends StatelessWidget {
  final String method;
  final Color methodColor;
  final List<TransactionModel> transactions;

  const KantongDetailPage({
    super.key,
    required this.method,
    required this.methodColor,
    required this.transactions,
  });

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

  Color getTransactionColor(String type) {
    if (type == 'Pemasukan') return Colors.green;
    if (type == 'Pengeluaran') return Colors.red;
    return Colors.blue;
  }

  String getTransactionPrefix(String type) {
    if (type == 'Pemasukan') return '+ ';
    if (type == 'Pengeluaran') return '- ';
    return '';
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

  double get totalBalance {
    double total = 0;
    for (final t in transactions) {
      if (t.type == 'Pemasukan') {
        total += t.amount;
      } else if (t.type == 'Pengeluaran') {
        total -= t.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = groupTransactionsByDate();
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

    final methodIcon = getMethodIcon(method);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBgColor = Theme.of(context).scaffoldBackgroundColor;
    final softCardColor = Theme.of(context).cardColor;
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: pageBgColor,
        surfaceTintColor: pageBgColor,
        title: const Text('Rincian Kantong'),
        centerTitle: true,
      ),
      body: Column(
        children: [ 
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  methodColor,
                  methodColor.withOpacity(0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: methodColor.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -28,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                ),
                Positioned(
                  right: 34,
                  bottom: -42,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.white.withOpacity(0.08),
                  ),
                ),
                Positioned(
                  left: -28,
                  bottom: -32,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white.withOpacity(0.06),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          methodIcon,
                          size: 28,
                          color: methodColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatRupiah(totalBalance),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transactions.length} transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada transaksi untuk $method',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey,
                                    fontSize: 11,
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

                            return Card(
                              color: softCardColor,
                              elevation: 3,
                              shadowColor: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                  width: 0.8,
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$prefix${formatRupiah(t.amount)}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.note.isEmpty ? '-' : t.note,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (t.additionalNote.isNotEmpty)
                                        Text(
                                          t.additionalNote,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: secondaryTextColor,
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
    );
  }
}