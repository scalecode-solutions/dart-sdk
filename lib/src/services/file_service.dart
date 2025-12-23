import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';

import 'package:tinode/src/models/connection-options.dart';
import 'package:tinode/src/services/auth.dart';
import 'package:tinode/src/services/configuration.dart';
import 'package:tinode/src/services/logger.dart';

/// Progress information for file uploads/downloads
class FileProgress {
  /// Number of bytes transferred so far
  final int bytesTransferred;

  /// Total size in bytes (may be -1 if unknown)
  final int totalBytes;

  /// Progress percentage (0-100), or -1 if total is unknown
  double get percentage =>
      totalBytes > 0 ? (bytesTransferred / totalBytes) * 100 : -1;

  FileProgress(this.bytesTransferred, this.totalBytes);
}

/// Result of a successful file upload
class UploadResult {
  /// URL path to the uploaded file (relative to server)
  final String url;

  /// Full URL including server host
  final String fullUrl;

  UploadResult(this.url, this.fullUrl);
}

/// Service for handling file uploads and downloads with the Tinode server.
///
/// Supports large file uploads via HTTP multipart POST and authenticated downloads.
class FileService {
  late AuthService _authService;
  late ConfigService _configService;
  late LoggerService _loggerService;
  final ConnectionOptions _options;

  /// Stream for upload progress updates
  final PublishSubject<FileProgress> onUploadProgress =
      PublishSubject<FileProgress>();

  /// Stream for download progress updates
  final PublishSubject<FileProgress> onDownloadProgress =
      PublishSubject<FileProgress>();

  FileService(this._options) {
    _authService = GetIt.I.get<AuthService>();
    _configService = GetIt.I.get<ConfigService>();
    _loggerService = GetIt.I.get<LoggerService>();
  }

  /// Get the base URL for file operations
  String _getBaseUrl() {
    final scheme = (_options.secure ?? false) ? 'https' : 'http';
    return '$scheme://${_options.host}';
  }

  /// Get the upload endpoint URL
  String get uploadUrl => '${_getBaseUrl()}/v0/file/u';

  /// Get the download endpoint URL
  String get downloadUrl => '${_getBaseUrl()}/v0/file/s';

  /// Build authentication headers for requests
  Map<String, String> _getAuthHeaders() {
    final headers = <String, String>{
      'X-Tinode-APIKey': _options.apiKey,
    };

    final token = _authService.authToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer ${token.token}';
    }

    return headers;
  }

  /// Upload a file to the Tinode server.
  ///
  /// [fileBytes] - The file content as bytes
  /// [filename] - The name of the file
  /// [mimeType] - The MIME type of the file (e.g., 'image/jpeg')
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns [UploadResult] with the URL of the uploaded file
  Future<UploadResult> uploadFile({
    required Uint8List fileBytes,
    required String filename,
    required String mimeType,
    void Function(FileProgress)? onProgress,
  }) async {
    _loggerService.log('Uploading file: $filename ($mimeType)');

    // Check file size against server limit
    final maxSize = _configService.serverConfiguration.maxFileUploadSize;
    if (maxSize != null && maxSize > 0 && fileBytes.length > maxSize) {
      throw Exception(
          'File size ${fileBytes.length} exceeds maximum allowed size $maxSize');
    }

    final uri = Uri.parse(uploadUrl);
    final request = http.MultipartRequest('POST', uri);

    // Add authentication headers
    request.headers.addAll(_getAuthHeaders());

    // Parse mime type
    final parts = mimeType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('application', 'octet-stream');

    // Add file to request
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: mediaType,
    ));

    // Send initial progress
    if (onProgress != null) {
      onProgress(FileProgress(0, fileBytes.length));
    }
    onUploadProgress.add(FileProgress(0, fileBytes.length));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Send completion progress
      if (onProgress != null) {
        onProgress(FileProgress(fileBytes.length, fileBytes.length));
      }
      onUploadProgress.add(FileProgress(fileBytes.length, fileBytes.length));

      if (response.statusCode == 200) {
        // Parse response to get URL
        final body = response.body;
        _loggerService.log('Upload response: $body');

        // The server returns a JSON ctrl message with params.url
        // Extract the URL from the response
        final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body);
        if (urlMatch != null) {
          final path = urlMatch.group(1)!;
          final fullUrl = path.startsWith('/')
              ? '${_getBaseUrl()}$path'
              : '$downloadUrl/$path';
          return UploadResult(path, fullUrl);
        }

        throw Exception('Failed to parse upload response: $body');
      } else if (response.statusCode == 307) {
        // Handle redirect - retry at new location
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          _loggerService.log('Upload redirected to: $newUrl');
          // Recursive call to handle redirect
          return _uploadToUrl(
            url: newUrl,
            fileBytes: fileBytes,
            filename: filename,
            mimeType: mimeType,
            onProgress: onProgress,
          );
        }
        throw Exception('Redirect without location header');
      } else {
        throw Exception(
            'Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _loggerService.error('Upload error: $e');
      rethrow;
    }
  }

  /// Upload to a specific URL (used for redirects)
  Future<UploadResult> _uploadToUrl({
    required String url,
    required Uint8List fileBytes,
    required String filename,
    required String mimeType,
    void Function(FileProgress)? onProgress,
  }) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_getAuthHeaders());

    final parts = mimeType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('application', 'octet-stream');

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: mediaType,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (onProgress != null) {
      onProgress(FileProgress(fileBytes.length, fileBytes.length));
    }

    if (response.statusCode == 200) {
      final urlMatch =
          RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(response.body);
      if (urlMatch != null) {
        final path = urlMatch.group(1)!;
        final fullUrl = path.startsWith('/')
            ? '${_getBaseUrl()}$path'
            : '$downloadUrl/$path';
        return UploadResult(path, fullUrl);
      }
      throw Exception('Failed to parse upload response');
    }
    throw Exception(
        'Upload failed with status ${response.statusCode}: ${response.body}');
  }

  /// Upload a file from disk.
  ///
  /// [file] - The file to upload
  /// [mimeType] - Optional MIME type (will try to detect if not provided)
  /// [onProgress] - Optional callback for progress updates
  Future<UploadResult> uploadFileFromPath({
    required File file,
    String? mimeType,
    void Function(FileProgress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last;

    // Try to detect MIME type from extension if not provided
    final resolvedMimeType = mimeType ?? _getMimeType(filename);

    return uploadFile(
      fileBytes: bytes,
      filename: filename,
      mimeType: resolvedMimeType,
      onProgress: onProgress,
    );
  }

  /// Download a file from the Tinode server.
  ///
  /// [url] - The file URL (can be relative or absolute)
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns the file content as bytes
  Future<Uint8List> downloadFile({
    required String url,
    void Function(FileProgress)? onProgress,
  }) async {
    // Resolve URL
    final fullUrl = _resolveUrl(url);
    _loggerService.log('Downloading file: $fullUrl');

    final uri = Uri.parse(fullUrl);
    final request = http.Request('GET', uri);

    // Add authentication headers
    request.headers.addAll(_getAuthHeaders());

    try {
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? -1;
        final chunks = <List<int>>[];
        var received = 0;

        await for (final chunk in streamedResponse.stream) {
          chunks.add(chunk);
          received += chunk.length;

          final progress = FileProgress(received, contentLength);
          if (onProgress != null) {
            onProgress(progress);
          }
          onDownloadProgress.add(progress);
        }

        final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
        _loggerService.log('Download complete: ${bytes.length} bytes');
        return bytes;
      } else {
        throw Exception(
            'Download failed with status ${streamedResponse.statusCode}');
      }
    } catch (e) {
      _loggerService.error('Download error: $e');
      rethrow;
    }
  }

  /// Download a file and save it to disk.
  ///
  /// [url] - The file URL (can be relative or absolute)
  /// [savePath] - Path where to save the file
  /// [onProgress] - Optional callback for progress updates
  Future<File> downloadFileToPath({
    required String url,
    required String savePath,
    void Function(FileProgress)? onProgress,
  }) async {
    final bytes = await downloadFile(url: url, onProgress: onProgress);
    final file = File(savePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Resolve a relative URL to an absolute URL
  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '${_getBaseUrl()}$url';
    }
    // Assume it's a filename
    return '$downloadUrl/$url';
  }

  /// Get MIME type from filename extension
  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',
      'zip': 'application/zip',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4',
      'webm': 'video/webm',
      'ogg': 'audio/ogg',
      'wav': 'audio/wav',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// Dispose of resources
  void dispose() {
    onUploadProgress.close();
    onDownloadProgress.close();
  }
}
