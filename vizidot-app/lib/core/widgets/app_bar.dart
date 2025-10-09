import 'package:flutter/material.dart';

class AppBarX extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  const AppBarX({super.key, required this.title, this.actions, this.centerTitle = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: centerTitle,
    );
  }
}


