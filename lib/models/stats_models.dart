class StatsSummaryModel {
  const StatsSummaryModel({
    required this.month,
    required this.currency,
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.transactionCount,
  });

  final String month;
  final String? currency;
  final double totalExpense;
  final double totalIncome;
  final double balance;
  final int transactionCount;

  factory StatsSummaryModel.fromJson(Map<String, dynamic> json) {
    return StatsSummaryModel(
      month: (json['month'] ?? '') as String,
      currency: json['currency'] as String?,
      totalExpense: _toDouble(json['totalExpense']),
      totalIncome: _toDouble(json['totalIncome']),
      balance: _toDouble(json['balance']),
      transactionCount: _toInt(json['transactionCount']),
    );
  }
}

class CategoryStatItemModel {
  const CategoryStatItemModel({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });

  final String? categoryId;
  final String categoryName;
  final double total;

  factory CategoryStatItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatItemModel(
      categoryId: json['categoryId'] as String?,
      categoryName: (json['categoryName'] ?? 'Sans categorie') as String,
      total: _toDouble(json['total']),
    );
  }
}

class StatsTrendPointModel {
  const StatsTrendPointModel({
    required this.date,
    required this.totalExpense,
    required this.totalIncome,
  });

  final String date;
  final double totalExpense;
  final double totalIncome;

  factory StatsTrendPointModel.fromJson(Map<String, dynamic> json) {
    return StatsTrendPointModel(
      date: (json['date'] ?? '') as String,
      totalExpense: _toDouble(json['totalExpense']),
      totalIncome: _toDouble(json['totalIncome']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
