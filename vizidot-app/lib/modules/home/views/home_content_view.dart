import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeContentView extends GetView<HomeController> {
  const HomeContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Best of the week'),
          centerTitle: false,
          titleSpacing: 0,
          floating: true,
          pinned: true,
          toolbarHeight: 44,
          expandedHeight: 96,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () {
                  // TODO: Show options menu
                },
                child: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: colors.onSurface,
                  size: 20,
                ),
              ),
            ),
          ],
          elevation: 0,
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text(
              'Best of the week',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.37,
              ),
            ),
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                // TOP AUDIO Section
                _SectionHeader(title: 'TOP AUDIO'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: Obx(() => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.topAudioItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.topAudioItems[index];
                          return _MediaCard(
                            title: item.title,
                            artist: item.artist,
                            asset: item.asset,
                          );
                        },
                      )),
                ),
                const SizedBox(height: 32),
                // TOP VIDEO Section
                _SectionHeader(title: 'TOP VIDEO'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: Obx(() => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.topVideoItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.topVideoItems[index];
                          return _MediaCard(
                            title: item.title,
                            artist: item.artist,
                            asset: item.asset,
                          );
                        },
                      )),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String title;
  final String artist;
  final String asset;

  const _MediaCard({
    required this.title,
    required this.artist,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artist,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

