import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'tokens/tokens.json';
  final outputPath = 'lib/generated/mds_tokens.dart';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Token file not found at $inputPath');
    exit(1);
  }

  final jsonStr = await inputFile.readAsString();
  final Map<String, dynamic> tokens = jsonDecode(jsonStr);

  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('');
  buffer.writeln('class MdsTokens {');

  tokens.forEach((category, values) {
    if (values is Map<String, dynamic>) {
      buffer.writeln('  static final $category = _${_capitalize(category)}();');
    }
  });

  buffer.writeln('}');
  buffer.writeln('');

  // generate subclass per category
  tokens.forEach((category, values) {
    if (values is Map<String, dynamic>) {
      buffer.writeln('class _${_capitalize(category)} {');
      values.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          final type = v['type'] ?? '';
          final val = v['value'];

          if (type == 'color') {
            final hex = val is String ? val.replaceAll('#', '') : '000000';
            buffer.writeln(
                '  Color get $k => Color(0xFF$hex);');
          } else if (type == 'dimension' || type == 'borderRadius') {
            final d = _parseDouble(val);
            buffer.writeln('  double get $k => $d;');
          } else if (type == 'boxShadow') {
            if (val is List) {
              buffer.writeln('  List<BoxShadow> get $k => [');
              for (var shadow in val) {
                buffer.writeln(
                    '    BoxShadow(color: Color(0xFF${(shadow['color'] ?? '#000000').substring(1)}), offset: Offset(${shadow['x'] ?? 0}, ${shadow['y'] ?? 0}), blurRadius: ${shadow['blur'] ?? 0}, spreadRadius: ${shadow['spread'] ?? 0}),');
              }
              buffer.writeln('  ];');
            } else {
              buffer.writeln('  List<BoxShadow> get $k => [];');
            }
          } else if (type == 'typography') {
            // fallback: bisa di extend nanti
            buffer.writeln('  Map<String,dynamic> get $k => ${jsonEncode(val)};');
          } else {
            // string / number / unknown
            buffer.writeln('  dynamic get $k => ${_encodeValue(val)};');
          }
        }
      });
      buffer.writeln('}\n');
    }
  });

  // create output folder if not exists
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('Tokens generated to $outputPath');
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

double _parseDouble(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val.replaceAll('px', '')) ?? 0;
  return 0;
}

String _encodeValue(dynamic val) {
  if (val is String) return "'$val'";
  if (val is num) return val.toString();
  if (val is bool) return val.toString();
  return jsonEncode(val);
}
