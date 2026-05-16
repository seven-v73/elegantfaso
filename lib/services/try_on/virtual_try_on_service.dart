import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/try_on/try_on_result.dart';

class VirtualTryOnService {
  VirtualTryOnService({
    http.Client? client,
    String? replicateApiKey,
    String? segmindApiKey,
  }) : _client = client ?? http.Client(),
       _replicateApiKey =
           replicateApiKey ?? dotenv.env['REPLICATE_API_KEY'] ?? '',
       _segmindApiKey = segmindApiKey ?? dotenv.env['SEGMIND_API_KEY'] ?? '';

  final http.Client _client;
  final String _replicateApiKey;
  final String _segmindApiKey;

  bool get hasConfiguredProvider =>
      _replicateApiKey.trim().isNotEmpty || _segmindApiKey.trim().isNotEmpty;

  static const _replicateModel =
      'yisol/idm-vton:c871bb9b046607b680449ecbae55fd8c6d945e0a1948644bf2361b3d021d3ff4';

  Future<TryOnResult> performVirtualTryOn({
    required File personImage,
    required File garmentImage,
    void Function(String)? onStatusUpdate,
  }) async {
    if (!await personImage.exists() || !await garmentImage.exists()) {
      return const TryOnResult(
        success: false,
        message:
            'Ajoutez votre photo et la pièce à essayer pour préparer l’aperçu.',
      );
    }

    if (!hasConfiguredProvider) {
      return const TryOnResult(
        success: false,
        message:
            'Le rendu assisté n’est pas disponible pour le moment. Utilisez l’aperçu libre pour continuer.',
      );
    }

    final services = <_TryOnProvider>[
      if (_replicateApiKey.trim().isNotEmpty)
        _TryOnProvider.replicate(_replicateApiKey),
      if (_segmindApiKey.trim().isNotEmpty)
        _TryOnProvider.segmind(_segmindApiKey),
    ];

    onStatusUpdate?.call('Préparation de votre rendu...');

    for (var i = 0; i < services.length; i++) {
      final service = services[i];
      onStatusUpdate?.call('Recherche du meilleur rendu...');
      final result = await _tryProvider(
        service,
        personImage,
        garmentImage,
        onStatusUpdate,
      );
      if (result.success || !result.tryNext || i == services.length - 1) {
        return result;
      }
    }

    return const TryOnResult(
      success: false,
      message:
          'Nous n’avons pas pu préparer le rendu assisté. L’aperçu libre reste disponible.',
    );
  }

  Future<TryOnResult> _tryProvider(
    _TryOnProvider provider,
    File personImage,
    File garmentImage,
    void Function(String)? onStatusUpdate,
  ) {
    return switch (provider.type) {
      _TryOnProviderType.replicate => _tryReplicate(
        provider,
        personImage,
        garmentImage,
        onStatusUpdate,
      ),
      _TryOnProviderType.segmind => _trySegmind(
        provider,
        personImage,
        garmentImage,
        onStatusUpdate,
      ),
    };
  }

  Future<TryOnResult> _tryReplicate(
    _TryOnProvider provider,
    File personImage,
    File garmentImage,
    void Function(String)? onStatusUpdate,
  ) async {
    try {
      final personBase64 = base64Encode(await _cleanImageBytes(personImage));
      final garmentBase64 = base64Encode(await _cleanImageBytes(garmentImage));

      onStatusUpdate?.call('Analyse de la silhouette...');
      final response = await _client
          .post(
            Uri.parse('https://api.replicate.com/v1/predictions'),
            headers: {
              'Authorization': 'Token ${provider.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'version': _replicateModel.split(':')[1],
              'input': {
                'human_img': 'data:image/jpeg;base64,$personBase64',
                'garm_img': 'data:image/jpeg;base64,$garmentBase64',
                'garment_des': 'A fashion garment',
                'is_checked': true,
                'is_checked_crop': false,
                'denoise_steps': 20,
                'seed': 42,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final predictionData =
            jsonDecode(response.body) as Map<String, dynamic>;
        return _waitForReplicateResult(
          predictionData['id']?.toString() ?? '',
          provider.apiKey,
          onStatusUpdate,
        );
      }
      return _handleApiError('Replicate', response);
    } catch (e) {
      debugPrint('Erreur Replicate: $e');
      return TryOnResult(
        success: false,
        message:
            'Le rendu assisté est indisponible pour le moment. Essayez l’aperçu libre.',
        tryNext: true,
      );
    }
  }

  Future<TryOnResult> _waitForReplicateResult(
    String predictionId,
    String apiKey,
    void Function(String)? onStatusUpdate,
  ) async {
    if (predictionId.isEmpty) {
      return const TryOnResult(
        success: false,
        message:
            'Le rendu n’a pas pu être préparé. Essayez une photo plus nette.',
        tryNext: true,
      );
    }

    for (var attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      onStatusUpdate?.call('Rendu en préparation... ${attempt + 1}/30');

      try {
        final response = await _client
            .get(
              Uri.parse(
                'https://api.replicate.com/v1/predictions/$predictionId',
              ),
              headers: {'Authorization': 'Token $apiKey'},
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status']?.toString() ?? '';

        if (status == 'succeeded') {
          final output = data['output'];
          final imageUrl =
              output is List && output.isNotEmpty
                  ? output.first.toString()
                  : output?.toString() ?? '';
          if (imageUrl.isEmpty) {
            return const TryOnResult(
              success: false,
              message:
                  'Le rendu n’a pas pu être finalisé. Essayez une autre photo.',
              tryNext: true,
            );
          }
          final imageResponse = await _client.get(Uri.parse(imageUrl));
          if (imageResponse.statusCode == 200) {
            return TryOnResult(
              success: true,
              data: imageResponse.bodyBytes,
              message: 'Votre rendu est prêt.',
            );
          }
        }

        if (status == 'failed') {
          return TryOnResult(
            success: false,
            message:
                'Le rendu n’a pas fonctionné avec cette photo. Essayez une image plus claire.',
            tryNext: true,
          );
        }
      } catch (e) {
        debugPrint('Vérification Replicate impossible: $e');
      }
    }

    return const TryOnResult(
      success: false,
      message:
          'Le rendu prend plus de temps que prévu. Réessayez plus tard ou utilisez l’aperçu libre.',
      tryNext: true,
    );
  }

  Future<TryOnResult> _trySegmind(
    _TryOnProvider provider,
    File personImage,
    File garmentImage,
    void Function(String)? onStatusUpdate,
  ) async {
    try {
      final personBase64 = base64Encode(await _cleanImageBytes(personImage));
      final garmentBase64 = base64Encode(await _cleanImageBytes(garmentImage));

      onStatusUpdate?.call('Création du rendu...');
      final response = await _client
          .post(
            Uri.parse('https://api.segmind.com/v1/idm-vton'),
            headers: {
              'x-api-key': provider.apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'human_img': 'data:image/jpeg;base64,$personBase64',
              'garm_img': 'data:image/jpeg;base64,$garmentBase64',
              'garment_des': 'A fashion garment',
              'is_checked': true,
              'is_checked_crop': false,
              'denoise_steps': 20,
              'seed': 42,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = jsonResponse['image']?.toString() ?? '';
        final imageResponse = await _client.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          return TryOnResult(
            success: true,
            data: imageResponse.bodyBytes,
            message: 'Votre rendu est prêt.',
          );
        }
      }
      return _handleApiError('Segmind', response);
    } catch (e) {
      debugPrint('Erreur Segmind: $e');
      return TryOnResult(
        success: false,
        message:
            'Le rendu assisté est indisponible pour le moment. Essayez l’aperçu libre.',
        tryNext: true,
      );
    }
  }

  Future<Uint8List> _cleanImageBytes(File file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    return base64Decode(base64Str);
  }

  TryOnResult _handleApiError(String serviceName, http.Response response) {
    if (response.statusCode == 401) {
      return TryOnResult(
        success: false,
        message:
            'Le rendu assisté n’est pas disponible pour le moment. Utilisez l’aperçu libre.',
      );
    }
    if (response.statusCode == 402) {
      return TryOnResult(
        success: false,
        message:
            'Le rendu assisté est temporairement limité. Utilisez l’aperçu libre pour continuer.',
        tryNext: true,
      );
    }
    if (response.statusCode == 429) {
      return TryOnResult(
        success: false,
        message:
            'Beaucoup de rendus sont en cours. Réessayez dans quelques instants.',
        tryNext: true,
      );
    }
    return TryOnResult(
      success: false,
      message:
          'Le rendu assisté est indisponible pour le moment. Utilisez l’aperçu libre.',
      tryNext: response.statusCode >= 500,
    );
  }
}

enum _TryOnProviderType { replicate, segmind }

class _TryOnProvider {
  const _TryOnProvider._(this.type, this.apiKey);

  factory _TryOnProvider.replicate(String apiKey) =>
      _TryOnProvider._(_TryOnProviderType.replicate, apiKey);

  factory _TryOnProvider.segmind(String apiKey) =>
      _TryOnProvider._(_TryOnProviderType.segmind, apiKey);

  final _TryOnProviderType type;
  final String apiKey;
}
