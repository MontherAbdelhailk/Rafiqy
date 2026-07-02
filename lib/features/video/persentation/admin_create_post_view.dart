import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_state.dart';

class CreatePostView extends StatefulWidget {
  final XFile? videoFile;
  final VideoEntity? videoToEdit;

  const CreatePostView({super.key, this.videoFile, this.videoToEdit});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  
  VideoPlayerController? _videoController;
  XFile? _selectedVideoFile;
  XFile? _selectedCoverImageFile;
  
  String _selectedCategory = 'Parenting';
  String _selectedSubcategory = 'Early Foundation';
  bool _isPublic = true;
  bool _isLoading = false;

  final Map<String, List<String>> _categorySubcategories = {
    'Parenting': [
      'Early Foundation',
      'Behavior Control',
      'Middle Childhood',
      'Pre-Adolescence',
      'Early Adolescence',
      'Late Adolescence',
      'Transition to Maturity'
    ],
    'Marital Relationships': [
      'Before Divorce',
      'After Divorce',
      'Youth (21–30)'
    ],
    'Youth (21–30)': [
      'Youth (21–30)'
    ]
  };

  bool get _isEditMode => widget.videoToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedVideoFile = widget.videoFile;

    if (_isEditMode) {
      final video = widget.videoToEdit!;
      _titleController.text = video.title;
      _descController.text = video.description;
      _tagsController.text = video.tags.join(', ');
      _isPublic = video.isPublic;
      
      // Determine selected category & subcategory from video.tag/subCategory
      if (_categorySubcategories.containsKey(video.tag)) {
        _selectedCategory = video.tag;
      }
      final subs = _categorySubcategories[_selectedCategory] ?? [];
      if (subs.contains(video.subCategory)) {
        _selectedSubcategory = video.subCategory;
      } else if (subs.isNotEmpty) {
        _selectedSubcategory = subs.first;
      }
    } else {
      _selectedSubcategory = _categorySubcategories[_selectedCategory]!.first;
    }

    _initializeVideo();
  }

  void _initializeVideo() {
    if (_selectedVideoFile != null) {
      _videoController = VideoPlayerController.file(File(_selectedVideoFile!.path))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        }).catchError((error) {
          debugPrint("Video Player Error: $error");
        });
    } else if (_isEditMode && widget.videoToEdit!.videoUrl.isNotEmpty) {
      String path = widget.videoToEdit!.videoUrl;
      String absoluteVideoUrl = path;
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        final cleanPath = path.startsWith('/') ? path : '/$path';
        absoluteVideoUrl = 'http://10.238.1.136:5000$cleanPath';
      }
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(absoluteVideoUrl))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        }).catchError((error) {
          debugPrint("Video Player Error: $error");
        });
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedCoverImageFile = image;
      });
    }
  }

  Future<void> _pickNewVideo() async {
    final XFile? video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      _videoController?.dispose();
      setState(() {
        _selectedVideoFile = video;
        _videoController = null;
      });
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: _buildAppBar(context),
      body: BlocListener<AdminVideoCubit, AdminVideoState>(
        listener: (context, state) {
          if (state is AddVideoLoading) {
            setState(() => _isLoading = true);
          } else if (state is AddVideoSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditMode ? "Video updated successfully" : "Video published successfully"),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminVideoCubit>().fetchAdminVideos();
            Navigator.pop(context);
          } else if (state is AddVideoError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaPreview(),
                  20.verticalSpace,
                  
                  _buildLabel("Title"),
                  10.verticalSpace,
                  _buildTextField(_titleController, "Give your post a name..."),
                  20.verticalSpace,
                  
                  _buildLabel("Description"),
                  10.verticalSpace,
                  _buildTextField(_descController, "Share insights and tips...", maxLines: 4),
                  20.verticalSpace,

                  // Cover Image Picker
                  _buildLabel("Cover Image"),
                  10.verticalSpace,
                  _buildCoverImagePickerSection(),
                  20.verticalSpace,

                  // Dropdowns Category & Subcategory
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Category"),
                            10.verticalSpace,
                            _buildCategoryDropdown(),
                          ],
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Age Stage/Subcategory"),
                            10.verticalSpace,
                            _buildSubcategoryDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  20.verticalSpace,

                  // Comma-separated Tags Field
                  _buildLabel("Tags (comma separated)"),
                  10.verticalSpace,
                  _buildTextField(_tagsController, "parenting, children, communication"),
                  20.verticalSpace,

                  // Public/Private Switch
                  _buildVisibilitySwitch(),
                  30.verticalSpace,
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryNormal),
                ),
              )
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.babypink,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        _isEditMode ? "Edit Video" : "Create Post", 
        style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => _submitPost(),
          child: Text(
            _isEditMode ? "Save" : "Post",
            style: AppTextStyles.bold20cairo.copyWith(
              color: _isLoading ? Colors.grey : AppColors.primaryNormal,
            ),
          ),
        )
      ],
    );
  }

  void _submitPost() {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Description is required")));
      return;
    }

    if (!_isEditMode) {
      if (_selectedVideoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video file is required")));
        return;
      }
      if (_selectedCoverImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cover image is required")));
        return;
      }
    }

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_isEditMode) {
      final updatedVideo = VideoEntity(
        id: widget.videoToEdit!.id,
        title: title,
        description: description,
        thumbnailUrl: widget.videoToEdit!.thumbnailUrl,
        videoUrl: widget.videoToEdit!.videoUrl,
        duration: widget.videoToEdit!.duration,
        views: widget.videoToEdit!.views,
        likes: widget.videoToEdit!.likes,
        tag: _selectedCategory,
        subCategory: _selectedSubcategory,
        isPublic: _isPublic,
        tags: tags,
      );

      context.read<AdminVideoCubit>().editExistingVideo(
            updatedVideo,
            _selectedVideoFile,
            _selectedCoverImageFile,
          );
    } else {
      final newPost = VideoEntity(
        id: '',
        title: title,
        description: description,
        thumbnailUrl: '',
        videoUrl: '',
        duration: '02:00',
        views: '0',
        likes: '0',
        tag: _selectedCategory,
        subCategory: _selectedSubcategory,
        isPublic: _isPublic,
        tags: tags,
      );

      context.read<AdminVideoCubit>().addNewVideo(
            newPost,
            _selectedVideoFile!,
            _selectedCoverImageFile!,
          );
    }
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            _videoController != null && _videoController!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primaryNormal)),
            
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: GestureDetector(
                onTap: _pickNewVideo,
                child: _buildCircleIcon(Icons.edit, Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImagePickerSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.ligthgrey, width: 2.w),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: _selectedCoverImageFile != null
                ? Image.file(
                    File(_selectedCoverImageFile!.path),
                    width: 70.w,
                    height: 70.w,
                    fit: BoxFit.cover,
                  )
                : _isEditMode && widget.videoToEdit!.thumbnailUrl.isNotEmpty
                    ? _buildCoverThumbnail(widget.videoToEdit!.thumbnailUrl)
                    : Container(
                        color: Colors.grey[200],
                        width: 70.w,
                        height: 70.w,
                        child: const Icon(Icons.image),
                      ),
          ),
          16.horizontalSpace,
          Expanded(
            child: ElevatedButton(
              onPressed: _pickCoverImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4D35D),
                elevation: 0,
              ),
              child: const Text("Select Cover Image", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 70.w,
        height: 70.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], width: 70.w, height: 70.w, child: const Icon(Icons.broken_image)),
      );
    } else if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final fullUrl = 'http://10.238.1.136:5000$cleanPath';
      return Image.network(
        fullUrl,
        width: 70.w,
        height: 70.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], width: 70.w, height: 70.w, child: const Icon(Icons.broken_image)),
      );
    } else {
      return Image.asset(
        path,
        width: 70.w,
        height: 70.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], width: 70.w, height: 70.w, child: const Icon(Icons.broken_image)),
      );
    }
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.ligthgrey, width: 2.w),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          onChanged: (String? val) {
            if (val != null) {
              setState(() {
                _selectedCategory = val;
                _selectedSubcategory = _categorySubcategories[_selectedCategory]!.first;
              });
            }
          },
          items: _categorySubcategories.keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: AppTextStyles.regular16cairo),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubcategoryDropdown() {
    final subcategories = _categorySubcategories[_selectedCategory] ?? [];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.ligthgrey, width: 2.w),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
  value: _selectedSubcategory,
  isExpanded: true,
          
          onChanged: (String? val) {
            if (val != null) {
              setState(() {
                _selectedSubcategory = val;
              });
            }
          },
          items: subcategories.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: AppTextStyles.regular16cairo, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVisibilitySwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.ligthgrey, width: 2.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_isPublic ? Icons.public : Icons.public_off, color: AppColors.primaryNormal),
              12.horizontalSpace,
              Text(
                _isPublic ? "Public Video" : "Private Video",
                style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
              ),
            ],
          ),
          Switch(
            value: _isPublic,
            onChanged: (val) {
              setState(() {
                _isPublic = val;
              });
            },
            activeThumbColor: const Color(0xFF96A53A),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey10),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.ligthgrey, width: 2.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.ligthgrey, width: 2.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: const Color(0xFFC4D35D), width: 1.5.w),
        ),
      ),
    );
  }

Widget _buildLabel(String text) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: AppTextStyles.bold14cairo.copyWith(
    color: AppColors.secondaryNormal,
  ),
);
  Widget _buildCircleIcon(IconData icon, Color bg) => CircleAvatar(
        radius: 16.r,
        backgroundColor: bg,
        child: Icon(icon, size: 16.sp, color: Colors.white),
      );
}

// Simple list filter helper
extension FilterList<T> on List<T> {
  List<T> filter(bool Function(T element) test) {
    final List<T> result = <T>[];
    for (final T element in this) {
      if (test(element)) {
        result.add(element);
      }
    }
    return result;
  }
}