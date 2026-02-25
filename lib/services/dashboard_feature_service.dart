import '../models/category_model.dart';
import '../models/stats_models.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

typedef StatsSummaryFetcher =
    Future<Map<String, dynamic>> Function({
      required String month,
      String? currency,
    });
typedef StatsByCategoryFetcher =
    Future<Map<String, dynamic>> Function({
      required String month,
      required String currency,
      String type,
    });
typedef StatsTrendFetcher =
    Future<Map<String, dynamic>> Function({
      required String month,
      String granularity,
      String? currency,
    });
typedef TransactionsFetcher =
    Future<List<TransactionModel>> Function({
      String? month,
      String? currency,
      String? type,
      String? categoryId,
      int limit,
      String? pageToken,
    });
typedef CategoriesFetcher =
    Future<List<CategoryModel>> Function({
      int limit,
      String? pageToken,
    });

class DashboardFeatureException implements Exception {
  const DashboardFeatureException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardFeatureSnapshot {
  const DashboardFeatureSnapshot({
    required this.summary,
    required this.byCategory,
    required this.trend,
    required this.transactions,
    required this.categories,
  });

  final StatsSummaryModel summary;
  final List<CategoryStatItemModel> byCategory;
  final List<StatsTrendPointModel> trend;
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  Map<String, String> get categoryNameById => <String, String>{
    for (final CategoryModel c in categories) c.id: c.name,
  };

  bool get isEmpty {
    final bool emptyCategory = byCategory.every(
      (CategoryStatItemModel i) => i.total <= 0,
    );
    return summary.transactionCount == 0 &&
        transactions.isEmpty &&
        trend.isEmpty &&
        emptyCategory;
  }
}

class DashboardFeatureService {
  DashboardFeatureService({
    StatsSummaryFetcher? summaryFetcher,
    StatsByCategoryFetcher? byCategoryFetcher,
    StatsTrendFetcher? trendFetcher,
    TransactionsFetcher? transactionsFetcher,
    CategoriesFetcher? categoriesFetcher,
  }) : _summaryFetcher = summaryFetcher ?? ApiClient.getStatsSummary,
       _byCategoryFetcher = byCategoryFetcher ?? ApiClient.getStatsByCategory,
       _trendFetcher = trendFetcher ?? ApiClient.getStatsTrend,
       _transactionsFetcher = transactionsFetcher ?? ApiClient.getTransactions,
       _categoriesFetcher = categoriesFetcher ?? ApiClient.getCategories;

  final StatsSummaryFetcher _summaryFetcher;
  final StatsByCategoryFetcher _byCategoryFetcher;
  final StatsTrendFetcher _trendFetcher;
  final TransactionsFetcher _transactionsFetcher;
  final CategoriesFetcher _categoriesFetcher;

  Future<DashboardFeatureSnapshot> fetch({
    required String month,
    required String currency,
    required String granularity,
  }) async {
    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _summaryFetcher(month: month, currency: currency),
        _byCategoryFetcher(month: month, currency: currency, type: 'expense'),
        _trendFetcher(month: month, granularity: granularity, currency: currency),
        _transactionsFetcher(month: month, currency: currency, limit: 120),
        _categoriesFetcher(limit: 120),
      ]);

      final Map<String, dynamic> summaryMap =
          results[0] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> byCategoryMap =
          results[1] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> trendMap =
          results[2] as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<TransactionModel> tx =
          results[3] as List<TransactionModel>? ?? <TransactionModel>[];
      final List<CategoryModel> categories =
          results[4] as List<CategoryModel>? ?? <CategoryModel>[];

      final List<CategoryStatItemModel> byCategory =
          (byCategoryMap['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(CategoryStatItemModel.fromJson)
              .toList(growable: false);

      final List<StatsTrendPointModel> trend =
          (trendMap['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(StatsTrendPointModel.fromJson)
              .toList(growable: false);

      return DashboardFeatureSnapshot(
        summary: StatsSummaryModel.fromJson(summaryMap),
        byCategory: byCategory,
        trend: trend,
        transactions: tx,
        categories: categories,
      );
    } on ApiException catch (error) {
      throw DashboardFeatureException(error.message);
    } catch (error) {
      throw DashboardFeatureException('Erreur API dashboard: $error');
    }
  }
}
