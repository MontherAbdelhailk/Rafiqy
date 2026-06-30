import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart'; // استخدمي GoRouter
import 'package:rafiq/core/routes/app_routes.dart';

class UploadMediaView extends StatefulWidget {
  const UploadMediaView({super.key});

  @override
  State<UploadMediaView> createState() => _UploadMediaViewState();
}

class _UploadMediaViewState extends State<UploadMediaView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (video != null) {
      if (!mounted) return;

      context.push(
        AppRouter.newReelView,
        extra: video, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const CloseButton(color: Colors.black),
        title: const Text("Upload Media", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _pickVideo,
            child: Text(
              "Next",
              style: TextStyle(
                color: const Color(0xFF96A53A),
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 80.sp, color: Colors.grey),
            20.verticalSpace,
            ElevatedButton(
              onPressed: _pickVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF96A53A),
              ),
              child: const Text("Select Video from Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}