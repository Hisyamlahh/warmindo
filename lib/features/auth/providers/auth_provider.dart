import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warmindo_pos/core/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  String _userRole = 'kasir';
  bool _isAuthenticated = false;

  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider() {
    _listenToAuthChanges();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _supabaseService.currentUser;

  // ---------------------------------------------------------------------------
  // Auth state listener
  // ---------------------------------------------------------------------------

  void _listenToAuthChanges() {
    _authSubscription = _supabaseService.onAuthStateChange.listen(
      (AuthState state) {
        final isNowAuthenticated = state.session != null;
        if (_isAuthenticated != isNowAuthenticated) {
          _isAuthenticated = isNowAuthenticated;
          notifyListeners();
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Attempt login with [email] and [password].
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signIn(email, password);

      // Fetch role after successful login.
      _userRole = await _supabaseService.getUserRole();
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign the current user out.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
    } catch (_) {
      // Ignore sign-out errors – clear local state regardless.
    }

    _isAuthenticated = false;
    _userRole = 'kasir';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Check whether the user is already authenticated (e.g. on app start).
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = _supabaseService.isAuthenticated;

      if (_isAuthenticated) {
        _userRole = await _supabaseService.getUserRole();
      }
    } catch (_) {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh the user profile (role) from the server.
  Future<void> getUserProfile() async {
    if (!_isAuthenticated) return;

    try {
      _userRole = await _supabaseService.getUserRole();
      notifyListeners();
    } catch (_) {
      // Keep the current role if fetch fails.
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Translate common Supabase auth error messages to Indonesian.
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email atau password salah.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan cek email Anda.';
    }
    if (lower.contains('user not found')) {
      return 'Akun tidak ditemukan.';
    }
    if (lower.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Silakan coba beberapa saat lagi.';
    }
    if (lower.contains('network')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
