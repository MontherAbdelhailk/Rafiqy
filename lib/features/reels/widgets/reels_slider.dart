import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';

class ReelsSidebarActions extends StatelessWidget {
  final bool isAdmin; 
  final int loveCount;
  final int commentCount;
  final bool hasLoved;
  final bool commentsEnabled;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAdminAction;

  const ReelsSidebarActions({
    super.key,
    required this.isAdmin,
    required this.loveCount,
    required this.commentCount,
    required this.hasLoved,
    required this.commentsEnabled,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAdminAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          iconPath: "assets/images/solar--heart-linear.svg",
          label: "$loveCount",
          onTap: onLike,
          isLiked: hasLoved,
        ),
        18.verticalSpace,
        if (commentsEnabled) ...[
          _buildActionButton(
            iconPath: "assets/images/solar--chat-round-line-duotone.svg",
            label: "$commentCount",
            onTap: onComment,
          ),
          18.verticalSpace,
        ],
        _buildActionButton(
          iconPath: "assets/images/solar--plain-outline.svg",
          label: "Share",
          onTap: onShare,
        ),
        18.verticalSpace,
        
        GestureDetector(
          onTap: onAdminAction,
          child: AnimatedSwitcher( 
            duration: const Duration(milliseconds: 300),
            child: isAdmin
                ? Icon(Icons.delete, key: const ValueKey("delete"), color: Colors.white, size: 30.sp)
                : AppAvatar(
                    key: const ValueKey("logo"),
                    imageUrl: 'assets/images/admin_logo.svg',
                    radius: 15.r,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String iconPath, 
    required String label,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero, 
          constraints: const BoxConstraints(),
          icon: isLiked 
            ? Icon(Icons.favorite, color: Colors.red, size: 28.sp)
            : SvgPicture.asset(
                iconPath,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                width: 28.w,
                height: 28.w,
              ),
        ),
        4.verticalSpace, 
        Text(
          label,
          style: TextStyle(
            color: Colors.white, 
            fontSize: 12.sp,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}