import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('tokens/tokens.json');
  if (!file.existsSync()) {
    print('File tokens.json tidak ditemukan!');
    return;
  }

  final jsonStr = await file.readAsString();
  final Map<String, dynamic> tokens = jsonDecode(jsonStr);

  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('');
  buffer.writeln('class MdsTokens {');
  buffer.writeln('  MdsTokens._();\n');

  // --- COLORS ---
  if (tokens.containsKey('colors')) {
    buffer.writeln('  // Colors');
    buffer.writeln('  static _MdsColors get color => _MdsColors();\n');
  }

  // --- SPACING ---
  if (tokens.containsKey('spacing')) {
    buffer.writeln('  // Spacing');
    buffer.writeln('  static _MdsSpacing get spacing => _MdsSpacing();\n');
  }

  // --- TYPOGRAPHY ---
  if (tokens.containsKey('fontSize') ||
      tokens.containsKey('lineHeights') ||
      tokens.containsKey('fontWeights')) {
    buffer.writeln('  // Typography');
    buffer.writeln(
        '  static _MdsTypography get typography => _MdsTypography();\n');
  }

  // --- ELEVATION / BOXSHADOW ---
  if (tokens.containsKey('elevation')) {
    buffer.writeln('  // Elevation / Shadow');
    buffer
        .writeln('  static _MdsElevation get elevation => _MdsElevation();\n');
  }

  buffer.writeln('}');

  // -------------------------
  // Generate Colors
  if (tokens.containsKey('colors')) {
    buffer.writeln('\nclass _MdsColors {');
    tokens['colors'].forEach((key, value) {
      final hex = value['value'] as String;
      buffer.writeln(
          '  final Color $key = Color(0xFF${hex.substring(1).toUpperCase()});');
    });
    buffer.writeln('}');
  }

  // -------------------------
  // Generate Spacing
  if (tokens.containsKey('spacing')) {
    buffer.writeln('\nclass _MdsSpacing {');
    tokens['spacing'].forEach((key, value) {
      buffer.writeln('  final double $key = ${value['value'].toDouble()};');
    });
    buffer.writeln('}');
  }

  // -------------------------
  // Generate Elevation / BoxShadow
  if (tokens.containsKey('elevation')) {
    buffer.writeln('\nclass _MdsElevation {');
    tokens['elevation'].forEach((key, value) {
      final shadows = value['value'] as List<dynamic>;
      buffer.writeln('  final List<BoxShadow> level$key = [');
      for (var s in shadows) {
        final color = s['color'] as String;
        final x = s['x'];
        final y = s['y'];
        final blur = s['blur'];
        final spread = s['spread'];
        buffer.writeln(
            '    BoxShadow(color: Color(0xFF${color.substring(1).toUpperCase()}), offset: Offset($x, $y), blurRadius: $blur, spreadRadius: $spread),');
      }
      buffer.writeln('  ];');
    });
    buffer.writeln('}');
  }

  // -------------------------
  // Generate Typography
  if (tokens.containsKey('fontSize')) {
    buffer.writeln('\nclass _MdsTypography {');

    final fontFamilies = tokens['fontFamilies'] ?? {};
    final fontWeights = tokens['fontWeights'] ?? {};
    final fontSizes = tokens['fontSize'] ?? {};
    final lineHeights = tokens['lineHeights'] ?? {};
    final letterSpacing = tokens['letterSpacing'] ?? {};
    final paragraphSpacing = tokens['paragraphSpacing'] ?? {};

    tokens.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          value.containsKey('value') &&
          value['type'] == 'typography') {
        final v = value['value'] as Map<String, dynamic>;

        final fontFamilyRef = v['fontFamily']?.toString() ?? '';
        final fontWeightRef = v['fontWeight']?.toString() ?? '';
        final fontSizeRef = v['fontSize']?.toString() ?? '';
        final lineHeightRef = v['lineHeight']?.toString() ?? '';
        final letterSpacingRef = v['letterSpacing']?.toString() ?? '';

        buffer.writeln('  TextStyle get $key => TextStyle(');
        buffer.writeln(
            '    fontFamily: ${_resolveToken(fontFamilies, fontFamilyRef)},');
        buffer.writeln(
            '    fontWeight: ${_resolveFontWeight(fontWeights, fontWeightRef)},');
        buffer.writeln(
            '    fontSize: ${_resolveTokenValue(fontSizes, fontSizeRef)},');
        buffer.writeln(
            '    height: ${_resolveLineHeight(lineHeights, lineHeightRef, fontSizes, fontSizeRef)},');
        buffer.writeln(
            '    letterSpacing: ${_resolveTokenValue(letterSpacing, letterSpacingRef)},');
        buffer.writeln('  );\n');
      }
    });

    buffer.writeln('}');
  }

  // -------------------------
  // Tulis file
  final outputFile = File('lib/generated/mds_tokens.dart');
  await outputFile.writeAsString(buffer.toString());
  print('✅ Tokens berhasil digenerate ke lib/generated/mds_tokens.dart');
}

// -----------------------------------
// Helper functions
String _resolveToken(Map<String, dynamic> tokens, String ref) {
  if (ref.startsWith('{') && ref.endsWith('}')) {
    final path = ref.substring(1, ref.length - 1).split('.');
    dynamic current = tokens;
    for (var p in path) {
      if (current[p] != null) {
        current = current[p];
      } else {
        return 'null';
      }
    }
    return '\'${current['value']}\'';
  }
  return '\'${ref}\'';
}

String _resolveTokenValue(Map<String, dynamic> tokens, String ref) {
  if (ref.startsWith('{') && ref.endsWith('}')) {
    final path = ref.substring(1, ref.length - 1).split('.');
    dynamic current = tokens;
    for (var p in path) {
      if (current[p] != null) {
        current = current[p];
      } else {
        return '0.0';
      }
    }
    return (current['value'] is String)
        ? '${double.tryParse(current['value']) ?? 0.0}'
        : '${current['value']}.0';
  }
  return ref;
}

String _resolveFontWeight(Map<String, dynamic> tokens, String ref) {
  final val = _resolveTokenValue(tokens, ref);
  switch (val) {
    case 'Regular':
      return 'FontWeight.w400';
    case 'Medium':
      return 'FontWeight.w500';
    case 'Bold':
      return 'FontWeight.w700';
    default:
      return 'FontWeight.normal';
  }
}

String _resolveLineHeight(Map<String, dynamic> lineHeights, String ref,
    Map<String, dynamic> fontSizes, String fontSizeRef) {
  final lhStr = _resolveTokenValue(lineHeights, ref);
  final fsStr = _resolveTokenValue(fontSizes, fontSizeRef);
  final lh = double.tryParse(lhStr) ?? 14.0;
  final fs = double.tryParse(fsStr) ?? 14.0;
  return (lh / fs).toStringAsFixed(2);
}
