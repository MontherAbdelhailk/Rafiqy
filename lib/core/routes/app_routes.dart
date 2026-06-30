import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_cubit.dart';

// Auth Imports
import 'package:rafiq/features/auth/persentation/logic/signin_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/signup_cubit.dart';
import 'package:rafiq/features/auth/persentation/signin_screen.dart';
import 'package:rafiq/features/auth/persentation/signup_screen.dart';
import 'package:rafiq/features/auth/persentation/welcome_screen.dart';
import 'package:rafiq/features/auth/persentation/forget_password.dart';
import 'package:rafiq/features/auth/persentation/otp_view.dart';
import 'package:rafiq/features/auth/persentation/create_new_password.dart';
import 'package:rafiq/features/auth/persentation/success_confirmation_views.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assess_result.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assessment_intro.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assessment_qs.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/chatbot_screens.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/chatbot_cubit.dart';
import 'package:rafiq/features/home/persentation/home_view.dart';
import 'package:rafiq/features/home/widgets/main_layout.dart';
import 'package:rafiq/features/home/widgets/post_sheet.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_cubit.dart';
import 'package:rafiq/features/video/persentation/upload_media_video.dart';
import 'package:rafiq/features/video/persentation/video_view.dart';
import 'package:rafiq/features/reels/persentation/reels_view.dart';
import 'package:rafiq/features/auth/persentation/profile_view.dart';
import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';
import 'package:rafiq/features/profile/persentation/edit_profile.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/features/video/persentation/video_details_view.dart';
import 'package:rafiq/features/video/persentation/video_list_view.dart';
import 'package:rafiq/features/video/persentation/age_stage_view.dart';
import 'package:rafiq/features/video/persentation/admin_video_view.dart';
import 'package:rafiq/features/video/persentation/admin_create_post_view.dart';
import 'package:rafiq/features/video/persentation/admin_dashboard_view.dart';
import 'package:rafiq/features/reels/persentation/new_reels_view.dart';
import 'package:rafiq/features/reels/persentation/upload_media_view.dart';
import 'package:rafiq/features/reels/logic/reels_cubit.dart';
import 'package:rafiq/features/Posts/peresentation/comments_view.dart';
import 'package:rafiq/features/book_session/persentation/screens/book_session.dart';
import 'package:rafiq/features/admin_chat/persenation/screens/admin_chat_view.dart';
import 'package:rafiq/features/admin_chat/persenation/screens/admin_inbox_view.dart';
import 'package:rafiq/features/admin_chat/persenation/logic/admin_chat_cubit.dart';

abstract class AppRouter {
  static const welcome = '/welcome';
  static const signUp = '/signup';
  static const signIn = '/signin';
  static const forgetPassword = '/ForgetPasswordView';
  static const adminChatRoom = '/AdminChatRoom';
  static const adminInbox = '/AdminInbox';
  static const otpView = '/otpView';
  static const createNewPasswordView = '/createNewPasswordView';
  static const successConfirmationView = '/successConfirmationView';

  static const homeView = '/HomeView';
  static const educationalVideosView = '/EducationalVideosView';
  static const reelsView = '/ReelsView';
  static const profileView = '/profileView';

  static const editProfileView = '/EditProfileView';
  static const videoDetailsView = '/VideoDetailsView';
  static const videosListView = '/VideosListView';
  static const ageStagesView = '/AgeStagesView';
  static const parentingAdminView = '/ParentingAdminView';
  static const adminDashboardView = '/AdminDashboardView';
  static const createPostView = '/CreatePostView';
  static const commentsView = '/CommentsView';
  static const newReelView = '/NewReelView';
  static const uploadMediaView = '/UploadMediaView';
  static const createPostSheet = '/CreatePostSheet';
  static const chatPage = '/ChatPage';
  static const bookSessionScreen = '/BookSessionScreen';
  static const uploadVideoMediaView = '/UploadVideoMediaView';
  static const String kAssessmentIntro = '/assessmentIntro';
  static const String kAssessmentQuestions = '/assessmentQuestions';
  static const String kAssessmentResult = '/assessmentResult';

  // ── Auth Guard ──────────────────────────────────────────────────────────────
  // Routes that require authentication
  static const _protectedRoutes = [
    '/HomeView',
    '/EducationalVideosView',
    '/ChatPage',
    '/ReelsView',
    '/profileView',
    '/EditProfileView',
    '/VideoDetailsView',
    '/VideosListView',
    '/AgeStagesView',
    '/CommentsView',
    '/BookSessionScreen',
    '/assessmentIntro',
    '/assessmentQuestions',
    '/assessmentResult',
    '/AdminChatRoom',
    '/AdminInbox',
  ];

  static final router = GoRouter(
    initialLocation: homeView,
    redirect: (context, state) async {
      final location = state.uri.toString();
      final isProtected = _protectedRoutes.any((r) => location.startsWith(r));

      if (isProtected) {
        final hasToken = await SecureStorage.hasToken();
        if (!hasToken) {
          return welcome;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: welcome, builder: (context, state) => const WelcomeView()),

      GoRoute(
        path: signIn,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<LoginCubit>(),
          child: const LoginScreen(),
        ),
      ),

      GoRoute(
        path: signUp,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<SignupCubit>(),
          child: const SignupScreen(),
        ),
      ),

      GoRoute(
        path: forgetPassword,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<ForgetPasswordCubit>(),
          child: const ForgetPasswordView(),
        ),
      ),

      GoRoute(
        path: otpView,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpView(phoneNumber: phone);
        },
      ),

      GoRoute(
        path: createNewPasswordView,
        builder: (context, state) {
          final token = state.extra as String? ?? '';
          return CreateNewPasswordView(token: token);
        },
      ),

      GoRoute(
        path: successConfirmationView,
        builder: (context, state) => const SuccessConfirmationView(),
      ),

      // ── Shell (Bottom Nav) ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: homeView,
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: educationalVideosView,
            builder: (context, state) => const EducationalVideosView(),
          ),
          GoRoute(
            path: '/ChatPage',
            builder: (context, state) {
              return FutureBuilder<String?>(
                future: SecureStorage.getUserId(),
                builder: (context, snapshot) {
                  final userId = snapshot.data ?? 'guest';
                  return BlocProvider(
                    create: (_) => getIt<ChatBloc>()..getChatHistory(userId),
                    child: ChatPage(),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: reelsView,
            builder: (context, state) {
              final video = state.extra as XFile?;
              return BlocProvider(
                create: (context) => getIt<ReelsCubit>()..loadReels(),
                child: ReelsView(
                  videoFile: video,
                ),
              );
            },
          ),
          GoRoute(
            path: profileView,
            builder: (context, state) => const ProfileView(),
          ),
          GoRoute(
            path: bookSessionScreen,
            builder: (context, state) => const BookSessionScreen(),
          ),
        ],
      ),

      // ── Video ─────────────────────────────────────────────────────────────
      GoRoute(
        path: videoDetailsView,
        builder: (context, state) {
          final videoModel = state.extra as VideoEntity;
          return VideoDetailsView(video: videoModel);
        },
      ),

      // ── Profile Edit ──────────────────────────────────────────────────────
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          // Receives ProfileEntity via extra; falls back to empty profile if missing
          final profile = state.extra as ProfileEntity? ??
              ProfileEntity(
                firstName: '',
                lastName: '',
                childrenCount: 0,
                age: 0,
                bio: '',
                phone: '',
                status: 'Single',
              );
          return EditProfileView(user: profile);
        },
      ),

      GoRoute(
        path: editProfileView,
        builder: (context, state) {
          final profile = state.extra as ProfileEntity? ??
              ProfileEntity(
                firstName: '',
                lastName: '',
                childrenCount: 0,
                age: 0,
                bio: '',
                phone: '',
                status: 'Single',
              );
          return EditProfileView(user: profile);
        },
      ),

      // ── Assessment ────────────────────────────────────────────────────────
      GoRoute(
        path: kAssessmentIntro,
        name: kAssessmentIntro,
        builder: (context, state) => const AssessmentIntroPage(),
      ),

      GoRoute(
        path: kAssessmentQuestions,
        name: kAssessmentQuestions,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final String userId = extra['userId'] as String;
          final int childAge = extra['childAge'] as int;

          return BlocProvider(
            create: (context) => getIt<AssessmentCubit>()..loadQuestions(),
            child: AssessmentQuestionnairePage(
              userId: userId,
              childAge: childAge,
            ),
          );
        },
      ),

      GoRoute(
        path: kAssessmentResult,
        name: kAssessmentResult,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final String userId = extra['userId'] as String;
          final int childAge = extra['childAge'] as int;
          final List<dynamic> answeredQuestions =
              extra['answeredQuestions'] as List<dynamic>;

          return BlocProvider(
            create: (context) => getIt<AssessmentResultCubit>()..loadResults(
                  userId: userId,
                  childAge: childAge,
                  answeredQuestions:
                      answeredQuestions.cast<AssessmentQuestion>(),
                ),
            child: const AssessmentResultPage(),
          );
        },
      ),

      // ── Age Stages / Videos List ──────────────────────────────────────────
      GoRoute(
        path: ageStagesView,
        builder: (context, state) {
          final categoryType = state.extra as String? ?? 'parenting';
          return AgeStagesView(categoryType: categoryType);
        },
      ),

      GoRoute(
        path: videosListView,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VideosListView(
            stageTitle: extra?['stageTitle'] as String? ?? '',
          );
        },
      ),

      GoRoute(
        path: commentsView,
        builder: (context, state) {
          final postId = state.extra as String? ?? '';
          return CommentsView(postId: postId);
        },
      ),

      GoRoute(
        path: uploadMediaView,
        builder: (context, state) => const UploadMediaView(),
      ),

      GoRoute(
        path: uploadVideoMediaView,
        builder: (context, state) => const UploadVideoMediaView(),
      ),

      GoRoute(
        path: createPostSheet,
        builder: (context, state) => const CreatePostSheet(),
      ),

      GoRoute(
        path: parentingAdminView,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<AdminVideoCubit>()..fetchAdminVideos(),
          child: const ParentingAdminView(),
        ),
      ),

      GoRoute(
        path: adminDashboardView,
        builder: (context, state) => const AdminDashboardView(),
      ),

      GoRoute(
        path: AppRouter.createPostView,
        builder: (context, state) {
          XFile? videoFile;
          VideoEntity? videoToEdit;
          if (state.extra is XFile) {
            videoFile = state.extra as XFile;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            videoFile = map['videoFile'] as XFile?;
            videoToEdit = map['videoToEdit'] as VideoEntity?;
          }
          return BlocProvider.value(
            value: getIt<AdminVideoCubit>(),
            child: CreatePostView(videoFile: videoFile, videoToEdit: videoToEdit),
          );
        },
      ),

      GoRoute(
        path: newReelView,
        builder: (context, state) {
          final videoFile = state.extra as XFile;
          return BlocProvider(
            create: (context) => getIt<ReelsCubit>(),
            child: NewReelView(videoFile: videoFile),
          );
        },
      ),



      GoRoute(
        path: adminInbox,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<AdminChatCubit>()
            ..connectSocket()
            ..loadConversations()
            ..loadUnreadCount(),
          child: const AdminInboxView(),
        ),
      ),

      GoRoute(
        path: adminChatRoom,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final targetUserId = extra?['userId'] as String? ?? 'admin';
          final targetUserName = extra?['userName'] as String? ?? 'Admin';
          final targetUserImage = extra?['userImage'] as String?;
          return BlocProvider(
            create: (context) => getIt<AdminChatCubit>()
              ..connectSocket()
              ..setActiveRoom(targetUserId)
              ..loadHistory(targetUserId),
            child: AdminChatRoomView(
              targetUserId: targetUserId,
              targetUserName: targetUserName,
              targetUserImage: targetUserImage,
            ),
          );
        },
      ),
    ],
  );
}