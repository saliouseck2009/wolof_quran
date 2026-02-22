import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/audio_availability_manifest.dart';

class AudioAvailabilityRemoteDataSource {
  final Dio _dio;

  static const String _manifestUrl =
      'https://github.com/saliouseck2009/algo-practice/raw/refs/heads/main/availability.json';

  AudioAvailabilityRemoteDataSource(this._dio);

  Future<AudioAvailabilityManifest> fetchManifest() async {
    final response = await _dio.get(_manifestUrl);

    dynamic payload = response.data;
    if (payload is String) {
      payload = json.decode(payload);
    }

    if (payload is! Map) {
      throw const FormatException(
        'Invalid availability manifest: payload must be an object',
      );
    }

    final normalizedPayload = payload.map(
      (key, value) => MapEntry('$key', value),
    );

    return AudioAvailabilityManifest.fromJson(normalizedPayload);
  }

  Future<AudioReciterAvailabilityEntry?> fetchReciterAvailability(
    String reciterId,
  ) async {
    final manifest = await fetchManifest();
    return manifest.reciterById(reciterId);
  }
}
