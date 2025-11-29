import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/elocker_controller.dart';
import '../widgets/media_card.dart';
import '../widgets/section_header.dart';
import '../../../routes/app_pages.dart';

class ELockerView extends GetView<ELockerController> {
  const ELockerView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  // FEATURED Section
                  const SectionHeader(title: 'FEATURED'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 174,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.featuredArtists.length,
                          itemBuilder: (context, index) {
                            final artist = controller.featuredArtists[index];
                            return MediaCard(
                              title: artist.name,
                              artist: artist.genre,
                              asset: artist.asset,
                              isHorizontal: true,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(30),
                              ),
                            );
                          },
                        )),
                  ),
                  const SizedBox(height: 32),
                  // RISING STARS Section
                  const SectionHeader(title: 'RISING STARS'),
                  const SizedBox(height: 16),
                  Obx(() => Column(
                        children: List.generate(
                          controller.risingStars.length,
                          (index) {
                            final artist = controller.risingStars[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < controller.risingStars.length - 1 ? 16 : 0,
                              ),
                              child: Row(
                                children: [
                                  // Artist Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      artist.asset,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Artist Info
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
}

