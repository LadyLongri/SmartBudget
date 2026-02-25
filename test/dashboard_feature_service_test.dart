import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/models/category_model.dart';
import 'package:smartbudget/models/transaction_model.dart';
import 'package:smartbudget/services/api_client.dart';
import 'package:smartbudget/services/dashboard_feature_service.dart';

void main() {
  group('DashboardFeatureService', () {
    test('maps API payloads into typed snapshot', () async {
      final DashboardFeatureService service = DashboardFeatureService(
        summaryFetcher: ({required String month, String? currency}) async =>
            <String, dynamic>{
              'month': month,
              'currency': currency,
              'totalExpense': 250,
              'totalIncome': 500,
              'balance': 250,
              'transactionCount': 2,
            },
        byCategoryFetcher:
            ({
              required String month,
              required String currency,
              String type = 'expense',
            }) async => <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'categoryId': 'transport',
                  'categoryName': 'Transport',
                  'total': 120,
                },
              ],
            },
        trendFetcher:
            ({
              required String month,
              String granularity = 'day',
              String? currency,
            }) async => <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'date': '2026-02-20',
                  'totalExpense': 80,
                  'totalIncome': 200,
                },
              ],
            },
        transactionsFetcher:
            ({
              String? month,
              String? currency,
              String? type,
              String? categoryId,
              int limit = 100,
              String? pageToken,
            }) async => <TransactionModel>[
              TransactionModel(
                id: 'tx-1',
                uid: 'u1',
                type: 'expense',
                amount: 120,
                currency: 'USD',
                categoryId: 'transport',
                note: 'Taxi',
                date: DateTime.parse('2026-02-20T10:00:00Z'),
              ),
            ],
        categoriesFetcher: ({int limit = 100, String? pageToken}) async =>
            const <CategoryModel>[
              CategoryModel(id: 'transport', uid: 'u1', name: 'Transport'),
            ],
      );

      final DashboardFeatureSnapshot snapshot = await service.fetch(
        month: '2026-02',
        currency: 'USD',
        granularity: 'day',
      );

      expect(snapshot.summary.totalExpense, 250);
      expect(snapshot.byCategory.first.categoryName, 'Transport');
      expect(snapshot.trend.first.totalIncome, 200);
      expect(snapshot.transactions.first.note, 'Taxi');
      expect(snapshot.categoryNameById['transport'], 'Transport');
      expect(snapshot.isEmpty, isFalse);
    });

    test('returns empty snapshot status when all values are empty', () async {
      final DashboardFeatureService service = DashboardFeatureService(
        summaryFetcher: ({required String month, String? currency}) async =>
            <String, dynamic>{
              'month': month,
              'currency': currency,
              'totalExpense': 0,
              'totalIncome': 0,
              'balance': 0,
              'transactionCount': 0,
            },
        byCategoryFetcher:
            ({
              required String month,
              required String currency,
              String type = 'expense',
            }) async => <String, dynamic>{'items': <dynamic>[]},
        trendFetcher:
            ({
              required String month,
              String granularity = 'day',
              String? currency,
            }) async => <String, dynamic>{'items': <dynamic>[]},
        transactionsFetcher:
            ({
              String? month,
              String? currency,
              String? type,
              String? categoryId,
              int limit = 100,
              String? pageToken,
            }) async => <TransactionModel>[],
        categoriesFetcher: ({int limit = 100, String? pageToken}) async =>
            const <CategoryModel>[],
      );

      final DashboardFeatureSnapshot snapshot = await service.fetch(
        month: '2026-02',
        currency: 'USD',
        granularity: 'day',
      );

      expect(snapshot.isEmpty, isTrue);
    });

    test('wraps api exception in DashboardFeatureException', () async {
      final DashboardFeatureService service = DashboardFeatureService(
        summaryFetcher: ({required String month, String? currency}) async =>
            throw const ApiException(500, 'Backend down'),
      );

      expect(
        () => service.fetch(
          month: '2026-02',
          currency: 'USD',
          granularity: 'day',
        ),
        throwsA(isA<DashboardFeatureException>()),
      );
    });
  });
}
