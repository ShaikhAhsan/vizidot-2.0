import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../music_player/controllers/music_player_controller.dart';

/// Full-screen WebView for opening a video URL (e.g. from artist Video tab).
/// Stops the music player when opened so video and music do not play together.
class VideoWebView extends StatefulWidget {
  final String url;

  const VideoWebView({super.key, required this.url});

  @override
  State<VideoWebView> createState() => _VideoWebViewState();
}

class _VideoWebViewState extends State<VideoWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stopMusicPlayer();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _stopMusicPlayer() {
    if (Get.isRegistered<MusicPlayerController>()) {
      Get.find<MusicPlayerController>().pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CupertinoActivityIndicator()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: Get.back,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_left,
                    color: colors.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
