import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart'; 

class UploadVideoMediaView extends StatefulWidget {
  const UploadVideoMediaView({super.key});

  @override
  State<UploadVideoMediaView> createState() => _UploadMediaViewState();
}

class _UploadMediaViewState extends State<UploadVideoMediaView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2), 
    );

    if (video != null) {
      setState(() {
        _selectedVideo = video;
      });
      
      if (!mounted) return;
      _navigateToCreatePost();
    }
  }

  void _navigateToCreatePost() {
    if (_selectedVideo != null) {
      context.push(
        AppRouter.createPostView,
        extra: _selectedVideo, 
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video first")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const CloseButton(color: Colors.black),
        title:  Text("Upload Media", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedVideo != null ? _navigateToCreatePost : null, 
            child: Text(
              "Next", 
              style:
              AppTextStyles.bold20cairo.copyWith(color: _selectedVideo != null ? AppColors.primaryNormal : Colors.grey)


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
            Icon(
              _selectedVideo != null ? Icons.video_file_rounded : Icons.video_library_outlined, 
              size: 80.sp, 
              color: _selectedVideo != null ? const Color(0xFF96A53A) : Colors.grey,
            ),
            20.verticalSpace,
            if (_selectedVideo != null) ...[
              Text(
                "Video Selected Successfully!",
                style: TextStyle(fontSize: 14.sp, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              10.verticalSpace,
            ],
            ElevatedButton(
              onPressed: _pickVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF96A53A),
              ),
              child: Text(_selectedVideo != null ? "Change Video" : "Select Video from Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}