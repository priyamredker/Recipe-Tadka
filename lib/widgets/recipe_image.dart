import 'dart:convert';

import 'package:flutter/material.dart';

class RecipeImage extends StatelessWidget {
  final String imageUrl;
  final BorderRadius? borderRadius;

  const RecipeImage({
    super.key,
    required this.imageUrl,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    if (imageUrl.startsWith('data:image')) {
      final data = imageUrl.split(',').last;
      final bytes = base64Decode(data);
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FallbackImage(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _FallbackImage(),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepOrange.shade50,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.deepOrange),
      ),
    );
  }
}

