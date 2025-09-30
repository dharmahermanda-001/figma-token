import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'lib/tokens.json';
  final outputPath = 'lib/generated/mds_tokens.dart';

  final jsonFile = File(inputPath);
  if (!jsonFile.existsSync()) {
    print('File not found: $inputPath');
    exit(1);
  }

  final Map<String, dynamic> jsonData = jsonDecode(await jsonFile.readAsString());

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('class MdsTokens {');

  jsonData.forEach((key, value) {
    if (key.startsWith(r'$')) return; // skip metadata
    final className = _pascalCase(key);
    buffer.writeln('  static final $key = _$className();');
  });

  buffer.writeln('}\n');

  // buat tiap subclass
  jsonData.forEach((key, value) {
    if (key.startsWith(r'$')) return;
    final className = _pascalCase(key);
    buffer.writeln('class _$className {');

    if (value is Map<String, dynamic>) {
      value.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final type = v['type'];
          final val = v['value'];
          if (type == 'color') {
            buffer.writeln('  Color get $k => Color(0xFF${val.toString().substring(1)});');
          } else if (type == 'borderRadius') {
            buffer.writeln('  double get $k => double.parse("$val");');
          } else if (type == 'dimension' || type == 'fontSizes' || type == 'lineHeights' || type == 'letterSpacing' || type == 'paragraphSpacing') {
            buffer.writeln('  double get $k => double.parse("$val");');
          } else if (type == 'boxShadow') {
            // val di boxShadow biasanya list
            if (val is List) {
              buffer.writeln('  List<BoxShadow> get $k => [');
              for (var shadow in val) {
                buffer.writeln(
                    '    BoxShadow(color: Color(0xFF${shadow['color'].substring(1)}), offset: Offset(${shadow['x']}, ${shadow['y']}), blurRadius: ${shadow['blur']}, spreadRadius: ${shadow['spread']}),');
              }
              buffer.writeln('  ];');
            }
          } else if (type == 'typography') {
            buffer.writeln('  TextStyle get $k => TextStyle(');
            if (val['fontSize'] != null) buffer.writeln('    fontSize: double.parse("${val['fontSize']}"),');
            if (val['lineHeight'] != null && val['fontSize'] != null) {
              buffer.writeln('    height: double.parse("${val['lineHeight']}") / double.parse("${val['fontSize']}"),');
            }
            if (val['fontWeight'] != null) buffer.writeln('    fontWeight: FontWeight.w${_fontWeightNumber(val['fontWeight'])},');
            buffer.writeln('  );');
          } else {
            // default: simpan sebagai String
            buffer.writeln('  final $k = "$val";');
          }
        }
      });
    }

    buffer.writeln('}\n');
  });

  final outFile = File(outputPath);
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(buffer.toString());

  print('Tokens generated successfully: $outputPath');
}

String _pascalCase(String s) =>
    s.split(RegExp(r'[_\s-]')).map((e) => e[0].toUpperCase() + e.substring(1)).join();

String _fontWeightNumber(String value) {
  switch (value.toLowerCase()) {
    case 'regular':
    case '400':
      return '400';
    case 'medium':
    case '500':
      return '500';
    case 'bold':
    case '700':
      return '700';
    default:
      return '400';
  }
}
