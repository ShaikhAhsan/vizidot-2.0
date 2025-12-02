import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/live_stream_controller.dart';

class LiveStreamFAB extends StatelessWidget {
  const LiveStreamFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveStreamController>();
    final colors = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: () => controller.startLiveStream(),
      backgroundColor: colors.primary,
      child: const Icon(
        CupertinoIcons.videocam_fill,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

