import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Language selection screen. Currently only English is available.
class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  static const String _englishCode = 'en';
  static const String _englishLabel = 'English';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Language'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _LanguageTile(
                    languageCode: _englishCode,
                    label: _englishLabel,
                    isSelected: true,
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String languageCode;
  final String label;
  final bool isSelected;

  const _LanguageTile({
    required this.languageCode,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 22,
              color: colors.primary,
            ),
        ],
      ),
    );
  }
}
