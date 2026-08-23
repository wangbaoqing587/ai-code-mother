import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:starvive/core/constants/app_constants.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5FBF8),
                Color(0xFFF0F9FF),
                Color(0xFFFFFEF5),
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _blob(520, AppColors.mintLight.withValues(alpha: 0.45)),
        ),
        Positioned(
          top: 40,
          right: -100,
          child: _blob(480, AppColors.skyLight.withValues(alpha: 0.35)),
        ),
        Positioned(
          bottom: 80,
          left: MediaQuery.sizeOf(context).width / 2 - 180,
          child: _blob(360, AppColors.yellowLight.withValues(alpha: 0.28)),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback = AppAssets.productCoverDefault,
  });

  final String? url;
  final BoxFit fit;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Image.asset(fallback, fit: fit);
    }
    if (url!.startsWith('data:image')) {
      try {
        final base64Str = url!.contains(',') ? url!.split(',').last : url!;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          errorBuilder: (_, __, ___) => Image.asset(fallback, fit: fit),
        );
      } catch (_) {
        return Image.asset(fallback, fit: fit);
      }
    }
    if (!url!.startsWith('http')) {
      return Image.asset(url!, fit: fit,
          errorBuilder: (_, __, ___) => Image.asset(fallback, fit: fit));
    }
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(fallback, fit: fit),
    );
  }
}
