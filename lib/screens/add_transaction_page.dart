import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../services/google_sheets_service.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;

  final double? initialAmount;
  final String? initialMethod;
  final String? initialDate;


  const AddTransactionPage({
    super.key,
    this.transaction,
    this.initialAmount,
    this.initialMethod,
    this.initialDate,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  String transactionType = 'Pemasukan';
  String? paymentMethod;
  String? incomeCategory;
  String? expenseCategory;
  String? targetWallet;
    String normalizeDate(String input) {
      try {
        final parsed = DateFormat('d MMM yyyy', 'en_US').parse(input);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        return input; // fallback
      }
    }

  List<String> walletMethods = [];
  List<String> incomeSources = [];

  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController additionalNoteController = TextEditingController();


   @override
    void initState() {
      super.initState();

      loadMasterData();

      // 🔥 AUTO SET PENGELUARAN JIKA DARI SCAN
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        transactionType = 'Pengeluaran';
      }

      if (widget.initialAmount != null) {
        amountController.text =
            formatNumberOnlyToRupiahText(widget.initialAmount!.toInt().toString());
      }

      if (widget.initialMethod != null) {
        paymentMethod = widget.initialMethod!;
      }

      if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
        dateController.text = normalizeDate(widget.initialDate!);
      }

    }

  Future<void> loadMasterData() async {
    final walletResult = await DatabaseHelper.instance.getWalletMethods();
    final incomeResult = await DatabaseHelper.instance.getIncomeSources();

    final loadedWalletMethods =
        walletResult.map((e) => e['name'] as String).toList();
    final loadedIncomeSources =
        incomeResult.map((e) => e['name'] as String).toList();

    setState(() {
      walletMethods = loadedWalletMethods;
      incomeSources = loadedIncomeSources;

      if (widget.transaction != null) {
        final t = widget.transaction!;
        transactionType = t.type;
        paymentMethod = t.paymentMethod;
        incomeCategory = t.incomeCategory;
        dateController.text = t.date;
        amountController.text = formatNumberOnlyToRupiahText(
          t.amount.toInt().toString(),
        );
        noteController.text = t.note;
        additionalNoteController.text = t.additionalNote;
      } else {
        paymentMethod =
            walletMethods.isNotEmpty ? walletMethods.first : null;
        incomeCategory =
            incomeSources.isNotEmpty ? incomeSources.first : null;
      }

      if (paymentMethod == null && walletMethods.isNotEmpty) {
        paymentMethod = walletMethods.first;
      }

      if (incomeCategory == null && incomeSources.isNotEmpty) {
        incomeCategory = incomeSources.first;
      }
    });
  }

  String formatNumberOnlyToRupiahText(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll('.', '')) ?? 0;
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(number).replaceAll(',', '.');
  }

  double parseFormattedAmount(String value) {
    final clean = value.replaceAll('.', '');
    return double.tryParse(clean) ?? 0;
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    amountController.dispose();
    noteController.dispose();
    additionalNoteController.dispose();
    super.dispose();
  }

  Future<void> saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: transactionType,
        date: dateController.text,
        amount: parseFormattedAmount(amountController.text),
        paymentMethod: paymentMethod ?? '',
        incomeCategory: transactionType == 'Pemasukan' ? incomeCategory : null,
        note: transactionType == 'Pengeluaran'
            ? (expenseCategory ?? '')
            : noteController.text,
        additionalNote: transactionType == 'Transfer Internal'
            ? (targetWallet ?? '')
            : additionalNoteController.text,
      );

      if (widget.transaction == null) {
        final db = await DatabaseHelper.instance.database;
        await db.insert('transactions', transaction.toMap());
      } else {
        await DatabaseHelper.instance.updateTransaction(
          transaction.toMap(),
          transaction.id!,
        );
      }

      try {
        await GoogleSheetsService().appendTransactionToSheet(transaction);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data tersimpan lokal, tapi gagal sync: $e'),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: walletMethods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: transactionType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Transaksi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pemasukan',
                          child: Text('Pemasukan'),
                        ),
                        DropdownMenuItem(
                          value: 'Pengeluaran',
                          child: Text('Pengeluaran'),
                        ),
                        DropdownMenuItem(
                          value: 'Transfer Internal',
                          child: Text('Transfer Internal'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          transactionType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RupiahInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nominal wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Transaksi',
                        border: OutlineInputBorder(),
                      ),
                      items: walletMethods
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value;

                          if (transactionType == 'Transfer Internal' &&
                              targetWallet == paymentMethod) {
                            targetWallet = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Metode transaksi wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    if (transactionType == 'Pengeluaran') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: expenseCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Pengeluaran',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          expenseCategory = value;
                        },
                        validator: (value) {
                          if (transactionType == 'Pengeluaran' &&
                              (value == null || value.isEmpty)) {
                            return 'Kategori pengeluaran wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (transactionType == 'Transfer Internal') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: walletMethods
                            .where((method) => method != paymentMethod)
                            .contains(targetWallet)
                        ? targetWallet
                        : null,
                        decoration: const InputDecoration(
                          labelText: 'Kantong Tujuan',
                          border: OutlineInputBorder(),
                        ),
                        items: walletMethods
                            .where((method) => method != paymentMethod)
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            targetWallet = value;
                          });
                        },
                        validator: (value) {
                          if (transactionType == 'Transfer Internal' &&
                              (value == null || value.isEmpty)) {
                            return 'Kantong tujuan wajib dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Transaksi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: additionalNoteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveTransaction,
                        child: Text(isEdit ? 'Update' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll('.', '');
    final number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    final newText = formatter.format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}