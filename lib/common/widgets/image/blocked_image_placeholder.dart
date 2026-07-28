import 'package:flutter/material.dart';

class BlockedImagePlaceholder extends StatelessWidget {
  const BlockedImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.block_outlined,
          size: 28,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}
