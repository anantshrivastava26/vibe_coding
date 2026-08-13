import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  UserProfile? profile;
  bool loading = true;
  String? lastError;

  AuthService() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      profile = null;
      loading = false;
      notifyListeners();
      return;
    }
    await syncProfile();
  }

  Future<void> syncProfile() async {
    loading = true;
    notifyListeners();
    try {
      final json = await _api.post('/api/auth/sync');
      profile = UserProfile.fromJson(json as Map<String, dynamic>);
      lastError = null;
    } catch (e) {
      lastError = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
