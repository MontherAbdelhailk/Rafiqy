import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool? isAdmin;
  final String? name;
  final VoidCallback? onTap;

  // Global update timestamp to append to URLs for cache busting
  static String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

  /// Forces all network images to fetch a fresh version by updating the cache buster
  static void refreshCache() {
    _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  }

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.isAdmin,
    this.name,
    this.onTap,
  });

  bool get _isUserAdmin {
    if (isAdmin == true) return true;
    final url = imageUrl?.toLowerCase() ?? '';
    final lowerName = name?.toLowerCase() ?? '';
    return url.contains('admin') || url.contains('logo') || lowerName == 'rafiqy' || lowerName == 'rafiq';
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Normalize relative paths
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return 'http://10.0.2.2:5000$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    final url = imageUrl ?? '';
    final isSvg = url.toLowerCase().endsWith('.svg');

    if (url.isEmpty) {
      // Empty URL - Show Local Asset Fallback
      if (_isUserAdmin) {
        avatarChild = SvgPicture.asset(
          'assets/images/admin_logo.svg',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        );
      } else {
        avatarChild = Image.asset(
          'assets/images/default_user.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        );
      }
    } else if (url.startsWith('assets/')) {
      // Local asset path
      if (isSvg) {
        avatarChild = SvgPicture.asset(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        );
      } else {
        avatarChild = Image.asset(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        );
      }
    } else {
      // Network URL
      final normalized = _normalizeUrl(url);
      final urlWithCacheBuster = normalized.contains('?')
          ? '$normalized&t=$_cacheBuster'
          : '$normalized?t=$_cacheBuster';

      if (isSvg || normalized.toLowerCase().endsWith('.svg')) {
        avatarChild = SvgPicture.network(
          urlWithCacheBuster,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholderBuilder: (BuildContext context) => SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      } else {
        avatarChild = Image.network(
          urlWithCacheBuster,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Error Fallback - use local defaults
            if (_isUserAdmin) {
              return SvgPicture.asset(
                'assets/images/admin_logo.svg',
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              );
            } else {
              return Image.asset(
                'assets/images/default_user.png',
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              );
            }
          },
        );
      }
    }

    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLightActive,
      ),
      child: ClipOval(
        child: avatarChild,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
