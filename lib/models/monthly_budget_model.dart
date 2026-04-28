class MonthlyBudget {
  final int? id;
  final String month;
  final String sourceWallet;
  final String description;
  final double amount;
  final String targetWallet;
  final bool isPaid;
  final bool isRecurring;

  MonthlyBudget({
    this.id,
    required this.month,
    required this.sourceWallet,
    required this.description,
    required this.amount,
    required this.targetWallet,
    required this.isPaid,
    required this.isRecurring,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'source_wallet': sourceWallet,
      'description': description,
      'amount': amount,
      'target_wallet': targetWallet,
      'is_paid': isPaid ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'],
      month: map['month'],
      sourceWallet: map['source_wallet'],
      description: map['description'],
      amount: map['amount'],
      targetWallet: map['target_wallet'],
      isPaid: map['is_paid'] == 1,
      isRecurring: map['is_recurring'] == 1,
    );
  }
}