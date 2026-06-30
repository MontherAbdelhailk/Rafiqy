import 'package:flutter/material.dart';

class AppGenericCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final double? padding;
  final double? borderRadius;
  final Border? border;
  final BoxShadow? shadow;
  final VoidCallback? onTap;

  const AppGenericCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.borderRadius,
    this.border,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        border: border,
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
        boxShadow: shadow != null ? [shadow!] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 0),
          child: Padding(
            padding: EdgeInsets.all(padding ?? 0),
            child: child,
          ),
        ),
      ),
    );
  }
}