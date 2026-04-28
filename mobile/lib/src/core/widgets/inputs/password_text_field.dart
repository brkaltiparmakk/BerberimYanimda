import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon = Icons.lock_outline,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? icon;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        hintText: widget.hintText,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
