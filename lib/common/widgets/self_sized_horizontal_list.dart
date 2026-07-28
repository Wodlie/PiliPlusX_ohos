import 'package:PiliPlus/common/widgets/only_layout_widget.dart';
import 'package:flutter/material.dart';

class SelfSizedHorizontalList extends StatefulWidget {
  const SelfSizedHorizontalList({
    super.key,
    required this.itemCount,
    this.itemBuilder,
    this.separatorBuilder,
    this.childBuilder,
    this.gapSize,
    this.controller,
    this.padding,
  }) : assert(
          (itemBuilder != null && separatorBuilder != null) ||
              (childBuilder != null && gapSize != null),
          'Provide either itemBuilder+separatorBuilder or childBuilder+gapSize',
        );

  final int itemCount;
  final EdgeInsets? padding;
  final IndexedWidgetBuilder? itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final Widget Function(int index)? childBuilder;
  final double? gapSize;
  final ScrollController? controller;

  @override
  State<SelfSizedHorizontalList> createState() =>
      _SelfSizedHorizontalListState();
}

class _SelfSizedHorizontalListState extends State<SelfSizedHorizontalList> {
  double? _height;

  IndexedWidgetBuilder get _itemBuilder {
    if (widget.itemBuilder != null) return widget.itemBuilder!;
    final childBuilder = widget.childBuilder!;
    return (context, index) => childBuilder(index);
  }

  IndexedWidgetBuilder get _separatorBuilder =>
      widget.separatorBuilder ??
      (widget.gapSize != null
          ? (_, _) => SizedBox(width: widget.gapSize)
          : (_, _) => const SizedBox(width: 0));

  @override
  Widget build(BuildContext context) {
    if (_height == null) {
      return OnlyLayoutWidget(
        onPerformLayout: (Size size) {
          if (!mounted) return;
          _height = size.height;
          setState(() {});
        },
        child: Padding(
          padding: widget.padding ?? .zero,
          child: _itemBuilder(context, 0),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: widget.padding,
        itemCount: widget.itemCount,
        controller: widget.controller,
        itemBuilder: _itemBuilder,
        separatorBuilder: _separatorBuilder,
      ),
    );
  }
}
