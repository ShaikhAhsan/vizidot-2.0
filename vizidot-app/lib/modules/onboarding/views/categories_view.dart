import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text('Categories', style: textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Select three or more genres to match\nyour interests',
                  style: textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    return Obx(() {
                      final isSelected = controller.selected.contains(index);
                      return isSelected
                          ? _SelectedCategoryCard(
                              key: ValueKey('cat_${index}_1'),
                              name: item.name,
                              asset: item.asset,
                              onTap: () => controller.toggle(index),
                            )
                          : _UnselectedCategoryCard(
                              key: ValueKey('cat_${index}_0'),
                              name: item.name,
                              asset: item.asset,
                              onTap: () => controller.toggle(index),
                            );
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () => Get.offAllNamed('/artists'), child: const Text('Skip')),
                  const SizedBox(width: 5),
                  Obx(() => InkWell(
                        onTap: controller.canContinue
                            ? () {
                                Get.offAllNamed('/artists');
                              }
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: controller.canContinue
                                ? (isDark ? Colors.white : Colors.black)
                                : colors.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

const BorderRadius _tileRadius = BorderRadius.only(
  topLeft: Radius.circular(22),
  topRight: Radius.circular(5),
  bottomLeft: Radius.circular(5),
  bottomRight: Radius.circular(22),
);

class _UnselectedCategoryCard extends StatelessWidget {
  final String name;
  final String asset;
  final VoidCallback onTap;

  const _UnselectedCategoryCard({
    super.key,
    required this.name,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: _tileRadius,
      child: Container(
        width: 97,
        height: 122,
        child: Column(
          children: [
            SizedBox(height: 14),
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: _tileRadius,
              ),
              child: ClipRRect(
                borderRadius: _tileRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(asset, fit: BoxFit.cover),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                      child: Container(color: Colors.white.withOpacity(0.50)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onBackground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCategoryCard extends StatelessWidget {
  final String name;
  final String asset;
  final VoidCallback onTap;

  const _SelectedCategoryCard({
    super.key,
    required this.name,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    print("_SelectedCategoryCard");
    return InkWell(
      onTap: onTap,
      borderRadius: _tileRadius,
      child: Container(
        width: 97,
        height: 122,
        child: Column(
          children: [
            Row(
              children: [
                Spacer(),
                Container(
                  width: 18,
                  height: 18,
                  child: Icon(Icons.check_rounded, color: isDark ? Colors.white : Colors.black, size: 18),

                ),
              ],
            ),
            Container(
              width: 78,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: _tileRadius,
                boxShadow: [
                  BoxShadow(color: colors.primary.withOpacity(0.25), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: ClipRRect(
                borderRadius: _tileRadius,
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onBackground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


