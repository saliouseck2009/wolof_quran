import 'dart:io';
import 'dart:typed_data';

/// Pure-Dart MP3 header parser for fast duration extraction.
///
/// Avoids the overhead of initializing a native AudioPlayer per file.
/// Works in isolates since it has no Flutter dependencies.
class Mp3DurationParser {
  Mp3DurationParser._();

  // ── MPEG bitrate tables (kbps) ──────────────────────────────────────────

  // Index: [mpegVersion][layer][bitrateIndex]
  // mpegVersion: 0 = MPEG2.5, 1 = reserved, 2 = MPEG2, 3 = MPEG1
  // layer:       1 = Layer III, 2 = Layer II, 3 = Layer I

  static const _bitratesMpeg1LayerIII = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0,
  ];
  static const _bitratesMpeg1LayerII = [
    0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0,
  ];
  static const _bitratesMpeg1LayerI = [
    0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0,
  ];
  static const _bitratesMpeg2LayerIII = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0,
  ];
  static const _bitratesMpeg2LayerII = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0,
  ];
  static const _bitratesMpeg2LayerI = [
    0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0,
  ];

  // ── Sample rate tables (Hz) ─────────────────────────────────────────────
  // Index: [mpegVersion][sampleRateIndex]

  static const _sampleRatesMpeg1 = [44100, 48000, 32000];
  static const _sampleRatesMpeg2 = [22050, 24000, 16000];
  static const _sampleRatesMpeg25 = [11025, 12000, 8000];

  /// Parse duration in milliseconds from raw MP3 bytes.
  /// [fileSize] is the total file size (needed for CBR calculation).
  /// Returns null if parsing fails.
  static int? parseDurationMs(Uint8List bytes, int fileSize) {
    if (bytes.length < 10) return null;

    var offset = 0;

    // ── Skip ID3v2 tag ──────────────────────────────────────────────────
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      // "ID3"
      if (bytes.length < 10) return null;
      final flags = bytes[5];
      final hasFooter = (flags & 0x10) != 0;
      final tagSize = _synchsafeInt(bytes, 6);
      offset = 10 + tagSize + (hasFooter ? 10 : 0);
    }

    // ── Find first valid MPEG frame sync ────────────────────────────────
    final frameInfo = _findFrame(bytes, offset);
    if (frameInfo == null) return null;

    final mpegVersion = frameInfo.mpegVersion;
    final layer = frameInfo.layer;
    final bitrateKbps = frameInfo.bitrateKbps;
    final sampleRate = frameInfo.sampleRate;
    final frameOffset = frameInfo.offset;

    // Samples per frame for duration calculation
    final samplesPerFrame = _samplesPerFrame(mpegVersion, layer);
    if (samplesPerFrame == 0) return null;

    // ── Check for VBR headers (Xing / Info / VBRI) ─────────────────────
    final vbrFrames = _readVbrFrameCount(
      bytes,
      frameOffset,
      mpegVersion,
      frameInfo.channelMode,
    );

    if (vbrFrames != null && vbrFrames > 0) {
      // VBR: duration = totalFrames * samplesPerFrame / sampleRate
      return (vbrFrames * samplesPerFrame * 1000) ~/ sampleRate;
    }

    // ── CBR fallback ────────────────────────────────────────────────────
    if (bitrateKbps <= 0) return null;
    final audioBytes = fileSize - offset; // bytes after ID3 tag
    if (audioBytes <= 0) return null;
    return (audioBytes * 8) ~/ bitrateKbps; // ms = (bytes * 8) / (kbps)
  }

  /// Parse duration from a file, reading only the first [headerBytes] bytes.
  static Future<int?> parseDurationMsFromFile(
    String filePath, {
    int headerBytes = 16384,
  }) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      if (fileSize < 10) return null;

      final raf = await file.open(mode: FileMode.read);
      try {
        final readSize = fileSize < headerBytes ? fileSize : headerBytes;
        final bytes = await raf.read(readSize);
        return parseDurationMs(bytes, fileSize);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Decode a 4-byte synchsafe integer (ID3v2 tag size).
  static int _synchsafeInt(Uint8List bytes, int offset) {
    return (bytes[offset] & 0x7F) << 21 |
        (bytes[offset + 1] & 0x7F) << 14 |
        (bytes[offset + 2] & 0x7F) << 7 |
        (bytes[offset + 3] & 0x7F);
  }

  /// Find the first valid MPEG audio frame starting from [offset].
  static _FrameInfo? _findFrame(Uint8List bytes, int offset) {
    final limit = bytes.length - 4;
    for (var i = offset; i < limit; i++) {
      if (bytes[i] != 0xFF) continue;
      if ((bytes[i + 1] & 0xE0) != 0xE0) continue;

      final header = _parseFrameHeader(bytes, i);
      if (header != null) return header;
    }
    return null;
  }

  /// Parse a 4-byte MPEG frame header at [offset].
  static _FrameInfo? _parseFrameHeader(Uint8List bytes, int offset) {
    final b1 = bytes[offset + 1];
    final b2 = bytes[offset + 2];

    // MPEG version: bits 4-3 of byte 1
    final versionBits = (b1 >> 3) & 0x03;
    if (versionBits == 1) return null; // reserved

    // Layer: bits 2-1 of byte 1
    final layerBits = (b1 >> 1) & 0x03;
    if (layerBits == 0) return null; // reserved

    // Bitrate index: bits 7-4 of byte 2
    final bitrateIndex = (b2 >> 4) & 0x0F;
    if (bitrateIndex == 0 || bitrateIndex == 15) return null;

    // Sample rate index: bits 3-2 of byte 2
    final sampleRateIndex = (b2 >> 2) & 0x03;
    if (sampleRateIndex == 3) return null; // reserved

    // Channel mode: bits 7-6 of byte 3
    final channelMode = (bytes[offset + 3] >> 6) & 0x03;

    // Resolve bitrate
    final bitrateKbps = _lookupBitrate(versionBits, layerBits, bitrateIndex);
    if (bitrateKbps == null || bitrateKbps <= 0) return null;

    // Resolve sample rate
    final sampleRate = _lookupSampleRate(versionBits, sampleRateIndex);
    if (sampleRate == null || sampleRate <= 0) return null;

    return _FrameInfo(
      offset: offset,
      mpegVersion: versionBits,
      layer: layerBits,
      bitrateKbps: bitrateKbps,
      sampleRate: sampleRate,
      channelMode: channelMode,
    );
  }

  static int? _lookupBitrate(int version, int layer, int index) {
    // version: 0=2.5, 2=2, 3=1 ; layer: 1=III, 2=II, 3=I
    if (version == 3) {
      // MPEG1
      if (layer == 3) return _bitratesMpeg1LayerI[index];
      if (layer == 2) return _bitratesMpeg1LayerII[index];
      if (layer == 1) return _bitratesMpeg1LayerIII[index];
    } else {
      // MPEG2 or MPEG2.5
      if (layer == 3) return _bitratesMpeg2LayerI[index];
      if (layer == 2) return _bitratesMpeg2LayerII[index];
      if (layer == 1) return _bitratesMpeg2LayerIII[index];
    }
    return null;
  }

  static int? _lookupSampleRate(int version, int index) {
    if (index > 2) return null;
    if (version == 3) return _sampleRatesMpeg1[index];
    if (version == 2) return _sampleRatesMpeg2[index];
    if (version == 0) return _sampleRatesMpeg25[index];
    return null;
  }

  static int _samplesPerFrame(int mpegVersion, int layer) {
    if (layer == 3) {
      // Layer I
      return 384;
    }
    if (layer == 2) {
      // Layer II
      return 1152;
    }
    // Layer III
    return mpegVersion == 3 ? 1152 : 576;
  }

  /// Read VBR frame count from Xing/Info or VBRI header.
  static int? _readVbrFrameCount(
    Uint8List bytes,
    int frameOffset,
    int mpegVersion,
    int channelMode,
  ) {
    // Side info size determines where Xing/Info tag starts
    int sideInfoSize;
    if (mpegVersion == 3) {
      // MPEG1
      sideInfoSize = channelMode == 3 ? 17 : 32; // mono : stereo
    } else {
      // MPEG2/2.5
      sideInfoSize = channelMode == 3 ? 9 : 17;
    }

    // Xing/Info header location: frame start + 4 (header) + sideInfo
    final xingOffset = frameOffset + 4 + sideInfoSize;
    if (xingOffset + 12 <= bytes.length) {
      final tag = String.fromCharCodes(bytes.sublist(xingOffset, xingOffset + 4));
      if (tag == 'Xing' || tag == 'Info') {
        final flags = _readUint32BE(bytes, xingOffset + 4);
        if ((flags & 0x01) != 0) {
          // Frames field present
          return _readUint32BE(bytes, xingOffset + 8);
        }
      }
    }

    // VBRI header: always at offset 36 from frame start
    final vbriOffset = frameOffset + 36;
    if (vbriOffset + 26 <= bytes.length) {
      final tag = String.fromCharCodes(bytes.sublist(vbriOffset, vbriOffset + 4));
      if (tag == 'VBRI') {
        return _readUint32BE(bytes, vbriOffset + 14);
      }
    }

    return null;
  }

  static int _readUint32BE(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}

class _FrameInfo {
  final int offset;
  final int mpegVersion;
  final int layer;
  final int bitrateKbps;
  final int sampleRate;
  final int channelMode;

  const _FrameInfo({
    required this.offset,
    required this.mpegVersion,
    required this.layer,
    required this.bitrateKbps,
    required this.sampleRate,
    required this.channelMode,
  });
}

/// Top-level function for use with [Isolate.run].
/// Takes a list of file paths, returns a list of durations in milliseconds.
Future<List<int?>> parseMp3DurationsInIsolate(List<String> filePaths) async {
  final results = <int?>[];
  for (final path in filePaths) {
    results.add(await Mp3DurationParser.parseDurationMsFromFile(path));
  }
  return results;
}
