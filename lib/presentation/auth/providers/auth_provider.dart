import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/storage_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

/// Watches the Supabase auth state
final authStateProvider = StreamProvider<Session?>((ref) {
  return ref.read(authRepositoryProvider).authStateStream.map(
        (event) => event.session,
      );
});

/// Current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final storageRepositoryProvider = Provider<StorageRepository>(
  (_) => StorageRepository(),
);

/// Live avatar URL fetched from profiles table.
/// Re-fetches whenever the current user changes.
final avatarUrlProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ref.read(storageRepositoryProvider).getAvatarUrl(userId);
});

// ── Login state ───────────────────────────────────────────
class LoginState {
  const LoginState({
    this.isLoading = false,
    this.error,
  });
  final bool isLoading;
  final String? error;
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  Future<bool> login(String email, String password) async {
    state = const LoginState(isLoading: true);
    try {
      await _repo.signIn(email: email, password: password);
      state = const LoginState();
      return true;
    } on AuthException catch (e) {
      state = LoginState(error: e.message);
      return false;
    } catch (_) {
      state = const LoginState(error: 'An unexpected error occurred');
      return false;
    }
  }

  void clearError() => state = const LoginState();
}

final loginProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.read(authRepositoryProvider));
});

// ── Signup state ──────────────────────────────────────────
class SignupState {
  const SignupState({
    this.isLoading = false,
    this.error,
    this.needsEmailConfirmation = false,
  });
  final bool isLoading;
  final String? error;
  /// True when signup succeeded but email confirmation is required
  /// (Supabase returns a user but no session).
  final bool needsEmailConfirmation;
}

class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier(this._repo) : super(const SignupState());

  final AuthRepository _repo;

  Future<bool> signUp(
      String email, String password, String fullName) async {
    state = const SignupState(isLoading: true);
    try {
      final res = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (res.session == null) {
        // Email confirmation required — user was created but not yet active.
        state = const SignupState(needsEmailConfirmation: true);
        return false; // don't navigate to dashboard
      }
      state = const SignupState();
      return true; // auto-confirmed, go to dashboard
    } on AuthException catch (e) {
      state = SignupState(error: e.message);
      return false;
    } catch (e) {
      state = SignupState(error: 'An unexpected error occurred: $e');
      return false;
    }
  }

  void clearError() => state = const SignupState();
}

final signupProvider =
    StateNotifierProvider<SignupNotifier, SignupState>((ref) {
  return SignupNotifier(ref.read(authRepositoryProvider));
});
