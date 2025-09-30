library design_tokens;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class DesignTokens {
  static Map<String, dynamic>? _tokens;

  /// Harus dipanggil sekali di awal (misalnya di main)
  static Future<void> load() async {
    final jsonStr = await rootBundle.loadString('packages/assets/tokens.json');
    _tokens = jsonDecode(jsonStr);
  }

  /// Colors
  static _ColorTokens get color => _ColorTokens(_tokens?['colors']);

  /// Spacing
  static _SpacingTokens get spacing => _SpacingTokens(_tokens?['spacing']);

  /// Typography
  static _TypographyTokens get typography =>
      _TypographyTokens(_tokens?['typography']);
}

/// Subclass untuk Colors
class _ColorTokens {
  final Map<String, dynamic>? _data;
  _ColorTokens(this._data);

  Color? operator [](String key) {
    final hex = _data?[key]?['value'];
    if (hex == null) return null;
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }

  // contoh: DesignTokens.color.primary
  Color? get primary => this['primary'];
  Color? get text => this['text'];
}

/// Subclass untuk Spacing
class _SpacingTokens {
  final Map<String, dynamic>? _data;
  _SpacingTokens(this._data);

  double? operator [](String key) => (_data?[key]?['value'] ?? 0).toDouble();

  double? get sm => this['sm'];
  double? get md => this['md'];
}

/// Subclass untuk Typography
class _TypographyTokens {
  final Map<String, dynamic>? _data;
  _TypographyTokens(this._data);

  Map<String, dynamic>? operator [](String key) => _data?[key];

  TextStyle? get body2 {
    final t = this['body2'];
    if (t == null) return null;
    return TextStyle(
      fontSize: (t['fontSize']?['value'] ?? 14).toDouble(),
      fontWeight: _toFontWeight(t['fontWeight']?['value']),
      height:
          (t['lineHeight']?['value'] ?? 1.2) / (t['fontSize']?['value'] ?? 14),
    );
  }

  static FontWeight _toFontWeight(String? value) {
    switch (value) {
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '700':
        return FontWeight.w700;
      default:
        return FontWeight.normal;
    }
  }
}
