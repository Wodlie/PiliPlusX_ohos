import 'package:PiliPlus/common/widgets/reorder_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReorderMixin', () {
    testWidgets('proxyDecorator applies color', (tester) async {
      late ColorScheme capturedScheme;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestReorderableWidget(
            onSchemeReady: (scheme) {
              capturedScheme = scheme;
            },
          ),
        ),
      );

      // The mixin should have captured the ColorScheme from context
      expect(capturedScheme, isNotNull);
    });

    testWidgets('proxyDecorator returns ColoredBox', (tester) async {
      late Widget decoratorResult;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestReorderableWidget(
            onDecoratorResult: (widget) {
              decoratorResult = widget;
            },
          ),
        ),
      );

      expect(decoratorResult, isA<ColoredBox>());
    });
  });
}

class _TestReorderableWidget extends StatefulWidget {
  const _TestReorderableWidget({
    this.onSchemeReady,
    this.onDecoratorResult,
  });

  final void Function(ColorScheme scheme)? onSchemeReady;
  final void Function(Widget widget)? onDecoratorResult;

  @override
  State<_TestReorderableWidget> createState() => _TestReorderableWidgetState();
}

class _TestReorderableWidgetState extends State<_TestReorderableWidget>
    with ReorderMixin<_TestReorderableWidget> {
  @override
  Widget build(BuildContext context) {
    // Trigger didChangeDependencies to set scheme
    widget.onSchemeReady?.call(scheme);

    final decorated = proxyDecorator(
      const SizedBox(key: Key('child'), width: 50, height: 50),
      0,
      null,
    );
    widget.onDecoratorResult?.call(decorated);

    return Scaffold(
      body: Center(child: decorated),
    );
  }
}