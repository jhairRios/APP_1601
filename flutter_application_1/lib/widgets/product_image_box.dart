import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'flexible_image.dart';

/// Standardized product image box: rounded corners, white padded background,
/// and BoxFit.contain to avoid cropping or distortion.
class ProductImageBox extends StatelessWidget {
  final String? source;
  final String? name;
  final double borderRadius;
  final EdgeInsets padding;
  final double? height;
  final double? maxHeight;
  final Color backgroundColor;
  final Uint8List? bytes;

  const ProductImageBox({
    super.key,
    this.source,
    this.name,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(8),
    this.height,
    this.maxHeight,
    this.backgroundColor = Colors.white,
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (bytes != null) {
      inner = Image.memory(
        bytes!,
        fit: BoxFit.contain,
      );
    } else {
      inner = FlexibleImage(
        source: source,
        name: name ?? '',
        fit: BoxFit.contain,
      );
    }

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        color: backgroundColor,
        padding: padding,
        child: Center(child: inner),
      ),
    );

    if (height != null) {
      content = SizedBox(
        height: height,
        width: double.infinity,
        child: content,
      );
    } else if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight!,
        ),
        child: content,
      );
    }

    return content;
  }
}
