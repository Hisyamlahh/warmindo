import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;

  bool _isInitialized = false;

  /// Initialize the Supabase client with URL and anon key from AppConstants.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConstants.supabaseAnonKey,
    );
    _isInitialized = true;
  }

  /// Returns the Supabase client instance.
  SupabaseClient get client => Supabase.instance.client;

  /// Returns the currently authenticated user, or null if not logged in.
  User? get currentUser => client.auth.currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password.
  /// Returns the [AuthResponse] on success or throws on failure.
  Future<AuthResponse> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign the current user out.
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Fetch the user's role from the `profiles` table.
  /// Returns `'admin'` or `'kasir'`. Defaults to `'kasir'` if not found.
  Future<String> getUserRole() async {
    final user = currentUser;
    if (user == null) return 'kasir';

    try {
      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = response['role'] as String?;
      return (role == 'admin') ? 'admin' : 'kasir';
    } catch (_) {
      return 'kasir';
    }
  }

  /// Provides the auth state change stream for reactive listening.
  Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
