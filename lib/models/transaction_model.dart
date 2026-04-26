class TransactionModel {
  final int? id;
  final String type;
  final String date;
  final double amount;
  final String paymentMethod;
  final String? incomeCategory;
  final String note;
  final String additionalNote;

  TransactionModel({
    this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.incomeCategory,
    required this.note,
    required this.additionalNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date,
      'amount': amount,
      'payment_method': paymentMethod,
      'income_category': incomeCategory,
      'note': note,
      'additional_note': additionalNote,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      date: map['date'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      incomeCategory: map['income_category'] as String?,
      note: map['note'] as String,
      additionalNote: map['additional_note'] as String,
    );
  }
}