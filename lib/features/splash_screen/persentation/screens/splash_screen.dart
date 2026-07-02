import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.go(AppRouter.welcome); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: SafeArea(
        child: Center(
          child: SvgPicture.asset(
            'assets/images/Group 4.svg',
            width: 370.w,  
            height: 220.h, 
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}