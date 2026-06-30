import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/auth/domain/entities/sign_up_entity.dart';
import 'package:rafiq/features/auth/domain/repos/auth_repo.dart';
import 'package:rafiq/features/auth/persentation/logic/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final AuthRepo authRepo;
  SignupCubit(this.authRepo) : super(SignupInitial());

  Future<void> signup(SignupRequestEntity request) async {
    emit(SignupLoading());
    try {
      final user = await authRepo.signup(request);
      emit(SignupSuccess(user));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(SignupError(errorMessage));
    }
  }
}