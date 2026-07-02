import 'dart:async';
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
import 'package:rafiq/features/home/widgets/admin_create_post.dart';
import 'package:rafiq/features/home/widgets/category_item.dart';
import 'package:rafiq/features/home/widgets/rafiq_card.dart';
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';
import 'package:rafiq/features/home/persentation/logic/posts_state.dart';

class HomeView extends StatefulWidget {
  final bool isAdmin;
  const HomeView({super.key, this.isAdmin = false});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isAdmin = false;

  // Slider data — 3 educational video cards as per SRS §3.1
  final List<Map<String, String>> _sliderItems = [
    {
      'image': 'assets/images/family_pic.png',
      'title': 'Understanding Your Child',
      'subtitle': 'Parenting • Beginner',
    },
    {
      'image': 'assets/images/mother_daughter.png',
      'title': 'Building Strong Bonds',
      'subtitle': 'Relationships • All Ages',
    },
    {
      'image': 'assets/images/sons.png',
      'title': 'Healthy Communication',
      'subtitle': 'Family • Intermediate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _startAutoSlide();
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await SecureStorage.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin || widget.isAdmin);
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _sliderItems.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PostsCubit>()..loadPosts(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFBF6),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                20.verticalSpace,
                _buildTopBar(),
                20.verticalSpace,

              const  Text("Learn Today", style: AppTextStyles.bold20cairo),
                14.verticalSpace,

                _buildCarousel(),
                12.verticalSpace,

                // Page indicator dots
                _buildDots(),
                24.verticalSpace,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                const    Text("Categories", style: AppTextStyles.bold20cairo),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.educationalVideosView),
                      child: 
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          "See all",
                          style: AppTextStyles.regular14cairo
                              .copyWith(color: AppColors.primaryNormalActive),
                        ),
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,

                Row(
                  children: [
                      Padding(
                    padding: const EdgeInsets.only(left: 5,right:5),
                  child:  CategoryItem(
                      title: "Parenting",
                      imagePath: "assets/images/mother_daughter.png",
                      onTap: () => context.push(
                        AppRouter.ageStagesView,
                        extra: 'parenting',
                      ),
                    ),
                      ),

                        Padding(
                    padding: const EdgeInsets.only(left: 5,right:5),
              child:      CategoryItem(
                      title: "Marital",
                      imagePath: "assets/images/sons.png",
                      onTap: () => context.push(
                        AppRouter.ageStagesView,
                        extra: 'marital',
                      ),
                    ),
                        ),

                          Padding(
                    padding: const EdgeInsets.only(left: 5,right:5),
                 child:    CategoryItem(
                      title: "Family",
                      imagePath: "assets/images/relation.png",
                      onTap: () => context.push(
                        AppRouter.ageStagesView,
                        extra: 'family',
                      ),
                    ),
                          )
                  ],
                ),

                20.verticalSpace,

                if (_isAdmin) ...[
                  const AdminCreatePostWidget(),
                  16.verticalSpace,
                ],

            const    Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Posts", style: AppTextStyles.bold20cairo),
                  ],
                ),
                12.verticalSpace,

                BlocBuilder<PostsCubit, PostsState>(
                  buildWhen: (previous, current) => current is PostsLoaded || current is PostsLoading || current is PostsError,
                  builder: (context, state) {
                    if (state is PostsLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryNormal));
                    } else if (state is PostsLoaded) {
                      if (state.posts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Text("No posts yet.", style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.posts.length,
                        separatorBuilder: (context, index) => 16.verticalSpace,
                        itemBuilder: (context, index) {
                          return RafiqPostCard(post: state.posts[index], isAdmin: _isAdmin);
                        },
                      );
                    } else if (state is PostsError) {
                      return Center(child: Text("Error loading posts: ${state.message}", style: const TextStyle(color: Colors.red)));
                    }
                    return const SizedBox.shrink();
                  },
                ),
                20.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Welcome back 👋",
            //   style:
            //       AppTextStyles.regular14cairo.copyWith(color: AppColors.grey),
            // ),
            Text("Home", style: AppTextStyles.bold20cairo),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.grey2),
              onPressed: () async {
                final isAdmin = await SecureStorage.isAdmin();
                if (!mounted) return;
                if (isAdmin) {
                  context.push(AppRouter.adminInbox);
                } else {
                  context.push(AppRouter.adminChatRoom);
                }
              },
            ),
            2.horizontalSpace,
            SvgPicture.asset(
              'assets/images/Group 4.svg',
              width: 48.w,
              height: 32.h,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 190.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _sliderItems.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final item = _sliderItems[index];
          final bool isActive = index == _currentPage;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: isActive ? 0 : 10.h,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLightActive,
                      ),
                    ),
                  ),
                  // Dark gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Text overlay
                  Positioned(
                    bottom: 14.h,
                    left: 14.w,
                    right: 14.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: AppTextStyles.bold16cairo
                              .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.verticalSpace,
                        Row(
                          children: [
                            const Icon(Icons.play_circle_fill,
                                color: AppColors.primaryNormal, size: 16),
                            6.horizontalSpace,
                            Text(
                              item['subtitle']!,
                              style: AppTextStyles.regular14cairo.copyWith(
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _sliderItems.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: i == _currentPage ? 20.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: i == _currentPage
                ? AppColors.primaryNormalActive
                : AppColors.grey1,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }
}