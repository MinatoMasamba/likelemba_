// lib/presentation/features/auth/widgets/auth_text_field.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de saisie stylisé "Liquid Glass" pour les formulaires d'authentification.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Widget? prefix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool enabled;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefix,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.enabled = true,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  static const String tag = 'AuthTextField';
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != null && !_hasError) {
        setState(() => _hasError = true);
        HapticFeedback.mediumImpact();
        print('$tag._validate - Erreur validation: $error');
      } else if (error == null && _hasError) {
        setState(() => _hasError = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final borderColor = _hasError
        ? const Color(0xFFE63946)
        : (isFocused ? const Color(0xFF00C9A7) : Colors.white.withOpacity(0.3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              color: isFocused ? const Color(0xFF00C9A7) : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isFocused ? 8 : 4, sigmaY: isFocused ? 8 : 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isFocused ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  if (widget.prefix != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: widget.prefix,
                    ),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      maxLength: widget.maxLength,
                      enabled: widget.enabled,
                      onChanged: (_) => _validate(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        counterText: '',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  if (_hasError)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.error_outline, color: Color(0xFFE63946), size: 20),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}