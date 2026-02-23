import '../services/api_client.dart';

class ExpenseController {
  Future<bool> checkBackendHealth() async {
    final response = await ApiClient.health();
    return response.statusCode == 200;
  }
}
