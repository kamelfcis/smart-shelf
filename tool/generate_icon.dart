// Generates assets/icon/icon.png and assets/icon/icon_fg.png
// Run with: dart run tool/generate_icon.dart
// Requires the `image` package — add it temporarily to pubspec dev_dependencies.

import 'dart:io';
import 'dart:math' as math;

void main() {
  const size = 1024;

  // ── Background icon (full square with gradient + ring + icon) ──────────
  final bgBytes = _generateMainIcon(size);
  final bgFile = File('assets/icon/icon.png');
  bgFile.writeAsBytesSync(bgBytes);
  print('Wrote ${bgFile.path}  (${bgBytes.length} bytes)');

  // ── Foreground icon (transparent bg + white icon only) ─────────────────
  final fgBytes = _generateFgIcon(size);
  final fgFile = File('assets/icon/icon_fg.png');
  fgFile.writeAsBytesSync(fgBytes);
  print('Wrote ${fgFile.path}  (${fgBytes.length} bytes)');
}

/// Writes a minimal PNG with the given RGBA pixel data.
List<int> _encodePng(List<List<List<int>>> pixels, int w, int h) {
  // We don't want to add a dependency just for a PNG, so we write a hand-crafted
  // minimal 8-bit RGBA PNG.  Flutter's image package would be cleaner, but this
  // avoids any pubspec changes.
  return _PngEncoder.encode(pixels, w, h);
}

List<int> _generateMainIcon(int sz) {
  final pixels = List.generate(
    sz,
    (y) => List.generate(sz, (x) {
      // Dark navy background (#0A0A1A)
      int r = 10, g = 10, b = 26, a = 255;

      final cx = sz / 2;
      final cy = sz / 2;
      final dist = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));

      // Purple-to-cyan gradient ring  (inner 260 → outer 360 radius)
      final inner = sz * 0.25;
      final outer = sz * 0.35;
      if (dist >= inner && dist <= outer) {
        final t = (dist - inner) / (outer - inner);
        // Purple #6C63FF → Cyan #00E5FF
        final pr = 108, pg = 99, pb = 255;
        final cr = 0, cg = 229, cb = 255;
        r = (pr + (cr - pr) * t).round().clamp(0, 255);
        g = (pg + (cg - pg) * t).round().clamp(0, 255);
        b = (pb + (cb - pb) * t).round().clamp(0, 255);
        // Soft edge
        final edge = math.min(dist - inner, outer - dist) / 12;
        a = (255 * edge.clamp(0.0, 1.0)).round();
      }

      // Simple inventory-box icon using line segments (white)
      final normX = (x - cx) / sz;
      final normY = (y - cy) / sz;
      if (_isBoxPixel(normX, normY)) {
        r = 255; g = 255; b = 255; a = 255;
      }

      return [r, g, b, a];
    }),
  );
  return _PngEncoder.encode(pixels, sz, sz);
}

List<int> _generateFgIcon(int sz) {
  final pixels = List.generate(
    sz,
    (y) => List.generate(sz, (x) {
      final cx = sz / 2;
      final cy = sz / 2;
      final normX = (x - cx) / sz;
      final normY = (y - cy) / sz;
      if (_isBoxPixel(normX, normY)) {
        return [255, 255, 255, 255];
      }
      return [0, 0, 0, 0];
    }),
  );
  return _PngEncoder.encode(pixels, sz, sz);
}

bool _isBoxPixel(double nx, double ny) {
  final t = 0.008; // line thickness (normalized)
  // Outer box  ±0.22
  const b = 0.22;
  // Bottom face
  if (ny.abs() < b && nx.abs() < b) {
    // Bottom horizontal
    if ((ny - b).abs() < t && nx >= -b && nx <= b) return true;
    // Top horizontal (lid bottom)
    if ((ny + b * 0.3).abs() < t && nx >= -b && nx <= b) return true;
    // Left vertical
    if ((nx + b).abs() < t && ny >= b * 0.3 && ny <= b) return true; // fixed: was -b to -0.3b
    // Right vertical
    if ((nx - b).abs() < t && ny >= b * 0.3 && ny <= b) return true;
    // Lid left
    if ((nx + b).abs() < t && ny >= -b && ny <= -b * 0.3) return true;
    // Lid right
    if ((nx - b).abs() < t && ny >= -b && ny <= -b * 0.3) return true;
    // Lid top
    if ((ny + b).abs() < t && nx >= -b && nx <= b) return true;
    // Center divider (lid crease)
    if ((ny + b * 0.3).abs() < t && nx >= -b && nx <= b) return true;
    // Lid handle arch (top center)
    final hx = nx;
    final hy = ny + b * 0.65;
    if ((hx * hx / 0.0025 + hy * hy / 0.0016 - 1.0).abs() < 0.3 &&
        hy < 0 && hx.abs() < 0.05) {
      return true;
    }
  }
  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal PNG encoder (DEFLATE level 0 = uncompressed, valid PNG)
// ─────────────────────────────────────────────────────────────────────────────

class _PngEncoder {
  static List<int> encode(List<List<List<int>>> pixels, int w, int h) {
    final raw = <int>[];
    for (var y = 0; y < h; y++) {
      raw.add(0); // filter byte
      for (var x = 0; x < w; x++) {
        raw.addAll(pixels[y][x]); // R G B A
      }
    }

    final idat = _deflateStore(raw);
    final ihdr = _ihdr(w, h);

    final out = <int>[];
    out.addAll([137, 80, 78, 71, 13, 10, 26, 10]); // PNG signature
    out.addAll(_chunk('IHDR', ihdr));
    out.addAll(_chunk('IDAT', idat));
    out.addAll(_chunk('IEND', []));
    return out;
  }

  static List<int> _ihdr(int w, int h) {
    return [
      ..._u32(w), ..._u32(h),
      8,  // bit depth
      6,  // colour type RGBA
      0, 0, 0, // compression, filter, interlace
    ];
  }

  /// Uncompressed DEFLATE (stored blocks) wrapping the raw bytes.
  static List<int> _deflateStore(List<int> data) {
    const blockMax = 65535;
    final out = <int>[0x78, 0x01]; // zlib header (CM=8, FCHECK, no dict)
    var adler = _adler32(data);
    var offset = 0;
    while (offset < data.length) {
      final end = math.min(offset + blockMax, data.length);
      final block = data.sublist(offset, end);
      final isLast = end >= data.length;
      out.add(isLast ? 1 : 0);
      final len = block.length;
      out.addAll([len & 0xFF, (len >> 8) & 0xFF]);
      final nlen = ~len & 0xFFFF;
      out.addAll([nlen & 0xFF, (nlen >> 8) & 0xFF]);
      out.addAll(block);
      offset = end;
    }
    out.addAll(_u32(adler)); // adler32 checksum
    return out;
  }

  static int _adler32(List<int> data) {
    int s1 = 1, s2 = 0;
    for (final b in data) {
      s1 = (s1 + b) % 65521;
      s2 = (s2 + s1) % 65521;
    }
    return (s2 << 16) | s1;
  }

  static List<int> _chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    final crcInput = [...typeBytes, ...data];
    final crc = _crc32(crcInput);
    return [..._u32(data.length), ...typeBytes, ...data, ..._u32(crc)];
  }

  static List<int> _u32(int v) => [
        (v >> 24) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 8) & 0xFF,
        v & 0xFF,
      ];

  static const List<int> _crcTable = [];
  static final _crcCache = <int>[];

  static int _crc32(List<int> data) {
    if (_crcCache.isEmpty) {
      for (var n = 0; n < 256; n++) {
        var c = n;
        for (var k = 0; k < 8; k++) {
          c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
        }
        _crcCache.add(c);
      }
    }
    var crc = 0xFFFFFFFF;
    for (final b in data) {
      crc = _crcCache[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }
}
