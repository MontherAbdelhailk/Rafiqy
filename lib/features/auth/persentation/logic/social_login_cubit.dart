import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<void> signInWithGoogle() async {
  emit(SocialLoginLoading());

  try {
        await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signIn();

    if (googleUser == null) {
      emit(SocialLoginInitial());
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    print("UID = ${userCredential.user!.uid}");
    print("Email = ${userCredential.user!.email}");
    print("Name = ${userCredential.user!.displayName}");
print("========== GOOGLE SUCCESS ==========");

    emit(SocialLoginSuccess());

  } catch (e) {
    print(e);
    emit(SocialLoginError(e.toString()));
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
