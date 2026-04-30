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

                    final month = widget.month;

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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.18),
                  Colors.blue.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.blue.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -10,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.withOpacity(0.12),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: -25,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.withOpacity(0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengeluaran Bulanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        '${currencyFormatter.format(paidAmount)} / ${currencyFormatter.format(totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '$paidCount / ${budgets.length} tagihan selesai',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔥 PROGRESS BAR
                      LinearProgressIndicator(
                        value: budgets.isEmpty
                            ? 0
                            : paidCount / budgets.length,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (budgets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada tagihan bulan ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tekan tombol + untuk menambahkan tagihan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ...budgets.map((b) {
              final isPaid = b.isPaid;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: isPaid
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
                    color: isPaid
                        ? Colors.green.withOpacity(0.35)
                        : Colors.orange.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: (isPaid ? Colors.green : Colors.orange)
                            .withOpacity(0.12),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: -25,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: (isPaid ? Colors.green : Colors.orange)
                            .withOpacity(0.08),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isPaid ? Colors.green : Colors.orange,
                        child: Icon(
                          isPaid ? Icons.check : Icons.schedule,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        b.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${b.sourceWallet} → ${b.targetWallet}\n'
                        '${currencyFormatter.format(b.amount)}',
                      ),
                      isThreeLine: true,
                      trailing: Checkbox(
                        value: isPaid,
                        activeColor: isPaid ? Colors.green : Colors.orange,
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
                  ],
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "monthly_add_fab",
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        onPressed: showAddBudgetDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}