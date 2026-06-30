import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart';

class VideoCard extends StatelessWidget {
  final VideoEntity video;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return 
    Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AppGenericCard(
        onTap: onTap,
        color: Colors.white,
        borderRadius: 16.r,
        shadow: const BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnailStack(),
            _buildCardInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: _buildThumbnailImage(),
        ),
        CircleAvatar(
          radius: 25.r,
          backgroundColor: const Color(0xFFC4D35D).withOpacity(0.9),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
        ),
        Positioned(
          bottom: 10.h,
          right: 10.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              video.duration,
              style: TextStyle(color: Colors.white, fontSize: 12.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardInfo() {
    return Padding(
      padding: EdgeInsets.all(28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(video.title, style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack)),
          4.verticalSpace,
          Text(
            video.description,
            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
            maxLines: 2,
          ),
          12.verticalSpace,
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: AppColors.lightYellow),
              6.horizontalSpace,
              Text(
                video.tag,
                style: AppTextStyles.bold14cairo.copyWith(color: AppColors.lightYellow),
              ),
              if (onEdit != null || onDelete != null) ...[
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.lightGreen),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (onEdit != null && onDelete != null) 12.horizontalSpace,
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage() {
    final path = video.thumbnailUrl;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: Colors.grey[200],
          height: 180.h,
          width: double.infinity,
          child: const Icon(Icons.broken_image),
        ),
      );
    } else if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final fullUrl = 'http://10.0.2.2:5000$cleanPath';
      return Image.network(
        fullUrl,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: Colors.grey[200],
          height: 180.h,
          width: double.infinity,
          child: const Icon(Icons.broken_image),
        ),
      );
    } else {
      return Image.asset(
        path,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: Colors.grey[200],
          height: 180.h,
          width: double.infinity,
          child: const Icon(Icons.broken_image),
        ),
      );
    }
  }
}