import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSummaryServiceRouter contracts', () {
    test('router file exports AiSummaryServiceRouter class', () {
      final String source = File(
        'lib/http/ai_summary_service_router.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('abstract final class AiSummaryServiceRouter'),
      );
    });

    test('summarizeUgcVideo dispatches to exactly three adapter paths', () {
      final String source = File(
        'lib/http/ai_summary_service_router.dart',
      ).readAsStringSync();
      final Iterable<Match> routeCases = RegExp(
        r'AiSummaryService\.(subtitleAi|multimodalAi|bilibiliLegacyDeprecated)\s*=>',
      ).allMatches(source);
      expect(routeCases.length, 3);
    });

    test('subtitleAi routes to BilibiliSubtitleSummaryAdapter', () {
      final String source = File(
        'lib/http/ai_summary_service_router.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r'AiSummaryService\.subtitleAi\s*=>\s*BilibiliSubtitleSummaryAdapter\.summarizeUgcVideo',
        ).hasMatch(source),
        isTrue,
      );
    });

    test('multimodalAi routes to BilibiliMultimodalSummaryAdapter', () {
      final String source = File(
        'lib/http/ai_summary_service_router.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r'AiSummaryService\.multimodalAi\s*=>\s*BilibiliMultimodalSummaryAdapter\.summarizeUgcVideo',
        ).hasMatch(source),
        isTrue,
      );
    });

    test(
      'bilibiliLegacyDeprecated routes to BilibiliLegacySummaryAdapter',
      () {
        final String source = File(
          'lib/http/ai_summary_service_router.dart',
        ).readAsStringSync();
        expect(
          RegExp(
            r'AiSummaryService\.bilibiliLegacyDeprecated\s*=>\s*BilibiliLegacySummaryAdapter\.summarizeUgcVideo',
          ).hasMatch(source),
          isTrue,
        );
      },
    );

    test('router has no implicit fallback', () {
      final String source = File(
        'lib/http/ai_summary_service_router.dart',
      ).readAsStringSync();
      expect(source.contains('default:'), isFalse);
      expect(source.contains('fallback'), isFalse);
    });
  });

  group('AiSummaryServiceResult sealed hierarchy', () {
    test('service_result.dart defines the full sealed class hierarchy', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();

      expect(source, contains('sealed class AiSummaryServiceResult'));
      expect(source, contains('class AiSummaryServiceSuccess'));
      expect(source, contains('sealed class AiSummaryServiceFailure'));
      expect(source, contains('class AiSummaryServiceMisconfigured'));
      expect(source, contains('class AiSummaryServiceUnavailable'));
      expect(source, contains('class AiSummaryServiceNoSubtitle'));
      expect(source, contains('class AiSummaryServiceProviderError'));
      expect(source, contains('class AiSummaryServiceLegacyError'));
    });

    test('AiSummaryServiceNoSubtitle extends AiSummaryServiceUnavailable', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();
      expect(
        source,
        contains(
          'class AiSummaryServiceNoSubtitle extends AiSummaryServiceUnavailable',
        ),
      );
    });

    test('AiSummaryServiceSuccess has data property', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();
      expect(source, contains('final AiConclusionResult data;'));
    });

    test('AiSummaryServiceFailure has nullable message property', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();
      expect(source, contains('final String? message;'));
    });

    test('isSuccess accessor is defined on AiSummaryServiceResult', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();
      expect(source, contains('bool get isSuccess'));
    });

    test('dataOrNull accessor is defined on AiSummaryServiceResult', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/service_result.dart',
      ).readAsStringSync();
      expect(source, contains('AiConclusionResult? get dataOrNull'));
    });
  });

  group('AiConclusionResult model contracts', () {
    test('model_result.dart defines AiConclusionResult', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/model_result.dart',
      ).readAsStringSync();
      expect(source, contains('class AiConclusionResult'));
      expect(source, contains('String? summary'));
      expect(source, contains('List<Outline>? outline'));
      expect(source, contains('List<Subtitle>? subtitle'));
    });

    test('fromJson factory exists', () {
      final String source = File(
        'lib/models_new/video/video_ai_conclusion/model_result.dart',
      ).readAsStringSync();
      expect(source, contains('factory AiConclusionResult.fromJson'));
    });
  });

  group('BilibiliSubtitleSummaryAdapter contracts', () {
    test('adapter file exports the class', () {
      final String source = File(
        'lib/http/bilibili_subtitle_summary_adapter.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('abstract final class BilibiliSubtitleSummaryAdapter'),
      );
    });

    test('summarizeUgcVideo takes bvid, cid, optional title', () {
      final String source = File(
        'lib/http/bilibili_subtitle_summary_adapter.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r'Future<AiSummaryServiceResult>\s+summarizeUgcVideo\(\{[^}]*required String bvid[^}]*required int cid[^}]*String\?\s+title',
        ).hasMatch(source),
        isTrue,
      );
    });

    test('adapter has _parseSummaryResponse helper', () {
      final String source = File(
        'lib/http/bilibili_subtitle_summary_adapter.dart',
      ).readAsStringSync();
      expect(source, contains('_parseSummaryResponse'));
      expect(source, contains('_tryParseConclusionJson'));
      expect(source, contains('_stripMarkdownCodeFence'));
      expect(source, contains('_extractJsonObject'));
    });
  });

  group('BilibiliMultimodalSummaryAdapter contracts', () {
    test('adapter file exports the class', () {
      final String source = File(
        'lib/http/bilibili_multimodal_summary_adapter.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('abstract final class BilibiliMultimodalSummaryAdapter'),
      );
    });

    test('adapter uses VideoHttp.ugcSummaryMp4Url', () {
      final String source = File(
        'lib/http/bilibili_multimodal_summary_adapter.dart',
      ).readAsStringSync();
      expect(source, contains('VideoHttp.ugcSummaryMp4Url('));
    });

    test('adapter uses OpenAiCompatibleMp4VideoInput.parse', () {
      final String source = File(
        'lib/http/bilibili_multimodal_summary_adapter.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('OpenAiCompatibleMp4VideoInput.parse(mp4Result.response);'),
      );
    });
  });

  group('BilibiliLegacySummaryAdapter contracts', () {
    test('adapter file exports the class', () {
      final String source = File(
        'lib/http/bilibili_legacy_summary_adapter.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('abstract final class BilibiliLegacySummaryAdapter'),
      );
    });

    test('adapter uses VideoHttp.aiConclusion', () {
      final String source = File(
        'lib/http/bilibili_legacy_summary_adapter.dart',
      ).readAsStringSync();
      expect(source, contains('VideoHttp.aiConclusion('));
    });

    test('adapter has _hasUsableConclusion helper', () {
      final String source = File(
        'lib/http/bilibili_legacy_summary_adapter.dart',
      ).readAsStringSync();
      expect(source, contains('_hasUsableConclusion'));
    });
  });

  group('OpenAiCompatibleSummaryProvider contracts', () {
    test('provider file exports the class', () {
      final String source = File(
        'lib/http/openai_compatible_summary_provider.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('abstract final class OpenAiCompatibleSummaryProvider'),
      );
    });

    test('provider has summarizeText method', () {
      final String source = File(
        'lib/http/openai_compatible_summary_provider.dart',
      ).readAsStringSync();
      expect(source, contains('summarizeText('));
    });

    test('provider has summarizeMultimodal method', () {
      final String source = File(
        'lib/http/openai_compatible_summary_provider.dart',
      ).readAsStringSync();
      expect(source, contains('summarizeMultimodal('));
    });

    test('provider has _extractResponseText helper', () {
      final String source = File(
        'lib/http/openai_compatible_summary_provider.dart',
      ).readAsStringSync();
      expect(source, contains('_extractResponseText'));
    });

    test('provider handles auth via Bearer token', () {
      final String source = File(
        'lib/http/openai_compatible_summary_provider.dart',
      ).readAsStringSync();
      expect(source, contains('HttpHeaders.authorizationHeader'));
      expect(source, contains(r"'Bearer ${config.apiKey.trim()}'"));
    });
  });

  group('VideoHttp new method contracts', () {
    test('video.dart has ugcSummaryMp4Url method', () {
      final String source = File('lib/http/video.dart').readAsStringSync();
      expect(
        source,
        contains('static Future<LoadingState<String>> ugcSummaryMp4Url('),
      );
    });

    test('video.dart has transcriptSubtitles method', () {
      final String source = File('lib/http/video.dart').readAsStringSync();
      expect(
        source,
        contains(
          'static Future<String?> transcriptSubtitles(String subtitleUrl)',
        ),
      );
    });

    test('video.dart has _processTranscriptList helper', () {
      final String source = File('lib/http/video.dart').readAsStringSync();
      expect(source, contains('_processTranscriptList'));
    });
  });

  group('api_hosts.dart contracts', () {
    test('api_hosts.dart defines ApiHostEntry', () {
      final String source = File(
        'lib/http/api_hosts.dart',
      ).readAsStringSync();
      expect(source, contains('class ApiHostEntry'));
      expect(source, contains('final String label;'));
      expect(source, contains('final String settingKey;'));
      expect(source, contains('final String defaultHost;'));
    });

    test('apiHostEntries contains all expected host entries', () {
      final String source = File(
        'lib/http/api_hosts.dart',
      ).readAsStringSync();
      expect(source, contains('const List<ApiHostEntry> apiHostEntries = ['));
      final Iterable<Match> entries = RegExp(
        r"label:\s*'[^']+',",
      ).allMatches(source);
      expect(entries.length, 12);
    });
  });

  group('custom_host_interceptor.dart contracts', () {
    test('interceptor extends Interceptor', () {
      final String source = File(
        'lib/http/custom_host_interceptor.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('class CustomHostInterceptor extends Interceptor'),
      );
    });

    test('interceptor rewrites URLs when custom hosts are configured', () {
      final String source = File(
        'lib/http/custom_host_interceptor.dart',
      ).readAsStringSync();
      expect(source, contains('options.baseUrl = hostMap[options.baseUrl]!;'));
      expect(source, contains('options.path = uri'));
      expect(source, contains(".replace("));
      expect(
        source,
        contains("scheme: customUri.scheme"),
      );
    });
  });

  group('hk_api_retry_interceptor.dart contracts', () {
    test('interceptor extends Interceptor', () {
      final String source = File(
        'lib/http/hk_api_retry_interceptor.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('class HkApiRetryInterceptor extends Interceptor'),
      );
    });

    test('interceptor handles -404 and -10403 response codes', () {
      final String source = File(
        'lib/http/hk_api_retry_interceptor.dart',
      ).readAsStringSync();
      expect(
        source,
        contains("data['code'] == -404"),
      );
      expect(
        source,
        contains("data['code'] == -10403"),
      );
    });
  });
}
