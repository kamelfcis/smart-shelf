import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';

class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // The DB trigger handle_new_user creates the profiles row automatically.
    // Do NOT upsert here — the user has no session yet when email
    // confirmation is enabled, so RLS would reject the write.
    //
    // emailRedirectTo must match one of the Redirect URLs registered in the
    // Supabase Dashboard (Authentication → URL Configuration).
    return supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: 'io.smartshelf://login-callback/',
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Updates the user's display name in auth metadata and the profiles table.
  Future<void> updateProfile({required String fullName}) async {
    await supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName.trim()}),
    );
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      await supabase
          .from('profiles')
          .update({'full_name': fullName.trim()})
          .eq('id', uid);
    }
  }

  /// Changes the signed-in user's password.
  Future<void> updatePassword({required String newPassword}) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateStream =>
      supabase.auth.onAuthStateChange;
}
