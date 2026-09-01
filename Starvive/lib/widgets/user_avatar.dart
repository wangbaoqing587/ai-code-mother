import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:starvive/core/constants/app_constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = 36,
    this.src,
    this.gender,
  });

  final double size;
  final String? src;
  final int? gender;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (src == null || src!.isEmpty) return _defaultImage();
    if (src!.startsWith('data:image')) {
      try {
        final base64Str = src!.contains(',') ? src!.split(',').last : src!;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultImage(),
        );
      } catch (_) {
        return _defaultImage();
      }
    }
    return Image.network(
      src!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultImage(),
    );
  }

  Widget _defaultImage() {
    final asset = gender == 0
        ? AppAssets.avatarDefaultFemale
        : AppAssets.avatarDefaultMale;
    return Image.asset(
      asset,
      fit: BoxFit.cover,
    );
  }
}
