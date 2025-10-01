import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'tokens/tokens.json';
  final outputPath = 'packages/fmi_core/lib/design_tokens/mds_tokens.dart';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Token file not found at $inputPath');
    exit(1);
  }

  final jsonStr = await inputFile.readAsString();
  final Map<String, dynamic> tokens = jsonDecode(jsonStr);

  // --- STEP 1: collect categories & keys from tokens.json
  final newCategories = <String, Set<String>>{};
  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      newCategories[category] = values.keys.toSet();
    }
  });

  // --- STEP 2: if old file exists, parse it
  final oldFile = File(outputPath);
  if (oldFile.existsSync()) {
    final oldContent = await oldFile.readAsString();

    final missing = <String, List<String>>{};

    // regex ambil class & getter
    final classRegex = RegExp(r'class _([A-Za-z0-9_]+) \{([\s\S]*?)\}');
    for (final match in classRegex.allMatches(oldContent)) {
      final category = match.group(1)?.toLowerCase();
      final body = match.group(2) ?? '';

      if (category != null) {
        final getters = RegExp(r'(\w+)\s+get\s+(\w+)')
            .allMatches(body)
            .map((m) => m.group(2)!)
            .toSet();

        final existing = newCategories[category] ?? <String>{};
        final diff = getters.difference(existing);

        if (diff.isNotEmpty) {
          missing[category] = diff.toList();
        }
      }
    }

    if (missing.isNotEmpty) {
      print('❌ Validation failed: Some tokens disappeared compared to previous file.');
      missing.forEach((cat, props) {
        print(' - Category $cat: missing ${props.join(', ')}');
      });
      exit(1);
    }
  }

  // --- STEP 3: generate new file
  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('import \'package:flutter/material.dart\';\n');
  buffer.writeln('class MdsTokens {');

  // generate instance per category
  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      buffer.writeln('  static final $category = _${_capitalize(category)}();');
    }
  });

  buffer.writeln('}\n');

  // generate subclass per category
  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      buffer.writeln('class _${_capitalize(category)} {');
      values.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          final type = v['type'] ?? '';
          final val = v['value'];

          switch (type) {
            case 'color':
              final hex = val is String ? val.replaceAll('#', '') : '000000';
              buffer.writeln('  Color get $k => Color(0xFF$hex);');
              break;

            case 'dimension':
            case 'borderRadius':
              buffer.writeln('  double get $k => ${_parseDouble(val)};');
              break;

            case 'boxShadow':
              if (val is List) {
                buffer.writeln('  List<BoxShadow> get $k => [');
                for (var shadow in val) {
                  final color =
                      (shadow['color'] ?? '#000000').replaceAll('#', '');
                  final x = shadow['x'] ?? 0;
                  final y = shadow['y'] ?? 0;
                  final blur = shadow['blur'] ?? 0;
                  final spread = shadow['spread'] ?? 0;
                  buffer.writeln(
                      '    BoxShadow(color: Color(0xFF$color), offset: Offset($x, $y), blurRadius: $blur, spreadRadius: $spread),');
                }
                buffer.writeln('  ];');
              } else {
                buffer.writeln('  List<BoxShadow> get $k => [];');
              }
              break;

            case 'typography':
              if (val is Map) {
                buffer.writeln(
                    '  Map<String,dynamic> get $k => ${jsonEncode(val)};');
              } else {
                buffer.writeln('  dynamic get $k => ${_encodeValue(val)};');
              }
              break;

            default:
              if (val is Map || val is List) {
                buffer.writeln('  dynamic get $k => ${jsonEncode(val)};');
              } else {
                buffer.writeln('  dynamic get $k => ${_encodeValue(val)};');
              }
          }
        } else {
          buffer.writeln('  dynamic get $k => ${_encodeValue(v)};');
        }
      });
      buffer.writeln('}\n');
    }
  });

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('✅ Tokens generated to $outputPath');
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

double _parseDouble(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val.replaceAll('px', '').replaceAll('%', '')) ?? 0;
  }
  return 0;
}

String _encodeValue(dynamic val) {
  if (val is String) return "'$val'";
  if (val is num) return val.toString();
  if (val is bool) return val.toString();
  return jsonEncode(val);
}
