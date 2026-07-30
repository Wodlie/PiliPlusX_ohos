import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:os_type/os_type.dart';

class AppBarAni extends StatelessWidget {
  const AppBarAni({
    super.key,
    required this.child,
    required this.controller,
    required this.isTop,
    required this.isFullScreen,
  });

  final Widget child;
  final AnimationController controller;
  final bool isTop;
  final bool isFullScreen;

  static final _topPos = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  );

  static const _topDecoration = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  static final _bottomPos = Tween<Offset>(
    begin: const Offset(0, 1.2),
    end: Offset.zero,
  );

  static const _bottomDecoration = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  @override
  Widget build(BuildContext context) {
    final safeAreaChild = ViewSafeArea(
      left: isFullScreen,
      right: isFullScreen,
      child: child,
    );

    return SlideTransition(
      position: controller.drive(isTop ? _topPos : _bottomPos),
      // OHOS/Impeller 在视频 Surface 上合成透明渐变时可能把 shader
      // 的离屏缓冲区显示为灰白矩形。控制条本身仍保留滑入/滑出动画，
      // 仅在 HarmonyOS 上跳过背景渐变层。
      child: OS.isHarmony
          ? safeAreaChild
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: isTop ? _topDecoration : _bottomDecoration,
              ),
              child: safeAreaChild,
            ),
    );
  }
}
