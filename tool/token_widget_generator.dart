// tool/generate_tokens.dart
// FULL generator: tokens -> packages/fmi_core/lib/design_tokens/mds_tokens.dart
// and registry -> packages/fmi_core/lib/components/<component>.dart
//
// NOTE:
// - Token generation & validation logic preserved from original script.
// - STEP 4 (widget generator) enhanced to generate Buttons and Cards,
//   resolve style tokens (color/padding/radius) and map numeric values
//   to nearest token if available.

import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'tokens/tokens.json';
  final tokenOutputPath =
      'packages/fmi_core/lib/design_tokens/mds_tokens.dart';
  final componentBasePath = 'packages/fmi_core/lib/components/new';

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
  final oldFile = File(tokenOutputPath);
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
      print(
          '❌ Validation failed: Some tokens disappeared compared to previous file.');
      missing.forEach((cat, props) {
        print(' - Category $cat: missing ${props.join(', ')}');
      });
      exit(1);
    }
  }

  // --- STEP 3: Generate tokens file ---
  final tokenBuffer = StringBuffer();
  tokenBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  tokenBuffer.writeln('import \'package:flutter/material.dart\';\n');
  tokenBuffer.writeln('class MdsTokens {');

  tokens.forEach((category, values) {
    if (values is Map<String, dynamic> && values.isNotEmpty) {
      tokenBuffer
          .writeln('  static final $category = _${_capitalize(category)}();');
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

  // --- STEP 4: Generate widget classes (Buttons & Cards) ---
  if (tokens.containsKey('registry') && tokens['registry'] is Map<String, dynamic>) {
    final registry = tokens['registry'] as Map<String, dynamic>;

    for (final compName in registry.keys) {
      final compData = registry[compName];

      // normalize filename to snake_case
      final fileName = _toSnakeCase(compName);
      final compFile = File('$componentBasePath/$fileName.dart');
      compFile.parent.createSync(recursive: true);

      final regBuffer = StringBuffer();
      regBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
      regBuffer.writeln('import \'package:flutter/material.dart\';');
      regBuffer.writeln('import \'../design_tokens/mds_tokens.dart\';\n');

      // decide component type: button | card | generic
      final lower = compName.toLowerCase();
      if (lower.contains('button')) {
        _generateButtonClass(regBuffer, compName, compData, tokens);
      } else if (lower.contains('card')) {
        _generateCardClass(regBuffer, compName, compData, tokens);
      } else {
        // fallback: generate a simple wrapper (kept minimal)
        _generateGenericClass(regBuffer, compName, compData);
      }

      await compFile.writeAsString(regBuffer.toString());
      print('✅ Widget class generated for $compName at $compFile');
    }
  }
}

/// ----------------- Generator helpers -----------------

void _generateButtonClass(StringBuffer b, String className,
    dynamic compData, Map<String, dynamic> tokens) {
  b.writeln('class $className extends StatelessWidget {');
  b.writeln('  final ButtonStyle? style;');
  b.writeln('  final Widget child;');
  b.writeln('  final Icon? icon;');
  b.writeln('  final bool iconVisible;');
  b.writeln('  final VoidCallback onPressed;\n');

  b.writeln('  const $className({');
  b.writeln('    this.style,');
  b.writeln('    required this.child,');
  b.writeln('    this.icon,');
  b.writeln('    this.iconVisible = false,');
  b.writeln('    required this.onPressed,');
  b.writeln('    super.key,');
  b.writeln('  });\n');

  // factory.variant
  b.writeln('  factory $className.variant({');
  b.writeln('    required String variant,');
  b.writeln('    required VoidCallback onPressed,');
  b.writeln('    Widget? child,');
  b.writeln('    Icon? icon,');
  b.writeln('    ButtonStyle? style,');
  b.writeln('    bool? iconVisible,');
  b.writeln('  }) {');
  b.writeln('    late ButtonStyle defaultStyle;');
  b.writeln('    late Widget defaultChild;');
  b.writeln('    late Icon? defaultIcon;');
  b.writeln('    late bool defaultIconVisible;\n');

  if (compData is Map<String, dynamic>) {
    b.writeln('    switch (variant) {');
    compData.forEach((variantName, props) {
      b.writeln("      case '$variantName':");

      // props['style'] parsing -> support nested token format or legacy string
      final styleVal = _safeGet(props, 'style');
      if (styleVal is Map && styleVal['type'] == 'style') {
        final styleMap = styleVal['value'] as Map<String, dynamic>;

        final bgToken = _resolveColorTokenFromStyle(styleMap, tokens) ??
            'color2.primary'; // fallback token string
        final radiusToken =
            _resolveRadiusTokenFromStyle(styleMap, tokens) ?? 'radius2.sm';

        // padding logic: support all/fromLTRB
        final paddingExpr = _buildPaddingExpressionFromStyle(styleMap, tokens);

        b.writeln('        defaultStyle = ElevatedButton.styleFrom(');
        // backgroundColor as token
        b.writeln('          backgroundColor: MdsTokens.${bgToken},');
        // padding (EdgeInsets)
        if (paddingExpr != null) {
          b.writeln('          padding: $paddingExpr,');
        }
        // shape / radius
        b.writeln(
            '          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MdsTokens.${radiusToken})),');
        b.writeln('        );');
      } else {
        b.writeln('        defaultStyle = ElevatedButton.styleFrom();');
      }

      // child default
      final childVal = _safeGet(props, 'child') is Map
          ? (_safeGet(props, 'child')['value'] ?? 'Label')
          : (_safeGet(props, 'child') ?? 'Label');
      b.writeln("        defaultChild = Text('${_escapeDartString(childVal.toString())}');");

      // default icon (we don't map icon name to IconData here — keep null)
      b.writeln('        defaultIcon = null;');

      // iconVisible
      final iconVisibleRaw = _safeGet(props, 'iconVisible');
      final iconVisibleVal =
          _parseBoolish(iconVisibleRaw) ? 'true' : 'false';
      b.writeln('        defaultIconVisible = $iconVisibleVal;');

      b.writeln('        break;');
    });
    b.writeln("      default: throw Exception('Unknown variant \$variant');");
    b.writeln('    }');
  } else {
    b.writeln(
        "    defaultStyle = ElevatedButton.styleFrom(); defaultChild = Text('Label'); defaultIcon = null; defaultIconVisible = false;");
  }

  // return
  b.writeln('    return $className(');
  b.writeln('      style: style ?? defaultStyle,');
  b.writeln('      child: child ?? defaultChild,');
  b.writeln('      icon: icon ?? defaultIcon,');
  b.writeln('      iconVisible: iconVisible ?? defaultIconVisible,');
  b.writeln('      onPressed: onPressed,');
  b.writeln('    );');
  b.writeln('  }\n');

  // build
  b.writeln('  @override');
  b.writeln('  Widget build(BuildContext context) {');
  b.writeln('    if (iconVisible && icon != null) {');
  b.writeln('      return ElevatedButton.icon(');
  b.writeln('        onPressed: onPressed,');
  b.writeln('        icon: icon!,');
  b.writeln('        label: child,');
  b.writeln('        style: style ?? ElevatedButton.styleFrom(),');
  b.writeln('      );');
  b.writeln('    }');
  b.writeln('    return ElevatedButton(');
  b.writeln('      onPressed: onPressed,');
  b.writeln('      child: child,');
  b.writeln('      style: style ?? ElevatedButton.styleFrom(),');
  b.writeln('    );');
  b.writeln('  }');

  b.writeln('}\n');
}

void _generateCardClass(StringBuffer b, String className, dynamic compData,
    Map<String, dynamic> tokens) {
  b.writeln('class $className extends StatelessWidget {');
  b.writeln('  final Widget? header;');
  b.writeln('  final Widget? body;');
  b.writeln('  final Widget? footer;');
  b.writeln('  const $className({this.header, this.body, this.footer, super.key});\n');

  b.writeln('  factory $className.variant({required String variant, Widget? header, Widget? body, Widget? footer}) {');
  b.writeln('    late Color defaultBg;');
  b.writeln('    late EdgeInsets defaultPadding;');
  b.writeln('    late BorderRadius defaultRadius;\n');

  if (compData is Map<String, dynamic>) {
    b.writeln('    switch (variant) {');
    compData.forEach((variantName, props) {
      b.writeln("      case '$variantName':");

      final styleVal = _safeGet(props, 'style');
      if (styleVal is Map && styleVal['type'] == 'style') {
        final styleMap = styleVal['value'] as Map<String, dynamic>;

        final bgToken = _resolveColorTokenFromStyle(styleMap, tokens);
        final radiusToken = _resolveRadiusTokenFromStyle(styleMap, tokens);
        final paddingExpr = _buildPaddingExpressionFromStyle(styleMap, tokens);

        if (bgToken != null) {
          b.writeln('        defaultBg = MdsTokens.${bgToken};');
        } else {
          // fallback white
          b.writeln('        defaultBg = Colors.white;');
        }

        if (paddingExpr != null) {
          b.writeln('        defaultPadding = $paddingExpr;');
        } else {
          b.writeln('        defaultPadding = EdgeInsets.zero;');
        }

        if (radiusToken != null) {
          b.writeln('        defaultRadius = BorderRadius.circular(MdsTokens.${radiusToken});');
        } else {
          b.writeln('        defaultRadius = BorderRadius.circular(0);');
        }
      } else {
        b.writeln('        defaultBg = Colors.white;');
        b.writeln('        defaultPadding = EdgeInsets.zero;');
        b.writeln('        defaultRadius = BorderRadius.circular(0);');
      }

      b.writeln('        break;');
    });
    b.writeln("      default: throw Exception('Unknown variant \$variant');");
    b.writeln('    }');
  } else {
    b.writeln('    defaultBg = Colors.white; defaultPadding = EdgeInsets.zero; defaultRadius = BorderRadius.circular(0);');
  }

  b.writeln('    return $className(header: header, body: body, footer: footer);');
  b.writeln('  }\n');

  // build
  b.writeln('  @override');
  b.writeln('  Widget build(BuildContext context) {');
  b.writeln('    return Container(');
  b.writeln('      decoration: BoxDecoration(');
  b.writeln('        color: defaultBg ?? Colors.white,'); // safe: defaultBg assigned in factory
  b.writeln('        borderRadius: defaultRadius ?? BorderRadius.circular(0),');
  b.writeln('      ),');
  b.writeln('      padding: defaultPadding ?? EdgeInsets.zero,');
  b.writeln('      child: Column(');
  b.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
  b.writeln('        children: [');
  b.writeln('          if (header != null) header!,');
  b.writeln('          if (body != null) body!,');
  b.writeln('          if (footer != null) footer!,');
  b.writeln('        ],');
  b.writeln('      ),');
  b.writeln('    );');
  b.writeln('  }');

  b.writeln('}\n');
}

void _generateGenericClass(StringBuffer b, String className, dynamic compData) {
  b.writeln('class $className extends StatelessWidget {');
  b.writeln('  final Widget? child;');
  b.writeln('  const $className({this.child, super.key});\n');
  b.writeln('  @override');
  b.writeln('  Widget build(BuildContext context) {');
  b.writeln('    return Container(child: child);');
  b.writeln('  }');
  b.writeln('}\n');
}

/// ----------------- Style token resolution helpers -----------------

/// Safely get nested property with null checks
dynamic _safeGet(Map props, String key) {
  try {
    return props[key];
  } catch (_) {
    return null;
  }
}

String? _resolveColorTokenFromStyle(Map<String, dynamic> styleMap, Map tokens) {
  // styleMap['backgroundColor'] can be:
  // - Map with token: { "token":"color2.primary", "type":"color" }
  // - String token "color2.primary"
  // - Hex string "#RRGGBB"
  final bg = styleMap['backgroundColor'];
  if (bg == null) return null;

  if (bg is Map && bg.containsKey('token')) {
    return bg['token'] as String;
  }

  if (bg is String) {
    if (bg.startsWith('#')) {
      // try to map hex to existing color token
      final found = _findColorTokenForHex(bg, tokens);
      return found;
    } else {
      // assume it's token string like 'color2.primary'
      return bg;
    }
  }

  return null;
}

String? _resolveRadiusTokenFromStyle(Map<String, dynamic> styleMap, Map tokens) {
  final r = styleMap['radius'];
  if (r == null) return null;

  if (r is Map && r.containsKey('token')) {
    return r['token'] as String;
  }

  if (r is num) {
    // try to find token in radius categories
    final found = _findRadiusTokenForValue(r.toDouble(), tokens);
    return found;
  }

  if (r is String && r.startsWith('radius')) {
    return r;
  }

  return null;
}

String? _buildPaddingExpressionFromStyle(Map<String, dynamic> styleMap, Map tokens) {
  final padding = styleMap['padding'];
  if (padding == null) return null;

  // padding can be:
  // - Map with top/bottom/left/right each either {token:..., type:...} or numeric
  // - single token string (e.g. "pad2.md")
  if (padding is String) {
    // treat as all-sides token
    return 'EdgeInsets.all(MdsTokens.${padding})';
  }

  if (padding is Map) {
    // detect if it's per-side or a single token under 'value'
    // per-side: padding['top'] -> {token: 'pad2.md', type: 'spacing'} or numeric
    final top = padding['top'];
    final bottom = padding['bottom'];
    final left = padding['left'];
    final right = padding['right'];

    // resolve each to token or numeric expression
    final topExpr = _resolveSpacingTokenOrLiteral(top, tokens) ?? '0.0';
    final bottomExpr = _resolveSpacingTokenOrLiteral(bottom, tokens) ?? '0.0';
    final leftExpr = _resolveSpacingTokenOrLiteral(left, tokens) ?? '0.0';
    final rightExpr = _resolveSpacingTokenOrLiteral(right, tokens) ?? '0.0';

    return 'EdgeInsets.fromLTRB($leftExpr, $topExpr, $rightExpr, $bottomExpr)';
  }

  // numeric value (all sides)
  if (padding is num) {
    final token = _findSpacingTokenForValue(padding.toDouble(), tokens);
    if (token != null) {
      return 'EdgeInsets.all(MdsTokens.${token})';
    } else {
      return 'EdgeInsets.all(${padding.toDouble()})';
    }
  }

  return null;
}

/// If input is either {token: 'pad2.md', ...} or numeric, return expression string
/// like 'MdsTokens.pad2.md' or literal '12.0'
String? _resolveSpacingTokenOrLiteral(dynamic input, Map tokens) {
  if (input == null) return null;
  if (input is Map && input.containsKey('token')) {
    return 'MdsTokens.${input['token']}';
  }
  if (input is num) {
    final token = _findSpacingTokenForValue(input.toDouble(), tokens);
    if (token != null) return 'MdsTokens.$token';
    return input.toString();
  }
  if (input is String) {
    // token string?
    if (input.startsWith('pad') || input.contains('.')) {
      // assume token string (e.g. 'pad2.md' or 'pad2.md' already dotted)
      return 'MdsTokens.${input}';
    }
    // maybe numeric string
    final numVal = double.tryParse(input);
    if (numVal != null) {
      final token = _findSpacingTokenForValue(numVal, tokens);
      if (token != null) return 'MdsTokens.$token';
      return numVal.toString();
    }
  }
  return null;
}

/// Search tokens for a spacing token whose numeric value matches (or nearest).
/// Returns token path like 'pad2.md' or null.
String? _findSpacingTokenForValue(double value, Map tokens) {
  // Look through token categories for ones containing 'pad' or 'gap'
  final candidates = <String, double>{}; // tokenPath -> numericValue
  tokens.forEach((category, mapVal) {
    if (mapVal is Map<String, dynamic> &&
        (category.toLowerCase().contains('pad') ||
            category.toLowerCase().contains('gap') ||
            category.toLowerCase().contains('spacing'))) {
      mapVal.forEach((k, v) {
        if (v is Map && v.containsKey('value')) {
          final raw = v['value'];
          final numVal = _tryParseNum(raw);
          if (numVal != null) {
            candidates['$category.$k'] = numVal;
          }
        }
      });
    }
  });

  if (candidates.isEmpty) return null;

  // find exact first, then nearest within tolerance
  for (final e in candidates.entries) {
    if ((e.value - value).abs() < 0.0001) return e.key;
  }

  // nearest
  final nearest = candidates.entries.reduce((a, b) =>
      (a.value - value).abs() < (b.value - value).abs() ? a : b);
  // set a tolerance: if difference less than, say, 4 px, accept
  if ((nearest.value - value).abs() <= 4.0) return nearest.key;
  return null;
}

String? _findRadiusTokenForValue(double value, Map tokens) {
  final candidates = <String, double>{};
  tokens.forEach((category, mapVal) {
    if (mapVal is Map<String, dynamic> &&
        category.toLowerCase().contains('radius')) {
      mapVal.forEach((k, v) {
        if (v is Map && v.containsKey('value')) {
          final raw = v['value'];
          final numVal = _tryParseNum(raw);
          if (numVal != null) {
            candidates['$category.$k'] = numVal;
          }
        }
      });
    }
  });

  if (candidates.isEmpty) return null;

  // exact match
  for (final e in candidates.entries) {
    if ((e.value - value).abs() < 0.0001) return e.key;
  }

  final nearest = candidates.entries.reduce((a, b) =>
      (a.value - value).abs() < (b.value - value).abs() ? a : b);
  if ((nearest.value - value).abs() <= 4.0) return nearest.key;
  return null;
}

String? _findColorTokenForHex(String hex, Map tokens) {
  final normalized = hex.toUpperCase().replaceAll('#', '');
  tokens.forEach((category, mapVal) {
    if (mapVal is Map<String, dynamic> &&
        category.toLowerCase().contains('color')) {
      mapVal.forEach((k, v) {
        if (v is Map && v.containsKey('value')) {
          final raw = v['value'];
          if (raw is String && raw.replaceAll('#', '').toUpperCase() == normalized) {
            // return token path
            return;
          }
        }
      });
    }
  });

  // second pass that returns first match via building list and checking
  for (final category in tokens.keys) {
    final mapVal = tokens[category];
    if (mapVal is Map<String, dynamic> &&
        category.toLowerCase().contains('color')) {
      for (final k in mapVal.keys) {
        final v = mapVal[k];
        if (v is Map && v.containsKey('value')) {
          final raw = v['value'];
          if (raw is String && raw.replaceAll('#', '').toUpperCase() == normalized) {
            return '$category.$k';
          }
        }
      }
    }
  }

  return null;
}

/// Utility: try parse numeric value from token raw value
double? _tryParseNum(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    return double.tryParse(raw.replaceAll('px', '').replaceAll('%', ''));
  }
  return null;
}

/// Parse "boolean-like" values: accepts bool, "true"/"false" strings, maps other to false
bool _parseBoolish(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is Map && val.containsKey('value')) {
    final v = val['value'];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
  }
  if (val is String) return val.toLowerCase() == 'true';
  return false;
}

/// Escape single quotes in string for Dart literal
String _escapeDartString(String s) => s.replaceAll("'", "\\'");

String _toSnakeCase(String input) {
  final noDash = input.replaceAll('-', '_');
  final withUnderscore = noDash.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}');
  return withUnderscore.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
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
