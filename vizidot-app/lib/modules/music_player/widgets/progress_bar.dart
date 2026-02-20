import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';

class MusicProgressBar extends StatelessWidget {
  final double height;
  final double borderRadius;

  const MusicProgressBar({
    super.key,
    this.height = 2,
    this.borderRadius = 1,
  });

  void _seekToPosition(BuildContext context, MusicPlayerController controller, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPosition = box.globalToLocal(globalPosition);
    final width = box.size.width;
    final newPosition = (localPosition.dx / width).clamp(0.0, 1.0);
    if (controller.duration.value.inMilliseconds > 0) {
      final newDuration = Duration(
        milliseconds: (controller.duration.value.inMilliseconds * newPosition).round(),
      );
      controller.seek(newDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds / controller.duration.value.inMilliseconds
          : 0.0;

      return GestureDetector(
        onTapDown: (details) => _seekToPosition(context, controller, details.globalPosition),
        onPanUpdate: (details) => _seekToPosition(context, controller, details.globalPosition),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final progressValue = progress.clamp(0.0, 1.0);
            final progressWidth = constraints.maxWidth * progressValue;
            
            return Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: progressWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

