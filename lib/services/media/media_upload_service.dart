import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MediaUploadResult {
  final String url;
  final String publicId;
  final String resourceType;
  final int? width;
  final int? height;
  final int? bytes;
  final String optimizedUrl;
  final String thumbnailUrl;
  final String? mediaId;

  const MediaUploadResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.optimizedUrl,
    required this.thumbnailUrl,
    this.width,
    this.height,
    this.bytes,
    this.mediaId,
  });

  MediaUploadResult copyWithAssetId(String mediaId) {
    return MediaUploadResult(
      url: url,
      publicId: publicId,
      resourceType: resourceType,
      optimizedUrl: optimizedUrl,
      thumbnailUrl: thumbnailUrl,
      width: width,
      height: height,
      bytes: bytes,
      mediaId: mediaId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'secureUrl': url,
      'publicId': publicId,
      'resourceType': resourceType,
      'optimizedUrl': optimizedUrl,
      'thumbnailUrl': thumbnailUrl,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (bytes != null) 'bytes': bytes,
      'provider': 'cloudinary',
      if (mediaId != null) 'mediaId': mediaId,
    };
  }

  Map<String, dynamic> toAssetMap({
    required String ownerId,
    required String ownerRole,
    required String usage,
    String status = 'active',
    String? linkedCollection,
    String? linkedDocumentId,
  }) {
    return {
      ...toMap(),
      'ownerId': ownerId,
      'ownerRole': ownerRole,
      'usage': usage,
      'status': status,
      if (linkedCollection != null) 'linkedCollection': linkedCollection,
      if (linkedDocumentId != null) 'linkedDocumentId': linkedDocumentId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class MediaUploadService {
  MediaUploadService({
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
    String? imageUploadPreset,
    String? videoUploadPreset,
    String? fileUploadPreset,
    String? folderRoot,
  }) : _client = client ?? http.Client(),
       _cloudName = cloudName ?? dotenv.env['CLOUDINARY_CLOUD_NAME'],
       _uploadPreset = uploadPreset ?? dotenv.env['CLOUDINARY_UPLOAD_PRESET'],
       _imageUploadPreset =
           imageUploadPreset ??
           dotenv.env['CLOUDINARY_IMAGE_UPLOAD_PRESET'] ??
           uploadPreset ??
           dotenv.env['CLOUDINARY_UPLOAD_PRESET'],
       _videoUploadPreset =
           videoUploadPreset ??
           dotenv.env['CLOUDINARY_VIDEO_UPLOAD_PRESET'] ??
           uploadPreset ??
           dotenv.env['CLOUDINARY_UPLOAD_PRESET'],
       _fileUploadPreset =
           fileUploadPreset ??
           dotenv.env['CLOUDINARY_FILE_UPLOAD_PRESET'] ??
           uploadPreset ??
           dotenv.env['CLOUDINARY_UPLOAD_PRESET'],
       _folderRoot =
           folderRoot ?? dotenv.env['CLOUDINARY_FOLDER_ROOT'] ?? 'elegantstyle';

  final http.Client _client;
  final String? _cloudName;
  final String? _uploadPreset;
  final String? _imageUploadPreset;
  final String? _videoUploadPreset;
  final String? _fileUploadPreset;
  final String _folderRoot;

  bool get isConfigured =>
      (_cloudName?.isNotEmpty ?? false) &&
      ((_imageUploadPreset?.isNotEmpty ?? false) ||
          (_videoUploadPreset?.isNotEmpty ?? false) ||
          (_fileUploadPreset?.isNotEmpty ?? false) ||
          (_uploadPreset?.isNotEmpty ?? false));

  Future<MediaUploadResult> uploadImage({
    required File file,
    required String folder,
    String? publicId,
  }) {
    return _upload(file: file, folder: folder, publicId: publicId);
  }

  Future<MediaUploadResult> uploadVideo({
    required File file,
    required String folder,
    String? publicId,
  }) {
    return _upload(
      file: file,
      folder: folder,
      publicId: publicId,
      resourceType: 'video',
    );
  }

  Future<MediaUploadResult> uploadFile({
    required File file,
    required String folder,
    String? publicId,
  }) {
    return _upload(
      file: file,
      folder: folder,
      publicId: publicId,
      resourceType: 'auto',
    );
  }

  Future<MediaUploadResult> _upload({
    required File file,
    required String folder,
    String? publicId,
    String resourceType = 'image',
  }) async {
    if (!await file.exists()) {
      throw const MediaUploadException('Fichier média introuvable.');
    }

    final validation = await validateFile(file, resourceType: resourceType);
    if (!validation.isValid) {
      throw MediaUploadException(validation.message);
    }

    final cloudName = _cloudName;
    final uploadPreset = _presetFor(resourceType);

    if (cloudName == null ||
        cloudName.isEmpty ||
        uploadPreset == null ||
        uploadPreset.isEmpty) {
      throw const MediaUploadException(
        'Cloudinary non configuré. Ajoutez CLOUDINARY_CLOUD_NAME et '
        'CLOUDINARY_UPLOAD_PRESET dans le fichier .env.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    final request =
        http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = _normalizeFolder(folder)
          ..fields['tags'] = 'elegantstyle,$resourceType'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (publicId != null && publicId.trim().isNotEmpty) {
      request.fields['public_id'] = _sanitizePublicId(publicId);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MediaUploadException(
        'Upload Cloudinary échoué (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url']?.toString();
    final returnedPublicId = data['public_id']?.toString();

    if (url == null || url.isEmpty || returnedPublicId == null) {
      throw const MediaUploadException('Réponse Cloudinary incomplète.');
    }

    return MediaUploadResult(
      url: url,
      publicId: returnedPublicId,
      resourceType: data['resource_type']?.toString() ?? resourceType,
      optimizedUrl: optimizedUrl(url),
      thumbnailUrl: thumbnailUrl(url),
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
      bytes: (data['bytes'] as num?)?.toInt(),
    );
  }

  String? _presetFor(String resourceType) {
    return switch (resourceType) {
      'image' => _imageUploadPreset,
      'video' => _videoUploadPreset,
      'auto' => _fileUploadPreset,
      _ => _uploadPreset,
    };
  }

  String _normalizeFolder(String folder) {
    final trimmed = _sanitizeFolderPath(folder);
    final root = _folderRoot.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (trimmed.isEmpty) return '$root/misc';
    if (trimmed == root || trimmed.startsWith('$root/')) return trimmed;
    return '$root/$trimmed';
  }

  String _sanitizeFolderPath(String folder) {
    final segments =
        folder
            .trim()
            .replaceAll('\\', '/')
            .split('/')
            .map((segment) {
              return segment
                  .trim()
                  .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
                  .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
            })
            .where(
              (segment) =>
                  segment.isNotEmpty && segment != '.' && segment != '..',
            )
            .toList();
    return segments.join('/');
  }

  String _sanitizePublicId(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-/]'), '_');
  }

  static String optimizedUrl(
    String url, {
    int width = 1200,
    String crop = 'limit',
  }) {
    return transformUrl(url, 'f_auto,q_auto:eco,c_$crop,w_$width,dpr_auto');
  }

  static String thumbnailUrl(String url, {int width = 360, int height = 480}) {
    return transformUrl(
      url,
      'f_auto,q_auto:eco,c_fill,g_auto,w_$width,h_$height,dpr_auto',
    );
  }

  static String avatarUrl(String url, {int size = 160}) {
    return transformUrl(
      url,
      'f_auto,q_auto:eco,c_fill,g_face,w_$size,h_$size,dpr_auto',
    );
  }

  static String transformUrl(String url, String transformation) {
    if (url.isEmpty || transformation.trim().isEmpty) return url;
    const marker = '/upload/';
    final index = url.indexOf(marker);
    if (index == -1) return url;
    final prefix = url.substring(0, index + marker.length);
    final suffix = url.substring(index + marker.length);
    if (suffix.startsWith('f_auto,') ||
        suffix.startsWith('q_auto,') ||
        suffix.startsWith('c_')) {
      return url;
    }
    return '$prefix$transformation/$suffix';
  }

  static const int maxImageBytes = 8 * 1024 * 1024;
  static const int maxVideoBytes = 80 * 1024 * 1024;
  static const int maxAudioBytes = 20 * 1024 * 1024;
  static const int maxDocumentBytes = 12 * 1024 * 1024;

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };
  static const Set<String> _videoExtensions = {'mp4', 'mov', 'm4v', 'webm'};
  static const Set<String> _audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
  };
  static const Set<String> _documentExtensions = {
    'pdf',
    'docx',
    'xlsx',
    'pptx',
  };
  static const Set<String> _blockedExtensions = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'apk',
    'aab',
    'exe',
    'msi',
    'dmg',
    'jar',
    'bat',
    'cmd',
    'com',
    'sh',
    'bash',
    'ps1',
    'js',
    'mjs',
    'ts',
    'jsx',
    'tsx',
    'html',
    'htm',
    'css',
    'php',
    'py',
    'rb',
    'pl',
    'dart',
    'java',
    'kt',
    'swift',
    'c',
    'cpp',
    'cs',
    'go',
    'rs',
    'sql',
    'xml',
    'svg',
    'json',
    'yaml',
    'yml',
    'env',
    'pem',
    'key',
    'crt',
    'p12',
    'doc',
    'xls',
    'ppt',
    'docm',
    'xlsm',
    'pptm',
  };

  static Future<MediaFileValidation> validateFile(
    File file, {
    String resourceType = 'image',
  }) async {
    if (!await file.exists()) {
      return const MediaFileValidation.invalid('Fichier introuvable.');
    }

    final length = await file.length();
    if (length <= 0) {
      return const MediaFileValidation.invalid('Fichier vide ou illisible.');
    }

    final extension = _extensionFromPath(file.path);
    if (_blockedExtensions.contains(extension)) {
      return const MediaFileValidation.invalid(
        'Ce type de fichier est bloqué pour protéger votre compte.',
      );
    }

    final header = await _readHeader(file);
    final detectedKind = _detectKind(header);
    final expectedKinds = _expectedKinds(resourceType);

    if (expectedKinds.isNotEmpty && !expectedKinds.contains(detectedKind)) {
      return MediaFileValidation.invalid(_messageForResource(resourceType));
    }

    if (!_extensionAllowedForKind(extension, detectedKind, resourceType)) {
      return MediaFileValidation.invalid(_messageForResource(resourceType));
    }

    final maxBytes = _maxBytesForKind(detectedKind);
    if (length > maxBytes) {
      return MediaFileValidation.invalid(
        'Fichier trop lourd. Limite: ${_formatMegabytes(maxBytes)}.',
      );
    }

    return MediaFileValidation.valid(
      kind: detectedKind.name,
      extension: extension,
      bytes: length,
    );
  }

  static Set<_MediaKind> _expectedKinds(String resourceType) {
    return switch (resourceType) {
      'image' => {_MediaKind.image},
      'video' => {_MediaKind.video},
      'auto' => {
        _MediaKind.image,
        _MediaKind.video,
        _MediaKind.audio,
        _MediaKind.document,
      },
      _ => {_MediaKind.image},
    };
  }

  static bool _extensionAllowedForKind(
    String extension,
    _MediaKind kind,
    String resourceType,
  ) {
    if (extension.isEmpty) {
      return kind == _MediaKind.image || kind == _MediaKind.video;
    }
    return switch (kind) {
      _MediaKind.image => _imageExtensions.contains(extension),
      _MediaKind.video => _videoExtensions.contains(extension),
      _MediaKind.audio =>
        resourceType == 'auto' && _audioExtensions.contains(extension),
      _MediaKind.document =>
        resourceType == 'auto' && _documentExtensions.contains(extension),
      _MediaKind.unknown => false,
    };
  }

  static int _maxBytesForKind(_MediaKind kind) {
    return switch (kind) {
      _MediaKind.image => maxImageBytes,
      _MediaKind.video => maxVideoBytes,
      _MediaKind.audio => maxAudioBytes,
      _MediaKind.document => maxDocumentBytes,
      _MediaKind.unknown => maxImageBytes,
    };
  }

  static String _messageForResource(String resourceType) {
    return switch (resourceType) {
      'image' =>
        'Ajoutez une image sûre: JPG, PNG, WEBP ou HEIC. Les fichiers zip, code ou documents sont refusés.',
      'video' =>
        'Ajoutez une vidéo sûre: MP4, MOV, M4V ou WEBM. Les archives et scripts sont refusés.',
      'auto' =>
        'Format non accepté. Utilisez une image, une vidéo, un audio ou un document PDF/DOCX/XLSX/PPTX.',
      _ => 'Format de fichier non accepté.',
    };
  }

  static String _formatMegabytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb == mb.roundToDouble() ? 0 : 1)} Mo';
  }

  static String _extensionFromPath(String path) {
    final filename = path.split(RegExp(r'[/\\]')).last.toLowerCase();
    final index = filename.lastIndexOf('.');
    if (index == -1 || index == filename.length - 1) return '';
    return filename.substring(index + 1);
  }

  static Future<Uint8List> _readHeader(File file) async {
    final length = await file.length();
    final count = length < 16 ? length : 16;
    final stream = file.openRead(0, count);
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
      if (bytes.length >= count) break;
    }
    return Uint8List.fromList(bytes);
  }

  static _MediaKind _detectKind(Uint8List header) {
    if (header.length >= 4) {
      if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
        return _MediaKind.image;
      }
      if (header[0] == 0x89 &&
          header[1] == 0x50 &&
          header[2] == 0x4E &&
          header[3] == 0x47) {
        return _MediaKind.image;
      }
      if (_asciiAt(header, 0, 'RIFF') && _asciiAt(header, 8, 'WEBP')) {
        return _MediaKind.image;
      }
      if (_asciiAt(header, 4, 'ftyp')) {
        if (_asciiAt(header, 8, 'heic') ||
            _asciiAt(header, 8, 'heix') ||
            _asciiAt(header, 8, 'hevc') ||
            _asciiAt(header, 8, 'hevx') ||
            _asciiAt(header, 8, 'heif') ||
            _asciiAt(header, 8, 'mif1') ||
            _asciiAt(header, 8, 'msf1')) {
          return _MediaKind.image;
        }
        return _MediaKind.video;
      }
      if (_asciiAt(header, 0, '%PDF')) {
        return _MediaKind.document;
      }
      if (_asciiAt(header, 0, 'PK\u0003\u0004')) {
        return _MediaKind.document;
      }
      if (_asciiAt(header, 0, 'ID3') || _asciiAt(header, 0, 'OggS')) {
        return _MediaKind.audio;
      }
      if (_asciiAt(header, 0, 'RIFF') && _asciiAt(header, 8, 'WAVE')) {
        return _MediaKind.audio;
      }
    }
    return _MediaKind.unknown;
  }

  static bool _asciiAt(Uint8List bytes, int offset, String value) {
    if (bytes.length < offset + value.length) return false;
    for (var i = 0; i < value.length; i++) {
      if (bytes[offset + i] != value.codeUnitAt(i)) return false;
    }
    return true;
  }
}

class MediaUploadException implements Exception {
  final String message;
  const MediaUploadException(this.message);

  @override
  String toString() => message;
}

class MediaFileValidation {
  const MediaFileValidation._({
    required this.isValid,
    required this.message,
    this.kind,
    this.extension,
    this.bytes,
  });

  const MediaFileValidation.valid({
    required String kind,
    required String extension,
    required int bytes,
  }) : this._(
         isValid: true,
         message: '',
         kind: kind,
         extension: extension,
         bytes: bytes,
       );

  const MediaFileValidation.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String message;
  final String? kind;
  final String? extension;
  final int? bytes;
}

enum _MediaKind { image, video, audio, document, unknown }
