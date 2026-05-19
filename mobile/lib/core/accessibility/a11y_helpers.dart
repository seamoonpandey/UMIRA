import 'package:flutter/material.dart';

class A11y {
  static Widget liveLabel(String text) =>
      Semantics(liveRegion: true, child: Text(text));

  static Widget tap({
    required String label,
    String? hint,
    required VoidCallback onTap,
    required Widget child,
  }) =>
      Semantics(
        label: label,
        hint: hint,
        button: true,
        onTap: onTap,
        child: GestureDetector(onTap: onTap, child: child),
      );
}
