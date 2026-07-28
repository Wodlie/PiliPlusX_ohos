import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloatingNavigationBar', () {
    Widget buildBar({
      required int selectedIndex,
      ValueChanged<int>? onDestinationSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FloatingNavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders all destinations', (tester) async {
      await tester.pumpWidget(buildBar(selectedIndex: 0));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('highlights selected destination', (tester) async {
      await tester.pumpWidget(buildBar(selectedIndex: 1));

      // The selected index should be 1 (Search)
      final bar = tester.widget<FloatingNavigationBar>(
        find.byType(FloatingNavigationBar),
      );
      expect(bar.selectedIndex, equals(1));
    });

    testWidgets('calls onDestinationSelected when tapped', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        buildBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      // Tap on the Search destination
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });

    testWidgets('asserts at least 2 destinations', (tester) async {
      expect(
        () => FloatingNavigationBar(
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          ],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('asserts valid selectedIndex', (tester) async {
      expect(
        () => FloatingNavigationBar(
          selectedIndex: 5,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
        throwsAssertionError,
      );
    });
  });
}