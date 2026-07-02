import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_cubit.dart';
import 'package:rafiq/features/profile/persentation/logic/profile_state.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';

import 'package:rafiq/features/booking/presentation/screens/my_sessions_screen.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..getProfile(),
      child: Scaffold(
        backgroundColor: AppColors.babypink,
        body: SafeArea(
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryNormal),
                );
              } else if (state is ProfileSuccess) {
                return _buildProfileBody(context, state.user);
              } else if (state is ProfileError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, style: AppTextStyles.bold16cairo),
                      TextButton(
                        onPressed: () => context.read<ProfileCubit>().getProfile(),
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

// --- الـ Body الأساسي ---
  Widget _buildProfileBody(BuildContext context, ProfileEntity user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            _buildHeader(),
            30.verticalSpace,
            _buildProfileImage(user),
            15.verticalSpace,
            Text(
              user.fullName,
              style: AppTextStyles.bold28merr.copyWith(color: AppColors.grey2),
            ),
            Text(
              user.bio,
              style: AppTextStyles.regular16merr.copyWith(color: AppColors.grey),
            ),
            30.verticalSpace,
            _buildInfoCard(user),
            40.verticalSpace,
            CustomButton(
              borderRadius: 10,
              text: 'Edit Profile',
              onPressed: () async {
                await context.push('/edit-profile', extra: user);
                if (context.mounted) {
                  context.read<ProfileCubit>().getProfile();
                }
              },
              backgroundColor: AppColors.primaryNormal,
              textColor: Colors.white,
              height: 50.h,
              icon: const Icon(Icons.edit_note, color: Colors.white),
            ),
            12.verticalSpace,
// 12.verticalSpace,
// استبدلي الزرار القديم بهذا الـ FutureBuilder:
FutureBuilder<bool>(
  future: SecureStorage.isAdmin(),
  builder: (context, snapshot) {
    // لو الـ isAdmin رجعت true، مش هنعرض الزرار (لأنه أدمن)
    // لو رجعت false (مستخدم عادي)، هنعرض الزرار
    if (snapshot.data == true) {
      return const SizedBox.shrink(); // لو أدمن، اخفي الزرار
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomButton(
        borderRadius: 10,
        text: 'My Consultation Sessions',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MySessionsScreen()),
          );
        },
        backgroundColor: AppColors.primaryNormal,
        textColor: Colors.white,
        height: 50.h,
        icon: const Icon(Icons.video_call_outlined, color: Colors.white),
      ),
    );
  },
),            12.verticalSpace,
            FutureBuilder<bool>(
              future: SecureStorage.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: CustomButton(
                      borderRadius: 10.r,
                      text: 'Admin Panel',
                      onPressed: () {
                        context.push(AppRouter.adminDashboardView);
                      },
                      backgroundColor: AppColors.secondaryNormal,
                      textColor: Colors.white,
                      height: 50.h,
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Logout button (SRS §1.4)
            CustomButton(
              borderRadius: 10,
              text: 'Logout',
              onPressed: () async {
                await SecureStorage.clearAll();
                if (context.mounted) {
                  context.go(AppRouter.welcome);
                }
              },
              backgroundColor: Colors.white,
              textColor: AppColors.errorNormal,
              borderSide: const BorderSide(color: AppColors.errorNormal),
              height: 50.h,
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorNormal),
            ),
            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        const   Icon(Icons.arrow_back, color: AppColors.darkblack),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "Profile",
              style: AppTextStyles.extrabold28cairo.copyWith(color: Colors.black),
            ),
          ),
          SvgPicture.asset(
            'assets/images/Group 4.svg',
            width: 56.w,
            height: 38.h,
          ),
        ],
      ),
    );
  }

Widget _buildProfileImage(ProfileEntity user) {
  return Center(
    child: SizedBox(
      width: 140.w,
      height: 140.h,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                ? Container( // هذا هو الـ Icon الجميل بدلاً من الصورة
                    width: 130.w,
                    height: 130.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey5, // لون خلفية هادئ
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 60.sp,
                      color: AppColors.primaryNormal,
                    ),
                  )
                : AppAvatar(
                    imageUrl: user.profilePicture,
                    radius: 65.r,
                    name: user.fullName,
                  ),
          ),
          Positioned(
            bottom: 10.h,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryNormal,
                child: Icon(Icons.edit, color: Colors.white, size: 18.sp),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildInfoCard(ProfileEntity user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
                              Padding(
            padding: const EdgeInsets.only(top:9,bottom: 9),

       child:   _buildProfileRow("First Name", user.firstName),
                              ),
          const Divider(height: 10),
                              Padding(
            padding: const EdgeInsets.only(top: 9,bottom: 9),
child:
          _buildProfileRow("Last Name", user.lastName),
                              ),
          const Divider(height: 10),
                              Padding(
            padding: const EdgeInsets.only(top: 9,bottom: 9),

     child:      _buildProfileRow("Phone Number", user.phone),
                              ),
          const Divider(height: 10),
                              Padding(
            padding: const EdgeInsets.only(top: 9,bottom: 9),

       child:   _buildProfileRow("Age", user.age.toString()),
                              ),
          const Divider(height: 10),
                              Padding(
            padding: const EdgeInsets.only(top: 9,bottom: 9),

     child:      _buildProfileRow("Status", user.status),
                              ),
          // Conditional: only show when Married (SRS §2.1)
          if (user.status == 'Married') ...[
            const Divider(height: 10),
            _buildProfileRow("Number of Children", user.childrenCount.toString()),
          ],
        ],
      ),
    );
  }


  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey),
        ),
        Text(
          value,
          style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2),
        ),
      ],
    );
  }
}