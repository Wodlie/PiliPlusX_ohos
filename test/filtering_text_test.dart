import 'package:PiliPlus/utils/filtering_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilteringText.decimal', () {
    late TextInputFormatter formatter;

    setUp(() {
      formatter = FilteringText.decimal.first;
    });

    test('allows digits', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '123'),
      );
      expect(result.text, '123');
    });

    test('allows decimal point', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '3.14'),
      );
      expect(result.text, '3.14');
    });

    test('rejects letters', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'abc'),
      );
      expect(result.text, '');
    });

    test('rejects letters interleaved with digits', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'a1b2c3'),
      );
      expect(result.text, '123');
    });

    test('rejects special characters', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '@#\$%'),
      );
      expect(result.text, '');
    });

    test('filters mixed input — keeps only digits and dots', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'a1b2.c3d'),
      );
      expect(result.text, '12.3');
    });

    test('allows multiple dots (regex does not restrict)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1.2.3'),
      );
      expect(result.text, '1.2.3');
    });

    test('rejects whitespace', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '12 34'),
      );
      expect(result.text, '1234');
    });

    test('preserves cursor position after filtering', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '12a34',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      // 'a' removed, so text becomes '1234', cursor adjusts
      expect(result.text, '1234');
      expect(result.selection.baseOffset, 4);
    });

    test('empty input stays empty', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue.empty,
      );
      expect(result.text, '');
    });
  });
}
