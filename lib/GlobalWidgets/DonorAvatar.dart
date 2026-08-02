import 'package:blood_donation/Utils/profile_image_helper.dart';
import 'package:flutter/material.dart';

class DonorAvatar extends StatelessWidget {
  const DonorAvatar({
    super.key,
    required this.name,
    this.profilePic,
    this.size = 80,
    this.borderRadius,
    this.backgroundColor = Colors.cyan,
  });

  final String? name;
  final String? profilePic;
  final double size;
  final BorderRadius? borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProfileImageUrl(profilePic);
    final displayName = name?.trim() ?? '';
    final initial =
        displayName.isEmpty ? 'D' : displayName[0].toUpperCase();
    final radius = borderRadius ?? BorderRadius.circular(size * 0.125);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: size,
        width: size,
        color: backgroundColor,
        child: imageUrl == null
            ? Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Image.network(
                imageUrl,
                height: size,
                width: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
