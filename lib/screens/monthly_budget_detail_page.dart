import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/monthly_budget_model.dart';

class MonthlyBudgetDetailPage extends StatefulWidget {
  final String month;

  const MonthlyBudgetDetailPage({
    super.key,
    required this.month,
  });

  @override
  State<MonthlyBudgetDetailPage> createState() =>
      _MonthlyBudgetDetailPageState();
}

class _MonthlyBudgetDetailPageState extends State<MonthlyBudgetDetailPage> {
  List<MonthlyBudget> budgets = [];
  List<String> walletMethods = [];
  
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    loadWalletMethods();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final result = await DatabaseHelper.instance.getMonthlyBudgetsByMonth(
      widget.month,
    );

    setState(() {
      budgets = result.map((e) => MonthlyBudget.fromMap(e)).toList();
    });
  }

  Future<void> loadWalletMethods() async {
    final result = await DatabaseHelper.instance.getWalletMethods();

    setState(() {
      walletMethods = result.map((e) => e['name'] as String).toList();
    });
  }

  double get totalAmount {
    return budgets.fold(0, (sum, item) => sum + item.amount);
  }

  double get paidAmount {
    return budgets
        .where((item) => item.isPaid)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int get paidCount {
    return budgets.where((item) => item.isPaid).length;
  }

  Future<void> showAddBudgetDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    String? sourceWallet = walletMethods.isNotEmpty ? walletMethods.first : null;
    String? targetWallet;
    bool isRecurring = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final targetOptions =
                walletMethods.where((w) => w != sourceWallet).toList();
            if (!walletMethods.contains(sourceWallet)) {
              sourceWallet = walletMethods.isNotEmpty ? walletMethods.first : null;
            }

            if (!targetOptions.contains(targetWallet)) {
              targetWallet = null;
            }

            return AlertDialog(
              title: const Text('Tambah Monthly Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: sourceWallet,
                      decoration: const InputDecoration(
                        labelText: 'Sumber Kantong',
                        border: OutlineInputBorder(),
                      ),
                      items: walletMethods
                          .map(
                            (wallet) => DropdownMenuItem(
                              value: wallet,
                              child: Text(wallet),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          sourceWallet = value;
                          if (targetWallet == sourceWallet) {
                            targetWallet = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Besaran / Jumlah',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: targetWallet,
                      decoration: const InputDecoration(
                        labelText: 'Tujuan Kantong',
                        border: OutlineInputBorder(),
                      ),
                      items: targetOptions
                          .map(
                            (wallet) => DropdownMenuItem(
                              value: wallet,
                              child: Text(wallet),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          targetWallet = value;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      value: isRecurring,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recurring tiap bulan'),
                      onChanged: (value) {
                        setDialogState(() {
                          isRecurring = value;
                        });
                      },
                    ),
                    if (isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tagihan ini akan otomatis muncul kembali di bulan berikutnya.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (sourceWallet == null ||
                        targetWallet == null ||
                        descriptionController.text.trim().isEmpty ||
                        amountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lengkapi semua data dulu')),
                      );
                      return;
                    }

                    final amount = double.tryParse(
                          amountController.text.replaceAll('.', ''),
                        ) ??
                        0;

                    final now = DateTime.now();
                    final month = DateFormat('MMMM yyyy', 'id_ID').format(now);

                    final newBudget = MonthlyBudget(
                      month: month,
                      sourceWallet: sourceWallet!,
                      description: descriptionController.text.trim(),
                      amount: amount,
                      targetWallet: targetWallet!,
                      isPaid: false,
                      isRecurring: isRecurring,
                    );

                    await DatabaseHelper.instance.insertMonthlyBudget(newBudget.toMap());

                    loadBudgets(); // refresh

                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.month),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            child: ListTile(
              title: const Text(
                'Pengeluaran Bulanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${currencyFormatter.format(paidAmount)} / ${currencyFormatter.format(totalAmount)}\n'
                '$paidCount / ${budgets.length} tagihan selesai',
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (budgets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('Belum ada tagihan bulan ini'),
              ),
            ),

          ...budgets.map((b) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: b.isPaid ? Colors.green : Colors.grey,
                  child: Icon(
                    b.isPaid ? Icons.check : Icons.schedule,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  b.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${b.sourceWallet} → ${b.targetWallet}\n'
                  '${currencyFormatter.format(b.amount)}',
                ),
                isThreeLine: true,
                trailing: Checkbox(
                  value: b.isPaid,
                  onChanged: (value) async {
                    final updated = MonthlyBudget(
                      id: b.id,
                      month: b.month,
                      sourceWallet: b.sourceWallet,
                      description: b.description,
                      amount: b.amount,
                      targetWallet: b.targetWallet,
                      isPaid: value ?? false,
                      isRecurring: b.isRecurring,
                    );

                    await DatabaseHelper.instance.updateMonthlyBudget(
                      updated.toMap(),
                    );

                    await loadBudgets();
                  },
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddBudgetDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}