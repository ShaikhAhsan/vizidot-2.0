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

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            // largeTitle: const Text(
            //   'Best of the week'
            // ),
            largeTitle: Text('Best of the week'),

            // middle:  const Text(
            // 'Best of the week'
            // ),
            // leading: Icon(CupertinoIcons.person_2),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white, // background
                borderRadius: BorderRadius.circular(12), // rounded corners
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () {
                  // TODO: Show options menu
                },
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Colors.black, // dot color
                  size: 20,
                ),
              ),
            ),
            // backgroundColor: Colors.transparent,
            // border: null,
            // automaticBackgroundVisibility: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  // TOP AUDIO Section
                  _SectionHeader(title: 'TOP AUDIO'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 177,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.topAudioItems.length,
                          itemBuilder: (context, index) {
                            final item = controller.topAudioItems[index];
                            return _MediaAudioCard(
                              title: item.title,
                              artist: item.artist,
                              asset: item.asset,
                            );
                          },
                        )),
                  ),
                  const SizedBox(height: 20),
                  // TOP VIDEO Section
                  _SectionHeader(title: 'TOP VIDEO'),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
          // TOP VIDEO Grid Section
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: Obx(() => SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.78, // Portrait aspect ratio accounting for text below
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.topVideoItems[index];
                        return _MediaCard(
                          title: item.title,
                          artist: item.artist,
                          asset: item.asset,
                        );
                      },
                      childCount: controller.topVideoItems.length,
                    ),
                  )),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 24),
          ),
        ],
      ),
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
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0,
          ),
    );
  }
}

class _MediaAudioCard extends StatelessWidget {
  final String title;
  final String artist;
  final String asset;

  const _MediaAudioCard({
    required this.title,
    required this.artist,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 107,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(30),
              ),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            artist,
            style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w800,
                fontSize: 10
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(

            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        const SizedBox(height: 5),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          artist,
          style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w800,
              fontSize: 10
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

