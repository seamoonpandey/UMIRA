import 'package:flutter/material.dart';

class UmiraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final int? maxLines;
  final Iterable<String>? autofillHints;
  final String? hint;
  const UmiraTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.maxLines = 1,
    this.autofillHints,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      autofillHints: autofillHints,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
