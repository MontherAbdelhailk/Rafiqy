// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:rafiq/features/auth/persentation/logic/signup_cubit.dart';
// import 'package:rafiq/features/auth/persentation/logic/signup_state.dart';
// class SignupBlocListener extends StatelessWidget {
//   const SignupBlocListener({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<SignupCubit, SignupState>(
//       listener: (context, state) {
//         if (state is SignupLoading) {
//           showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
//         } else if (state is SignupSuccess) {
//           Navigator.pop(context); 
//         } else if (state is SignupError) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
//         }
//       },
//       child: const SizedBox.shrink(),
//     );
//   }
// }