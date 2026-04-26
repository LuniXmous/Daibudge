import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  String transactionType = 'Pemasukan';
  String? paymentMethod;
  String? incomeCategory;

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
        note: noteController.text,
        additionalNote: additionalNoteController.text,
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
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Metode transaksi wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (transactionType == 'Pemasukan')
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: incomeCategory,
                            decoration: const InputDecoration(
                              labelText: 'Sumber Pemasukan',
                              border: OutlineInputBorder(),
                            ),
                            items: incomeSources
                                .map(
                                  (source) => DropdownMenuItem(
                                    value: source,
                                    child: Text(source),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                incomeCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Sumber pemasukan wajib dipilih';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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