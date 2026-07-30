import 'dart:async';

import 'package:flutter/material.dart';
import 'package:os_type/os_type.dart';

class BackwardSeekIndicator extends StatefulWidget {
  final ValueChanged<Duration> onSubmitted;
  final Duration duration;

  const BackwardSeekIndicator({
    super.key,
    required this.onSubmitted,
    required this.duration,
  });

  @override
  State<BackwardSeekIndicator> createState() => BackwardSeekIndicatorState();
}

class BackwardSeekIndicatorState extends State<BackwardSeekIndicator> {
  late Duration duration;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    duration = widget.duration;
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted(duration);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void increment() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted(duration);
    });
    setState(() {
      duration += widget.duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.fast_rewind,
          size: 24.0,
          color: Colors.white,
        ),
        const SizedBox(height: 8.0),
        Text(
          '快退${duration.inSeconds}秒',
          style: const TextStyle(
            fontSize: 12.0,
            color: Colors.white,
          ),
        ),
      ],
    );

    if (OS.isHarmony) {
      // 避免在 OHOS 视频 Surface 上创建覆盖半屏的渐变/Ink saveLayer。
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: increment,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xCC000000),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: indicator,
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        splashColor: const Color(0x44767676),
        onTap: increment,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x88767676),
                Color(0x00767676),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          alignment: Alignment.center,
          child: indicator,
        ),
      ),
    );
  }
}
