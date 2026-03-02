import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app WebView for opening a link (e.g. Help Center, Privacy). Works reliably on iOS.
class LinkWebView extends StatefulWidget {
  final String url;
  final String title;

  const LinkWebView({
    super.key,
    required this.url,
    this.title = 'Link',
  });

  @override
  State<LinkWebView> createState() => _LinkWebViewState();
}

class _LinkWebViewState extends State<LinkWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static String _ensureScheme(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  @override
  void initState() {
    super.initState();
    final fullUrl = _ensureScheme(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(widget.title),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
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
            sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CupertinoActivityIndicator()),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}
