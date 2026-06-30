import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

// ── States ──────────────────────────────────────────────────────────────────

sealed class SocialLoginState {}

final class SocialLoginInitial extends SocialLoginState {}

final class SocialLoginLoading extends SocialLoginState {}

final class SocialLoginSuccess extends SocialLoginState {}

final class SocialLoginError extends SocialLoginState {
  final String message;
  SocialLoginError(this.message);
}

// ── Cubit ────────────────────────────────────────────────────────────────────

/// Handles Google and Apple OAuth flows.
/// Currently stubbed — wire the actual Firebase Auth calls when the
/// google_sign_in / sign_in_with_apple packages are added.
class SocialLoginCubit extends Cubit<SocialLoginState> {
  SocialLoginCubit() : super(SocialLoginInitial());

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    emit(SocialLoginLoading());
    try {
      // TODO: Replace stub with real Firebase + GoogleSignIn flow:
      //
      // final googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) { emit(SocialLoginInitial()); return; }
      // final googleAuth = await googleUser.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // final userCredential =
      //     await FirebaseAuth.instance.signInWithCredential(credential);
      // final token = await userCredential.user!.getIdToken();
      // await SecureStorage.saveToken(token!);
      // await SecureStorage.saveRole('user');
      // await SecureStorage.saveUserId(userCredential.user!.uid);
      // await SecureStorage.saveUsername(userCredential.user!.email ?? '');

      emit(SocialLoginSuccess());
    } catch (e) {
      emit(SocialLoginError('Google sign-in failed: ${e.toString()}'));
    }
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  Future<void> signInWithApple() async {
    emit(SocialLoginLoading());
    try {
      // TODO: Replace stub with real Firebase + Sign in with Apple flow:
      //
      // final appleCredential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      // );
      // final oauthCredential = OAuthProvider("apple.com").credential(
      //   idToken: appleCredential.identityToken,
      //   accessToken: appleCredential.authorizationCode,
      // );
      // final userCredential =
      //     await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      // final token = await userCredential.user!.getIdToken();
      // await SecureStorage.saveToken(token!);
      // await SecureStorage.saveRole('user');
      // await SecureStorage.saveUserId(userCredential.user!.uid);

      emit(SocialLoginSuccess());
    } catch (e) {
      emit(SocialLoginError('Apple sign-in failed: ${e.toString()}'));
    }
  }
}
