import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'database_service.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseUrl;
  final String? releaseNotes;
  final bool isNewer;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseUrl,
    this.releaseNotes,
    required this.isNewer,
  });
}

class UpdateService {
  static const _repoOwner = 'Shuash11';
  static const _repoName = 'Strict-Reminder';
  static const _cacheKey = 'last_update_check_cache';
  static const _cacheDuration = Duration(hours: 1);
  static const _skipVersionKey = 'skipped_update_version';

  static String? _cachedResponse;
  static DateTime? _lastFetch;

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      if (_cachedResponse != null && _lastFetch != null) {
        if (DateTime.now().difference(_lastFetch!) < _cacheDuration) {
          return _parseResponse(_cachedResponse!);
        }
      }

      final dbCache = await DatabaseService.getSetting(_cacheKey);
      if (dbCache != null && _cachedResponse == null) {
        _cachedResponse = dbCache;
        _lastFetch = DateTime.now();
      }

      final client = HttpClient();
      client.userAgent = 'ForReal/1.0';
      final request = await client.getUrl(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        ),
      );
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint('[UpdateService] GitHub API returned ${response.statusCode}');
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      _cachedResponse = body;
      _lastFetch = DateTime.now();
      await DatabaseService.setSetting(_cacheKey, body);

      return _parseResponse(body);
    } catch (e) {
      debugPrint('[UpdateService] Failed to check for update: $e');
      return null;
    }
  }

  static UpdateInfo? _parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final releaseUrl = json['html_url'] as String? ?? '';
      final releaseNotes = json['body'] as String?;

      if (tagName.isEmpty) return null;

      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final currentVersion = _currentAppVersion();

      final isNewer = _isVersionNewer(latestVersion, currentVersion);
      if (!isNewer) return null;

      return UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        releaseUrl: releaseUrl,
        releaseNotes: releaseNotes,
        isNewer: true,
      );
    } catch (e) {
      debugPrint('[UpdateService] Failed to parse response: $e');
      return null;
    }
  }

  static String _currentAppVersion() {
    return '1.0.1';
  }

  static bool _isVersionNewer(String latest, String current) {
    final latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static Future<bool> isVersionSkipped(String version) async {
    final skipped = await DatabaseService.getSetting(_skipVersionKey);
    return skipped == version;
  }

  static Future<void> skipVersion(String version) async {
    await DatabaseService.setSetting(_skipVersionKey, version);
  }
}
