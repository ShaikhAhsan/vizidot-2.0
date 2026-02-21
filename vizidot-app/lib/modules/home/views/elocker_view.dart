import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/elocker_controller.dart';
import '../widgets/media_card.dart';
import '../widgets/section_header.dart';
import '../../../routes/app_pages.dart';
import '../../../core/utils/app_config.dart';

class ELockerView extends GetView<ELockerController> {
  const ELockerView({super.key});

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppConfig.fromEnv().baseUrl.replaceFirst(RegExp(r'/$'), '');

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('E-locker'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () {
                  Get.toNamed(AppRoutes.search);
                },
                child: const Icon(
                  CupertinoIcons.search,
                  color: Colors.black,
                  size: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  Obx(() {
                    if (controller.isLoading.value && controller.featuredArtists.isEmpty && controller.risingStars.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SectionHeader(title: 'FEATURED'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 174,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.featuredArtists.length,
                          itemBuilder: (context, index) {
                            final artist = controller.featuredArtists[index];
                            final imageUrl = _fullImageUrl(baseUrl, artist.imageUrl);
                            return MediaCard(
                              title: artist.name,
                              artist: artist.genre,
                              asset: '',
                              imageUrl: imageUrl,
                              artistId: artist.id,
                              isHorizontal: true,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(30),
                              ),
                              onTap: () => Get.toNamed(AppRoutes.artistDetail, parameters: {'id': artist.id.toString()}),
                            );
                          },
                        )),
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'RISING STARS'),
                  const SizedBox(height: 16),
                  Obx(() => Column(
                        children: List.generate(
                          controller.risingStars.length,
                          (index) {
                            final artist = controller.risingStars[index];
                            final imageUrl = _fullImageUrl(baseUrl, artist.imageUrl);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < controller.risingStars.length - 1 ? 16 : 0,
                              ),
                              child: InkWell(
                                onTap: () => Get.toNamed(AppRoutes.artistDetail, parameters: {'id': artist.id.toString()}),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _placeholder(context),
                                            )
                                          : _placeholder(context),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            artist.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            artist.genre,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _fullImageUrl(String baseUrl, String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 32),
    );
  }
}
