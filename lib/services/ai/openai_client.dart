import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiClient {
  OpenAiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get apiKey => dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
  String get model => dotenv.env['OPENAI_MODEL']?.trim() ?? 'gpt-4o-mini';
  List<String> get models {
    final configured = [
      model,
      ...?dotenv.env['OPENAI_FALLBACK_MODELS']
          ?.split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      'gpt-4o-mini',
      'gpt-4.1-mini',
    ];
    return configured.toSet().toList();
  }

  bool get isConfigured => apiKey.isNotEmpty;

  Future<String> generateText({
    required String prompt,
    String systemInstruction = '',
    double temperature = 0.72,
    double topP = 0.92,
    int maxOutputTokens = 1600,
    Duration timeout = const Duration(seconds: 38),
  }) async {
    if (!isConfigured) {
      throw const OpenAiClientException('OpenAI n’est pas configuré.');
    }

    OpenAiClientException? lastError;
    for (final candidateModel in models) {
      late final http.Response response;
      try {
        response = await _postToModel(
          candidateModel,
          prompt,
          systemInstruction: systemInstruction,
          temperature: temperature,
          topP: topP,
          maxOutputTokens: maxOutputTokens,
          timeout: timeout,
        );
      } catch (e) {
        lastError = OpenAiClientException(
          'OpenAI ne répond pas pour le moment.',
          isNetworkError: true,
          cause: e,
        );
        continue;
      }

      if (response.statusCode == 404) {
        debugPrint('OpenAI model introuvable: $candidateModel');
        lastError = OpenAiClientException(
          'Modèle OpenAI indisponible: $candidateModel.',
          statusCode: response.statusCode,
        );
        continue;
      }

      if (response.statusCode == 429) {
        debugPrint('Quota OpenAI dépassé pour $candidateModel.');
        lastError = OpenAiClientException(
          'Quota OpenAI dépassé.',
          statusCode: response.statusCode,
          isQuotaExceeded: true,
        );
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'OpenAI ${response.statusCode}: ${_extractErrorMessage(response.body)}',
        );
        throw OpenAiClientException(
          'OpenAI indisponible (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return _extractText(response.body);
    }

    throw lastError ??
        const OpenAiClientException('Aucun modèle OpenAI disponible.');
  }

  Future<http.Response> _postToModel(
    String candidateModel,
    String prompt, {
    required String systemInstruction,
    required double temperature,
    required double topP,
    required int maxOutputTokens,
    required Duration timeout,
  }) {
    return _client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': candidateModel,
            if (systemInstruction.trim().isNotEmpty)
              'instructions': systemInstruction,
            'input': prompt,
            'temperature': temperature,
            'top_p': topP,
            'max_output_tokens': maxOutputTokens,
          }),
        )
        .timeout(timeout);
  }

  String _extractText(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final directText = decoded['output_text']?.toString();
    if (directText != null && directText.trim().isNotEmpty) {
      return directText.trim();
    }

    final output = decoded['output'] as List?;
    if (output != null) {
      final buffer = StringBuffer();
      for (final item in output) {
        if (item is! Map<String, dynamic>) continue;
        final content = item['content'] as List?;
        if (content == null) continue;

        for (final part in content) {
          if (part is! Map<String, dynamic>) continue;
          final text = part['text']?.toString();
          if (text != null && text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) buffer.write('\n');
            buffer.write(text.trim());
          }
        }
      }

      if (buffer.isNotEmpty) return buffer.toString();
    }

    throw const OpenAiClientException('OpenAI a retourné une réponse vide.');
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['error']?['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}

class OpenAiClientException implements Exception {
  const OpenAiClientException(
    this.message, {
    this.statusCode,
    this.isQuotaExceeded = false,
    this.isNetworkError = false,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final bool isQuotaExceeded;
  final bool isNetworkError;
  final Object? cause;

  @override
  String toString() => message;
}
