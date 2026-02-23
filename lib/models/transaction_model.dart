class TransactionModel {
  final String id;
  final String uid;
  final String type;
  final double amount;
  final String currency;
  final String? categoryId;
  final String note;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.note,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] ?? '') as String,
      uid: (json['uid'] ?? '') as String,
      type: (json['type'] ?? 'expense') as String,
      amount: _toDouble(json['amount']),
      currency: (json['currency'] ?? 'USD') as String,
      categoryId: json['categoryId'] as String?,
      note: (json['note'] ?? '') as String,
      date: _parseServerDate(json['date']) ?? DateTime.now(),
      createdAt: _parseServerDate(json['createdAt']),
      updatedAt: _parseServerDate(json['updatedAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static DateTime? _parseServerDate(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    if (value is num) {
      final int raw = value.toInt();
      final int millis = raw > 1000000000000 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    }

    if (value is Map<String, dynamic>) {
      final dynamic secondsValue = value['_seconds'] ?? value['seconds'];
      final dynamic nanosValue = value['_nanoseconds'] ?? value['nanoseconds'];
      if (secondsValue is num) {
        final int millis = secondsValue.toInt() * 1000;
        final int nanosPart = nanosValue is num ? (nanosValue ~/ 1000000) : 0;
        return DateTime.fromMillisecondsSinceEpoch(
          millis + nanosPart,
          isUtc: true,
        ).toLocal();
      }
    }

    return null;
  }
}
