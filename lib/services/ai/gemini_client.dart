import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiClient {
  GeminiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get apiKey => dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  String get model => dotenv.env['GEMINI_MODEL']?.trim() ?? 'gemini-2.0-flash';
  List<String> get models {
    final configured = [
      model,
      ...?dotenv.env['GEMINI_FALLBACK_MODELS']
          ?.split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-2.0-flash-lite',
    ];
    return configured.toSet().toList();
  }

  bool get isConfigured => apiKey.isNotEmpty;

  Future<String> generateText({
    required String prompt,
    String systemInstruction = '',
    double temperature = 0.72,
    int topK = 35,
    double topP = 0.92,
    int maxOutputTokens = 1600,
    Duration timeout = const Duration(seconds: 38),
  }) async {
    if (!isConfigured) {
      throw const GeminiClientException('Gemini n’est pas configuré.');
    }

    final text =
        systemInstruction.trim().isEmpty
            ? prompt
            : '$systemInstruction\n\n$prompt';

    GeminiClientException? lastError;
    for (final candidateModel in models) {
      late final http.Response response;
      try {
        response = await _postToModel(
          candidateModel,
          text,
          temperature: temperature,
          topK: topK,
          topP: topP,
          maxOutputTokens: maxOutputTokens,
          timeout: timeout,
        );
      } catch (e) {
        lastError = GeminiClientException(
          'Gemini ne répond pas pour le moment.',
          isNetworkError: true,
          cause: e,
        );
        continue;
      }

      if (response.statusCode == 404) {
        debugPrint('Gemini model introuvable: $candidateModel');
        lastError = GeminiClientException(
          'Modèle Gemini indisponible: $candidateModel.',
          statusCode: response.statusCode,
        );
        continue;
      }

      if (response.statusCode == 429) {
        final retryDelay = _extractRetryDelay(response.body);
        debugPrint(
          'Quota Gemini dépassé pour $candidateModel'
          '${retryDelay == null ? '' : ' (réessai conseillé dans ${retryDelay.inSeconds}s)'}.',
        );
        lastError = GeminiClientException(
          'Quota Gemini dépassé.',
          statusCode: response.statusCode,
          isQuotaExceeded: true,
          retryDelay: retryDelay,
        );
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Gemini ${response.statusCode}: ${_extractErrorMessage(response.body)}',
        );
        throw GeminiClientException(
          'Gemini indisponible (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return _extractText(response.body);
    }

    throw lastError ??
        const GeminiClientException('Aucun modèle Gemini disponible.');
  }

  Future<http.Response> _postToModel(
    String candidateModel,
    String text, {
    required double temperature,
    required int topK,
    required double topP,
    required int maxOutputTokens,
    required Duration timeout,
  }) {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$candidateModel:generateContent?key=$apiKey',
    );

    return _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': text},
                ],
              },
            ],
            'generationConfig': {
              'temperature': temperature,
              'topK': topK,
              'topP': topP,
              'maxOutputTokens': maxOutputTokens,
            },
            'safetySettings': const [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
            ],
          }),
        )
        .timeout(timeout);
  }

  String _extractText(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    final parts =
        candidates?.isNotEmpty == true
            ? (candidates!.first['content']?['parts'] as List?)
            : null;
    final generated =
        parts?.isNotEmpty == true ? parts!.first['text']?.toString() : null;

    if (generated == null || generated.trim().isEmpty) {
      throw const GeminiClientException('Gemini a retourné une réponse vide.');
    }

    return generated.trim();
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['error']?['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }

  Duration? _extractRetryDelay(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final details = decoded['error']?['details'] as List?;
      if (details == null) return null;

      for (final detail in details) {
        if (detail is! Map) continue;
        final retryDelay = detail['retryDelay']?.toString();
        if (retryDelay == null || !retryDelay.endsWith('s')) continue;

        final seconds = double.tryParse(
          retryDelay.substring(0, retryDelay.length - 1),
        );
        if (seconds != null) {
          return Duration(milliseconds: (seconds * 1000).round());
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

class GeminiClientException implements Exception {
  const GeminiClientException(
    this.message, {
    this.statusCode,
    this.isQuotaExceeded = false,
    this.isNetworkError = false,
    this.retryDelay,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final bool isQuotaExceeded;
  final bool isNetworkError;
  final Duration? retryDelay;
  final Object? cause;

  @override
  String toString() => message;
}
