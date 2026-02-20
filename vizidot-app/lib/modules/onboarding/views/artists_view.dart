import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/artists_controller.dart';

class ArtistsView extends GetView<ArtistsController> {
  const ArtistsView({super.key});

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
              Text('Artists', style: textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Select three or more artists to follow', style: textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.items.isEmpty) {
                    return Center(
                      child: Text(
                        'No artists available',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.items.length + (controller.hasMore.value ? 1 : 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= controller.items.length) {
                        controller.loadMore();
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        ));
                      }
                      final item = controller.items[index];
                      return Obx(() {
                        final isSelected = controller.selected.contains(item.id);
                        return isSelected
                            ? _SelectedArtistCard(
                                key: ValueKey('artist_${item.id}_1'),
                                name: item.name,
                                imageUrl: item.imageUrl,
                                onTap: () => controller.toggle(index),
                              )
                            : _UnselectedArtistCard(
                                key: ValueKey('artist_${item.id}_0'),
                                name: item.name,
                                imageUrl: item.imageUrl,
                                onTap: () => controller.toggle(index),
                              );
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () => Get.offAllNamed('/'), child: const Text('Skip')),
                  const SizedBox(width: 5),
                  Obx(() => InkWell(
                        onTap: controller.canContinue && !controller.isSaving.value
                            ? () => controller.onContinue()
                            : null,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: controller.canContinue && !controller.isSaving.value
                                ? (isDark ? Colors.white : Colors.black)
                                : colors.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: controller.isSaving.value
                              ? Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
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

Widget _artistImage(String? imageUrl, double size) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(size),
    );
  }
  return _placeholder(size);
}

Widget _placeholder(double size) {
  return Container(
    width: size,
    height: size,
    color: Colors.grey.shade300,
    child: Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade600),
  );
}

class _UnselectedArtistCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _UnselectedArtistCard({super.key, required this.name, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: _tileRadius,
      child: SizedBox(
        width: 97,
        height: 122,
        child: Column(
          children: [
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: _tileRadius,
              child: Stack(
                children: [
                  SizedBox(width: 78, height: 78, child: _artistImage(imageUrl, 78)),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                    child: Container(width: 78, height: 78, color: Colors.white.withOpacity(0.50)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onBackground), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SelectedArtistCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SelectedArtistCard({super.key, required this.name, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: _tileRadius,
      child: SizedBox(
        width: 97,
        height: 122,
        child: Column(
          children: [
            Row(children: [const Spacer(), Icon(Icons.check_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 18)]),
            Container(
              width: 78,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: _tileRadius,
                boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.25), blurRadius: 24, spreadRadius: 2)],
              ),
              child: ClipRRect(borderRadius: _tileRadius, child: _artistImage(imageUrl, 78)),
            ),
            const SizedBox(height: 6),
            Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onBackground), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
