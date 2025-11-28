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
                      childAspectRatio: 0.78, // Portrait aspect ratio accounting for text below
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

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.isHorizontal
            ? ClipRRect(
                borderRadius: widget.borderRadius,
                child: Image.asset(
                  widget.asset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 107,
                ),
              )
            : Expanded(
                child: ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: Image.asset(
                    widget.asset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
        const SizedBox(height: 5),
        Text(
          widget.title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          widget.artist,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    Widget wrappedContent = widget.isHorizontal
        ? Container(
            width: 107,
            margin: const EdgeInsets.only(right: 16),
            child: cardContent,
          )
        : cardContent;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        // TODO: Handle card tap
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              child: wrappedContent,
            ),
          );
        },
      ),
    );
  }
}

