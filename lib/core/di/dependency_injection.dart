import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/networking/dio_consumer.dart';

// Auth Imports
import 'package:rafiq/features/auth/domain/repos/auth_repo.dart';
import 'package:rafiq/features/auth/domain/repos/auth_repo_implement.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/signin_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/signup_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/social_login_cubit.dart';

// Chatbot Imports
import 'package:rafiq/features/chatbot_and_assessment/data/datasource/dataresourceremote.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/chat_repo.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/chat_repo_impl.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/parenting_planning_repo.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/get_chat_history_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/send_message_usecase.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_cubit.dart';

// Assessment Imports
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo_impl.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/get_assessment.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';

// Profile & Video Imports
import 'package:rafiq/features/profile/domain/repos/profile_repo.dart';
import 'package:rafiq/features/profile/domain/repos/profile_repo_implement.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_cubit.dart';
import 'package:rafiq/features/video/domain/repos/video_repo.dart';
import 'package:rafiq/features/video/domain/repos/video_repo_implement.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/video_card_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/video_list_cubit.dart';

// Posts Import
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';

// Reels Import
import 'package:rafiq/features/reels/logic/reels_cubit.dart';

// Admin Chat Import
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_cubit.dart';

// Booking Feature Imports
import 'package:rafiq/features/booking/domain/repos/booking_repo.dart';
import 'package:rafiq/features/booking/data/repos/booking_repo_impl.dart';
import 'package:rafiq/features/booking/presentation/logic/booking_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/slots_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/sessions_cubit.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // --- External ---
  // الـ Dio الأساسي للمشروع
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<ApiConsumer>(() => DioConsumer(dio: getIt<Dio>()));

  // --- Auth Feature ---
getIt.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(apiConsumer: getIt<ApiConsumer>()));
  getIt.registerFactory(() => LoginCubit(getIt<AuthRepo>()));
  getIt.registerFactory(() => SignupCubit(getIt<AuthRepo>()));
  getIt.registerFactory(() => ForgetPasswordCubit(getIt<AuthRepo>()));
  getIt.registerFactory(() => SocialLoginCubit());

  // --- Profile Feature ---
  getIt.registerLazySingleton<ProfileRepo>(() => ProfileRepoImpl(apiConsumer: getIt<ApiConsumer>()));
  getIt.registerFactory(() => ProfileCubit(getIt<ProfileRepo>()));

  // --- Video Feature ---
getIt.registerLazySingleton<VideoRepo>(() => VideoRepoImpl(api: getIt()));
  getIt.registerFactory(() => CategoryCubit(getIt<VideoRepo>()));
  getIt.registerFactory(() => VideosListCubit(getIt<VideoRepo>()));
  getIt.registerFactory(() => AdminVideoCubit(getIt<VideoRepo>()));

  // --- Chatbot Feature (Corrected) ---
  
  // 1. Data Source: بياخد الـ Dio اللي متسجل فوق
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  // 2. Repository: بياخد الـ DataSource من getIt
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: getIt<ChatRemoteDataSource>()),
  );

  // 3. Use Case: بياخد الـ Repository من getIt
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt<ChatRepository>()));

  // 4. Bloc/Cubit: بياخد الـ Use Case
// 1️⃣ أولاً: تسجيل الـ UseCase الجديدة (ضيفي السطر ده تحت سطر الـ SendMessageUseCase)
getIt.registerLazySingleton(() => GetChatHistoryUseCase(getIt<ChatRepository>()));

getIt.registerFactory(() => ChatBloc(
      getIt<SendMessageUseCase>(),
      getIt<GetChatHistoryUseCase>(), 
    ));
  // --- Assessment Feature ---
// --- Assessment Feature ---
// --- Assessment Feature ---
  // 1. الـ Repository بياخد الـ Dio الأساسي عشان يكلم الـ API الحقيقية
  getIt.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepositoryImpl(getIt<Dio>()),
  );
  
  // 2. الـ UseCase بياخد الـ Repository
  getIt.registerLazySingleton(() => GetAssessmentQuestions(getIt<AssessmentRepository>()));
  
  // 3. الـ AssessmentCubit المسؤول عن الأسئلة
  getIt.registerFactory(() => AssessmentCubit(
    getIt<GetAssessmentQuestions>(),
    getIt<AssessmentRepository>(),
  ));

  getIt.registerFactory(() => AssessmentResultCubit(
    getIt<AssessmentRepository>(),
  ));

  // --- Parenting Plan Feature ---
  getIt.registerLazySingleton<ParentingPlanRepo>(
    () => ParentingPlanRepo(getIt<ApiConsumer>()),
  );

  getIt.registerFactory<ParentingPlanCubit>(
    () => ParentingPlanCubit(getIt<ParentingPlanRepo>()),
  );

  // --- Posts Feature ---
  getIt.registerFactory(() => PostsCubit(getIt<ApiConsumer>()));

  // --- Reels Feature ---
  getIt.registerFactory(() => ReelsCubit(getIt<ApiConsumer>()));

  // --- Admin Chat Feature ---
  getIt.registerFactory(() => AdminChatCubit(getIt<ApiConsumer>()));

  // --- Booking Feature ---
  getIt.registerLazySingleton<BookingRepo>(() => BookingRepoImpl(api: getIt<ApiConsumer>()));
  getIt.registerFactory(() => SlotsCubit(getIt<BookingRepo>()));
  getIt.registerFactory(() => BookingCubit(getIt<BookingRepo>()));
  getIt.registerFactory(() => SessionsCubit(getIt<BookingRepo>()));
}