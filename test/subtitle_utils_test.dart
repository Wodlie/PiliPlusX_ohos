import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/subtitle_utils.dart';

void main() {
  group('SubtitleUtils', () {
    group('json2Vtt', () {
      test('converts empty list to just WEBVTT header', () {
        expect(SubtitleUtils.json2Vtt([]), 'WEBVTT\n\n');
      });

      test('converts single subtitle entry', () {
        final result = SubtitleUtils.json2Vtt([
          {'from': 0.0, 'to': 2.5, 'content': 'Hello world'},
        ]);
        expect(result, 'WEBVTT\n\n00:00:00.000 --> 00:00:02.500\nHello world');
      });

      test('converts multiple subtitle entries', () {
        final result = SubtitleUtils.json2Vtt([
          {'from': 0.0, 'to': 2.5, 'content': 'Hello'},
          {'from': 3.0, 'to': 5.0, 'content': 'World'},
        ]);
        expect(
          result,
          'WEBVTT\n\n00:00:00.000 --> 00:00:02.500\nHello\n\n00:00:03.000 --> 00:00:05.000\nWorld',
        );
      });

      test('handles long durations correctly', () {
        final result = SubtitleUtils.json2Vtt([
          {'from': 3720.0, 'to': 3775.5, 'content': '1 hour 2 min'},
        ]);
        expect(
          result,
          'WEBVTT\n\n01:02:00.000 --> 01:02:55.500\n1 hour 2 min',
        );
      });

      test('trims content whitespace', () {
        final result = SubtitleUtils.json2Vtt([
          {'from': 1.0, 'to': 2.0, 'content': '  spaced text  '},
        ]);
        expect(
          result,
          'WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nspaced text',
        );
      });
    });

    group('json2Srt', () {
      test('converts empty list to empty string', () {
        expect(SubtitleUtils.json2Srt([]), '');
      });

      test('converts single subtitle entry', () {
        final result = SubtitleUtils.json2Srt([
          {'from': 0.0, 'to': 2.5, 'content': 'Hello world'},
        ]);
        expect(result, '1\n00:00:00,000 --> 00:00:02,500\nHello world');
      });

      test('converts multiple entries with sequential numbering', () {
        final result = SubtitleUtils.json2Srt([
          {'from': 0.0, 'to': 2.5, 'content': 'First'},
          {'from': 3.0, 'to': 5.0, 'content': 'Second'},
        ]);
        expect(
          result,
          '1\n00:00:00,000 --> 00:00:02,500\nFirst\n\n2\n00:00:03,000 --> 00:00:05,000\nSecond',
        );
      });

      test('handles milliseconds correctly', () {
        final result = SubtitleUtils.json2Srt([
          {'from': 1.234, 'to': 2.789, 'content': 'precision'},
        ]);
        expect(
          result,
          '1\n00:00:01,234 --> 00:00:02,789\nprecision',
        );
      });

      test('trims content whitespace', () {
        final result = SubtitleUtils.json2Srt([
          {'from': 1.0, 'to': 2.0, 'content': '  trimmed  '},
        ]);
        expect(result, '1\n00:00:01,000 --> 00:00:02,000\ntrimmed');
      });
    });

    group('SubtitleFormat enum', () {
      test('has correct labels', () {
        expect(SubtitleFormat.json.label, 'JSON');
        expect(SubtitleFormat.vtt.label, 'WEBVTT');
        expect(SubtitleFormat.srt.label, 'SRT');
      });
    });
  });
}
