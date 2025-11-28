import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../routes/app_pages.dart';

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
                  _SectionHeader(title: 'TOP AUDIO'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 174,
                    child: Obx(() => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.topAudioItems.length,
                          itemBuilder: (context, index) {
                            final item = controller.topAudioItems[index];
                            return _MediaCard(
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
                      childAspectRatio: 0.6, // Portrait aspect ratio accounting for text below
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.topVideoItems[index];
                        return _MediaCard(
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

class _MediaCard extends StatefulWidget {
  final String title;
  final String artist;
  final String asset;
  final bool isHorizontal;
  final BorderRadius borderRadius;

  const _MediaCard({
    required this.title,
    required this.artist,
    required this.asset,
    required this.isHorizontal,
    required this.borderRadius,
  });

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    Widget imageWidget = ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.asset(
        widget.asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.isHorizontal ? 100 : double.infinity,
      ),
    );

    Widget titleWidget = Text(
      widget.title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    Widget artistNameWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.toNamed(
          AppRoutes.artistDetail,
          arguments: {
            'artistName': widget.artist,
            'artistImage': widget.asset,
            'description': 'Artist / Musician / Writer',
            'followers': 321000,
            'following': 125,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          widget.artist,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    Widget animatedImage = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.deferToChild,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: imageWidget,
          );
        },
      ),
    );

    Widget animatedTitle = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.deferToChild,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: titleWidget,
          );
        },
      ),
    );

    Widget imageAndTitle = widget.isHorizontal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              animatedImage,
              const SizedBox(height: 5),
              animatedTitle,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.75,
                child: animatedImage,
              ),
              const SizedBox(height: 5),
              animatedTitle,
            ],
          );

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.isHorizontal ? MainAxisSize.min : MainAxisSize.max,
      children: [
        imageAndTitle,
        const SizedBox(height: 10),
        artistNameWidget,
      ],
    );

    Widget wrappedContent = widget.isHorizontal
        ? Container(
            width: 107,
            margin: const EdgeInsets.only(right: 16),
            child: cardContent,
          )
        : cardContent;

    return wrappedContent;
  }
}

