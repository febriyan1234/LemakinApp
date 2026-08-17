import 'package:flutter/material.dart';

class SkeletalLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletalLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  factory SkeletalLoader.card({double? width, double height = 120}) {
    return SkeletalLoader(
      width: width ?? double.infinity,
      height: height,
      borderRadius: 16.0,
    );
  }

  factory SkeletalLoader.line({double? width, double height = 16}) {
    return SkeletalLoader(
      width: width ?? double.infinity,
      height: height,
      borderRadius: 4.0,
    );
  }

  @override
  State<SkeletalLoader> createState() => _SkeletalLoaderState();
}

class _SkeletalLoaderState extends State<SkeletalLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
