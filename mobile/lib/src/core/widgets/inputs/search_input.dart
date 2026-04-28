import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    this.controller,
    this.hintText = 'Berber, hizmet veya semt ara',
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Filtrele',
          onPressed: onFilterTap,
          icon: const Icon(Icons.tune),
        ),
        hintText: hintText,
      ),
    );
  }
}
