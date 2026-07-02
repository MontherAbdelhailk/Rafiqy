import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart'; 
import 'package:rafiq/core/widgets/apptextformfield.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/Posts/models/comments.model.dart';
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class CreatePostSheet extends StatefulWidget {
  final PostEntity? postToEdit;
  const CreatePostSheet({super.key, this.postToEdit});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _postController = TextEditingController();
  String? _currentUserImage;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _postController.text = widget.postToEdit!.content;
    }
    
    SecureStorage.getProfileImage().then((url) {
      print("🔥🔥🔥 القيمة اللي جاية من الستورج هي: $url"); // دي أهم خطوة!
      if (mounted) {
        setState(() {
          _currentUserImage = url;
        });
      }
    });
    
    SecureStorage.getUsername().then((name) {
      if (mounted) {
        setState(() {
          _currentUserName = name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, 
      child: Container(
        width: 0.9.sw, 
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r), 
                    boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
           //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 22.sp, color: AppColors.darkblack),
                  visualDensity: VisualDensity.compact,
                ),

                   Padding(
                     padding: const EdgeInsets.only(left: 50  ),
                     child: Text(
                      widget.postToEdit != null ? "Edit Post" : "Create Post",
                      style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
                                       ),
                   ),

                   12.verticalSpace,                  
                
              ],
            ),
            const Divider(height: 1, thickness: 0.2), 
                               12.verticalSpace,                  
            
            
            Row(
              children: [

_currentUserImage != null && _currentUserImage!.isNotEmpty
    ? CircleAvatar(
        radius: 24.r, 
backgroundImage: NetworkImage(
  _currentUserImage!,
),      )
    : CircleAvatar(
        radius: 24.r, 
        child: const Icon(Icons.person),
      ),
                      12.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentUserName ?? "Rafiq", style: AppTextStyles.extrabold16cairo),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color:  AppColors.grey5, 
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "Admin",
                        style:  AppTextStyles.regular12cairo.copyWith(color: AppColors.grey12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            20.verticalSpace,

            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 150.h, 
                maxHeight: 300.h, 
              ),
              child: AppTextFormField(
                controller: _postController,
                hintText: "What's on your mind, Rafiq?",
                hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12),
                keyboardType: TextInputType.multiline,
                validator: (value) => null,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            
            25.verticalSpace,


            CustomButton(borderRadius: 10.r,
              text: widget.postToEdit != null ? 'Save Changes' : 'Publish Post',
              onPressed: () => _handlePublish(context),
              backgroundColor: AppColors.primaryNormal,
              textColor: Colors.white,
              height: 50.h,
            ),

          ],
        ),
      ),
    );
  }

  void _handlePublish(BuildContext context) {
    final text = _postController.text.trim();
    if (text.isNotEmpty) {
      if (widget.postToEdit != null) {
        context.read<PostsCubit>().updatePost(widget.postToEdit!.id, text);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post Updated Successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        context.read<PostsCubit>().createPost(text);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post Published Successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}