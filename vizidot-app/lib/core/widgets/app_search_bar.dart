import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AppSearchBar({super.key, this.hintText = 'Search…', this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hintText,
      leading: const Icon(Icons.search),
      onChanged: onChanged,
      controller: controller,
    );
  }
}


