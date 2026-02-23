import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<String> getIdToken({bool forceRefresh = true}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw Exception('Token is null or empty');
    }

    return token;
  }

  static Future<String> loginAndGetToken(String email, String password) async {
    await login(email, password);
    return getIdToken(forceRefresh: true);
  }
}
