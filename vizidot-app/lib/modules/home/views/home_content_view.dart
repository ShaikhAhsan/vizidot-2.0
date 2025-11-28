import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/media_card.dart';

class HomeContentView extends GetView<HomeController> {
  const HomeContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Best of the week'),
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
                  // TODO: Show options menu
                },
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
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
                  // TOP AUDIO Section
                  const SectionHeader(title: 'TOP AUDIO'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 174,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.topAudioItems.length,
                          itemBuilder: (context, index) {
                            final item = controller.topAudioItems[index];
                            return MediaCard(
                              title: item.title,
                              artist: item.artist,
                              asset: item.asset,
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
                  const SizedBox(height: 20),
                  // TOP VIDEO Section
                  const SectionHeader(title: 'TOP VIDEO'),
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
                      childAspectRatio: 0.6, // Portrait aspect ratio accounting for text below
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.topVideoItems[index];
                        return MediaCard(
                          title: item.title,
                          artist: item.artist,
                          asset: item.asset,
                          isHorizontal: false,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(40),
                          ),
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

