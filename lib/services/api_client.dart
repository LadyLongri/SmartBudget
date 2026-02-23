import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/category_model.dart';
import '../models/transaction_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static Future<String> _getToken({bool forceRefresh = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ApiException(401, 'User not logged in');
    }

    final String? token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Invalid Firebase token');
    }

    return token;
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final Uri parsed = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return parsed;
    return parsed.replace(queryParameters: query);
  }

  static dynamic _decode(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final dynamic decoded = _decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return response.body.isEmpty
        ? 'Request failed (${response.statusCode})'
        : response.body;
  }

  static Future<http.Response> _request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    bool authorized = false,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (authorized) {
      final String token = await _getToken(forceRefresh: true);
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http
            .get(uri, headers: requestHeaders)
            .timeout(const Duration(seconds: 15));
        break;
      case 'POST':
        response = await http
            .post(uri, headers: requestHeaders, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
        break;
      case 'PATCH':
        response = await http
            .patch(uri, headers: requestHeaders, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
        break;
      case 'DELETE':
        response = await http
            .delete(uri, headers: requestHeaders)
            .timeout(const Duration(seconds: 15));
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    throw ApiException(response.statusCode, _extractErrorMessage(response));
  }

  static Future<Map<String, dynamic>> _getJsonMap(
    String path, {
    Map<String, String>? query,
    bool authorized = false,
  }) async {
    final response = await _request(
      method: 'GET',
      uri: _uri(path, query),
      authorized: authorized,
    );
    final dynamic decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> _postJsonMap(
    String path, {
    required Map<String, dynamic> body,
    bool authorized = true,
  }) async {
    final response = await _request(
      method: 'POST',
      uri: _uri(path),
      body: body,
      authorized: authorized,
    );
    final dynamic decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> _patchJsonMap(
    String path, {
    required Map<String, dynamic> body,
    bool authorized = true,
  }) async {
    final response = await _request(
      method: 'PATCH',
      uri: _uri(path),
      body: body,
      authorized: authorized,
    );
    final dynamic decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static Future<void> _deleteVoid(String path, {bool authorized = true}) async {
    await _request(method: 'DELETE', uri: _uri(path), authorized: authorized);
  }

  static Future<http.Response> health() {
    return _request(method: 'GET', uri: _uri('/health'));
  }

  static Future<Map<String, dynamic>> getMe() async {
    return _getJsonMap('/me', authorized: true);
  }

  static Future<List<TransactionModel>> getTransactions({
    String? month,
    String? currency,
    String? type,
    String? categoryId,
    int limit = 100,
  }) async {
    final Map<String, String> query = {
      'limit': '$limit',
      if (month != null && month.isNotEmpty) 'month': month,
      if (currency != null && currency.isNotEmpty) 'currency': currency,
      if (type != null && type.isNotEmpty) 'type': type,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };

    final Map<String, dynamic> json = await _getJsonMap(
      '/transactions',
      query: query,
      authorized: true,
    );

    final List<dynamic> items =
        (json['items'] as List<dynamic>? ?? <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }

  static Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String currency,
    String? categoryId,
    String note = '',
    DateTime? date,
  }) async {
    final Map<String, dynamic> payload = {
      'type': type,
      'amount': amount,
      'currency': currency,
      'note': note,
      'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };

    final Map<String, dynamic> json = await _postJsonMap(
      '/transactions',
      body: payload,
      authorized: true,
    );
    return TransactionModel.fromJson(json);
  }

  static Future<TransactionModel> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? currency,
    String? categoryId,
    String? note,
    DateTime? date,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'type': type,
      'amount': amount,
      'currency': currency,
      'categoryId': categoryId,
      'note': note,
      'date': date?.toUtc().toIso8601String(),
    }..removeWhere((String _, dynamic value) => value == null);

    final Map<String, dynamic> json = await _patchJsonMap(
      '/transactions/$id',
      body: payload,
      authorized: true,
    );
    return TransactionModel.fromJson(json);
  }

  static Future<void> deleteTransaction(String id) {
    return _deleteVoid('/transactions/$id', authorized: true);
  }

  static Future<List<CategoryModel>> getCategories() async {
    final Map<String, dynamic> json = await _getJsonMap(
      '/categories',
      authorized: true,
    );
    final List<dynamic> items =
        (json['items'] as List<dynamic>? ?? <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  static Future<CategoryModel> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    final Map<String, dynamic> payload = {
      'name': name,
      if (icon != null && icon.isNotEmpty) 'icon': icon,
      if (color != null && color.isNotEmpty) 'color': color,
    };

    final Map<String, dynamic> json = await _postJsonMap(
      '/categories',
      body: payload,
      authorized: true,
    );
    return CategoryModel.fromJson(json);
  }

  static Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'icon': icon,
      'color': color,
    }..removeWhere((String _, dynamic value) => value == null);

    final Map<String, dynamic> json = await _patchJsonMap(
      '/categories/$id',
      body: payload,
      authorized: true,
    );
    return CategoryModel.fromJson(json);
  }

  static Future<void> deleteCategory(String id) {
    return _deleteVoid('/categories/$id', authorized: true);
  }
}
