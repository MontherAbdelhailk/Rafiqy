
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/auth/domain/repos/auth_repo.dart';
import 'package:rafiq/features/auth/persentation/logic/signin_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepo authRepo; 
  LoginCubit(this.authRepo) : super(LoginInitial());

  Future<void> login(String user, String pass) async {
    emit(LoginLoading());
    try {
      final userEntity = await authRepo.login(user, pass);
      emit(LoginSuccess(userEntity));
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }
}