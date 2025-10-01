import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'tokens/tokens.json';
  final tokenOutputPath = 'packages/fmi_core/lib/design_tokens/mds_tokens.dart';
  final componentBasePath ='packages/fmi_core/lib/components/';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Token file not found at $inputPath');
    exit(1);
  }

  final jsonStr = await inputFile.readAsString();
  final Map<String, dynamic> tokens = jsonDecode(jsonStr);

  // --- Generate tokens file ---
  final tokenBuffer = StringBuffer();
  tokenBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  tokenBuffer.writeln('import \'package:flutter/material.dart\';\n');
  tokenBuffer.writeln('class MdsTokens {');

  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      tokenBuffer.writeln('  static final $category = _${_capitalize(category)}();');
    }
  });
  tokenBuffer.writeln('}\n');

  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      tokenBuffer.writeln('class _${_capitalize(category)} {');
      values.forEach((k, v) {
        if (v is Map<String, dynamic> && v.containsKey('value')) {
          final val = v['value'];
          final type = v['type'] ?? '';
          switch (type) {
            case 'color':
              final hex = val is String ? val.replaceAll('#', '') : '000000';
              tokenBuffer.writeln('  Color get $k => Color(0xFF$hex);');
              break;
            case 'dimension':
            case 'borderRadius':
              tokenBuffer.writeln('  double get $k => ${_parseDouble(val)};');
              break;
            default:
              tokenBuffer.writeln('  dynamic get $k => ${_encodeValue(val)};');
          }
        } else {
          tokenBuffer.writeln('  dynamic get $k => ${_encodeValue(v)};');
        }
      });
      tokenBuffer.writeln('}\n');
    }
  });

  final tokenFile = File(tokenOutputPath);
  tokenFile.parent.createSync(recursive: true);
  await tokenFile.writeAsString(tokenBuffer.toString());
  print('✅ Tokens generated to $tokenOutputPath');

  // --- Generate widget classes ---
  if (tokens.containsKey('registry') &&
      tokens['registry'] is Map<String, dynamic>) {
    final registry = tokens['registry'] as Map<String, dynamic>;

    for (final compName in registry.keys) {
      final compData = registry[compName];

      // snake_case file name
      final fileName = compName.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]}_${m[2]}',
      ).toLowerCase();

      final compFile = File('$componentBasePath/$fileName.dart');
      compFile.parent.createSync(recursive: true);

      final regBuffer = StringBuffer();
      regBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
      regBuffer.writeln('import \'package:flutter/material.dart\';');
      regBuffer.writeln('import \'../design_tokens/mds_tokens.dart\';\n');

      // class definition
      regBuffer.writeln('class $compName extends StatelessWidget {');
      regBuffer.writeln('  final ButtonStyle? style;');
      regBuffer.writeln('  final Widget child;');
      regBuffer.writeln('  final Icon? icon;');
      regBuffer.writeln('  final bool iconVisible;');
      regBuffer.writeln('  final VoidCallback onPressed;\n');

      // constructor
      regBuffer.writeln('  const $compName({');
      regBuffer.writeln('    this.style,');
      regBuffer.writeln('    required this.child,');
      regBuffer.writeln('    this.icon,');
      regBuffer.writeln('    this.iconVisible = false,');
      regBuffer.writeln('    required this.onPressed,');
      regBuffer.writeln('    super.key,');
      regBuffer.writeln('  });\n');

      // variant factory
      regBuffer.writeln('  factory $compName.variant({');
      regBuffer.writeln('    required String variant,');
      regBuffer.writeln('    required VoidCallback onPressed,');
      regBuffer.writeln('    Widget? child,');
      regBuffer.writeln('    Icon? icon,');
      regBuffer.writeln('    ButtonStyle? style,');
      regBuffer.writeln('    bool? iconVisible,');
      regBuffer.writeln('  }) {');
      regBuffer.writeln('    late ButtonStyle defaultStyle;');
      regBuffer.writeln('    late Widget defaultChild;');
      regBuffer.writeln('    late Icon? defaultIcon;');
      regBuffer.writeln('    late bool defaultIconVisible;\n');

      if (compData is Map<String, dynamic>) {
        regBuffer.writeln('    switch(variant) {');
        compData.forEach((variantName, props) {
          regBuffer.writeln("      case '$variantName':");

          // style
          final styleVal = props['style'];
          if (styleVal is Map && styleVal['type'] == 'style') {
            final styleMap = styleVal['value'] as Map;
            final bg = styleMap['backgroundColor'] ?? 'MdsTokens.color2.primary';
            final pad = styleMap['padding'] ?? 'MdsTokens.pad2.md';
            final radius = styleMap['radius'] ?? 'MdsTokens.radius2.sm';

            regBuffer.writeln('        defaultStyle = ElevatedButton.styleFrom(');
            regBuffer.writeln('          backgroundColor: MdsTokens.${bg.replaceAll('.', '.')} ,');
            regBuffer.writeln('          padding: EdgeInsets.all(MdsTokens.${pad.replaceAll('.', '.')}),');
            regBuffer.writeln('          shape: RoundedRectangleBorder(');
            regBuffer.writeln('            borderRadius: BorderRadius.circular(MdsTokens.${radius.replaceAll('.', '.')}),');
            regBuffer.writeln('          ),');
            regBuffer.writeln('        );');
          } else {
            regBuffer.writeln('        defaultStyle = ElevatedButton.styleFrom();');
          }

          // child
          final childVal = props['child']?['value'] ?? 'Label';
          regBuffer.writeln("        defaultChild = Text('$childVal');");

          // icon
          regBuffer.writeln('        defaultIcon = null;');

          // iconVisible
          final iconVisibleVal =
              props['iconVisible']?['value']?.toString().toLowerCase() == 'true'
                  ? 'true'
                  : 'false';
          regBuffer.writeln('        defaultIconVisible = $iconVisibleVal;');

          regBuffer.writeln('        break;');
        });
        regBuffer.writeln('      default:');
        regBuffer.writeln("        throw Exception('Unknown variant \$variant');");
        regBuffer.writeln('    }');
      }

      regBuffer.writeln('    return $compName(');
      regBuffer.writeln('      style: style ?? defaultStyle,');
      regBuffer.writeln('      child: child ?? defaultChild,');
      regBuffer.writeln('      icon: icon ?? defaultIcon,');
      regBuffer.writeln('      iconVisible: iconVisible ?? defaultIconVisible,');
      regBuffer.writeln('      onPressed: onPressed,');
      regBuffer.writeln('    );');
      regBuffer.writeln('  }\n');

      // build method
      regBuffer.writeln('  @override');
      regBuffer.writeln('  Widget build(BuildContext context) {');
      regBuffer.writeln('    return ElevatedButton.icon(');
      regBuffer.writeln('      onPressed: onPressed,');
      regBuffer.writeln('      icon: icon ?? SizedBox.shrink(),');
      regBuffer.writeln('      label: child,');
      regBuffer.writeln('      style: style ?? ElevatedButton.styleFrom(),');
      regBuffer.writeln('    );');
      regBuffer.writeln('  }');

      regBuffer.writeln('}\n');

      await compFile.writeAsString(regBuffer.toString());
      print('✅ Widget class generated for $compName at $compFile');
    }
  }
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
  if (val is bool)
