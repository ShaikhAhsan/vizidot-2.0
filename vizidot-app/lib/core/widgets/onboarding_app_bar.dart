import 'package:flutter/material.dart';

class OnboardingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String imageAsset;
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingAppBar({
    super.key,
    required this.imageAsset,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    final double toolbar = (112 - top).clamp(56.0, 112.0);
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      leadingWidth: showBack ? 64 : 0,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 16, top: 0, bottom: 14),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: Image.asset('assets/icons/back-arrow-ic.png', width: 18, height: 18),
                  splashRadius: 24,
                ),
              ),
            )
          : null,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


