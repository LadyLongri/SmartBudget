class CategoryModel {
  final String id;
  final String uid;
  final String name;
  final String? icon;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.uid,
    required this.name,
    this.icon,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '') as String,
      uid: (json['uid'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: _parseServerDate(json['createdAt']),
      updatedAt: _parseServerDate(json['updatedAt']),
    );
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
