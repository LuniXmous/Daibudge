import 'package:flutter/material.dart';
import '../models/monthly_budget_model.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'monthly_budget_detail_page.dart';

class MonthlyBudgetPage extends StatefulWidget {
  const MonthlyBudgetPage({super.key});

  @override
  State<MonthlyBudgetPage> createState() => _MonthlyBudgetPageState();
}

class _MonthlyBudgetPageState extends State<MonthlyBudgetPage> {
  List<MonthlyBudget> budgets = [];

  List<String> get groupedMonths {
    final months = budgets.map((e) => e.month).toSet().toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final result = await DatabaseHelper.instance.getMonthlyBudgets();

    setState(() {
      budgets = result.map((e) => MonthlyBudget.fromMap(e)).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Bulanan'),
        centerTitle: true,
      ),
      body: groupedMonths.isEmpty
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Belum ada monthly budget.\nTambahkan tagihan bulanan pertama kamu dari detail bulan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
      :ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: groupedMonths.length,
        itemBuilder: (context, index) {
          final month = groupedMonths[index];
          final items = budgets.where((b) => b.month == month).toList();

          final total = items.fold<double>(0, (sum, item) => sum + item.amount);
          final paid = items
              .where((item) => item.isPaid)
              .fold<double>(0, (sum, item) => sum + item.amount);
          final paidCount = items.where((item) => item.isPaid).length;
          final isComplete = items.isNotEmpty && paidCount == items.length;

          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: isComplete
                    ? [
                        Colors.green.withOpacity(0.18),
                        Colors.green.withOpacity(0.04),
                      ]
                    : [
                        Colors.orange.withOpacity(0.18),
                        Colors.orange.withOpacity(0.04),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isComplete
                    ? Colors.green.withOpacity(0.35)
                    : Colors.orange.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isComplete ? Colors.green : Colors.orange).withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -18,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: (isComplete ? Colors.green : Colors.orange)
                        .withOpacity(0.12),
                  ),
                ),
                Positioned(
                  right: 22,
                  bottom: -32,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: (isComplete ? Colors.green : Colors.orange)
                        .withOpacity(0.08),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    '${currencyFormatter.format(paid)} / ${currencyFormatter.format(total)}\n'
                    '$paidCount / ${items.length} tagihan selesai',
                  ),
                  isThreeLine: true,
                  trailing: Center(
                    widthFactor: 1,
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: isComplete ? Colors.green : Colors.orange,
                      child: Icon(
                        isComplete ? Icons.check : Icons.schedule,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyBudgetDetailPage(month: month),
                      ),
                    );

                    await loadBudgets();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: Hero(
          tag: "monthly_add_fab",
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}