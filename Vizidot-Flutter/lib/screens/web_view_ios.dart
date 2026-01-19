import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/selected_artist.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';

class WebScreeniOS extends StatefulWidget {
  String url;
  String title;

  WebScreeniOS({Key? key, required this.url, required this.title})
      : super(key: key);

  @override
  State<WebScreeniOS> createState() => _WebScreeniOSState();
}

class _WebScreeniOSState extends State<WebScreeniOS> {
  @override
  int pos = 1;
  late final Future<WebViewController> controller;
  late WebViewController _webViewController;

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppArtist>(builder: (context, appArtist, child) {
      return Scaffold(
          appBar: getAppBar(widget.title),
          backgroundColor: kBackgroundColor,
          body: SafeArea(
              child: WebView(
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _webViewController = controller;
              reloadWebView();
            },
            onPageStarted: (urlString) {
              print(urlString);
            },
            initialUrl: widget.url,
          )));
    });
  }

  void reloadWebView() {
    _webViewController.loadUrl(widget.url);
    _webViewController.reload();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
