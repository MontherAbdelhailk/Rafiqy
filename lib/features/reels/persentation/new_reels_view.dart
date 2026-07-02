import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:rafiq/features/reels/logic/reels_cubit.dart';
import 'package:rafiq/features/reels/logic/reels_state.dart';

class NewReelView extends StatefulWidget {
  final XFile videoFile; 

  const NewReelView({super.key, required this.videoFile});

  @override
  State<NewReelView> createState() => _NewReelViewState();
}

class _NewReelViewState extends State<NewReelView> {
  late VideoPlayerController _videoController;
  late final TextEditingController _captionController;
  bool allowComments = true;
  bool isPublic = true;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    
    if (kIsWeb) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoFile.path));
    } else {
      _videoController = VideoPlayerController.file(File(widget.videoFile.path));
    }
    
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {}); 
        _videoController.setLooping(true);
        _videoController.play(); 
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose(); 
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        title:  Text("New Reel", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDark)),
        centerTitle: true,
        backgroundColor: AppColors.babypink,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        actions: [
          Padding(
            padding:  EdgeInsets.only(right: 20.w),
            child: Text(
              "Publish",
              style: AppTextStyles.bold20cairo.copyWith(color: AppColors.primaryNormal),
            ),
          ),
        ],
      ),
      body: BlocListener<ReelsCubit, ReelsState>(
        listener: (context, state) {
          if (state is ReelsLoaded && _isPublishing) {
            setState(() => _isPublishing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Reel published successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(); // Pop back to reels feed
          } else if (state is ReelsError && _isPublishing) {
            setState(() => _isPublishing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Upload failed: ${state.message}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // video preview
              AspectRatio(
                aspectRatio: 9 / 12,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: _videoController.value.isInitialized
                      ? VideoPlayer(_videoController)
                      : const Center(child: CircularProgressIndicator(color: Color(0xFF96A53A))),
                ),
              ),
              20.verticalSpace,

              // caption field
Stack(

  children: [
    TextField(
      
      controller: _captionController,
      maxLines: 1,
      decoration:
       InputDecoration(

        hintText: "Write a caption...",

        hintStyle: AppTextStyles.regular16cairo.copyWith(
          color: AppColors.grey6,
        ),
        contentPadding: EdgeInsets.fromLTRB(
          16.w,
          120.h, // مساحة لكلمة Caption
          16.w,
          20.h,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    ),

    Positioned(
      top: 12.h,
      left: 16.w,
      child: Text(
        "Caption",
        style: AppTextStyles.regular16cairo.copyWith(
          color: AppColors.grey6,
        ),
      ),
    ),
  ],
),              20.verticalSpace,

              // Allow Comments switch
              buildSettingRow(
                icon: Icons.chat_bubble_outline,
                title: "Allow Comments",
                value: allowComments,
                onChanged: (val) {
                  setState(() => allowComments = val);
                },
              ),

              // Public / Private switch
              buildSettingRow(
                icon: Icons.public,
                title: "Private/Public",
                value: isPublic,
                onChanged: (val) {
                  setState(() => isPublic = val);
                },
              ),
              
              30.verticalSpace,

              _isPublishing
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF96A53A)))
                  : CustomButton(
                    borderRadius: 10.r,
                      text: 'Publish',
                      onPressed: () {
                        final caption = _captionController.text.trim();
                        if (caption.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please write a caption")),
                          );
                          return;
                        }
                        setState(() => _isPublishing = true);
                        context.read<ReelsCubit>().publishReel(
                              widget.videoFile,
                              caption,
                              isPublic,
                              allowComments,
                            );
                      },
                      backgroundColor: AppColors.primaryNormal,
                      textColor: Colors.white,
                      height: 50.h,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSettingRow({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      width: 600.w,
      height: 80.h,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.ligthgrey1, 
        borderRadius: BorderRadius.circular(15), 
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(10), 
          ),
        child: Icon(icon, color: AppColors.primaryDarkHover, size: 22),
        ),
      title: Text(
        title,
        style:AppTextStyles.bold14cairo.copyWith(color: AppColors.black3)
      ),
              trailing: Switch(
          value: value,
          onChanged: onChanged,
thumbColor: WidgetStateProperty.all(Colors.white), 
  
  activeTrackColor: AppColors.primaryNormal, 
  inactiveTrackColor: AppColors.ligthgrey1,        ),
      ),
    );
  }
}