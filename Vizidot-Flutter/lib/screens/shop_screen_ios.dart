import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/config.dart';
import 'package:vizidot_flutter/models/selected_artist.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';

class ShopScreeniOS extends StatefulWidget {
  const ShopScreeniOS({Key? key}) : super(key: key);

  @override
  State<ShopScreeniOS> createState() => _ShopScreeniOSState();
}

class _ShopScreeniOSState extends State<ShopScreeniOS> {
  @override
  int pos = 1;
  String shopUrl = 'https://shop.meekmill.com/';
  String title = 'Shop Screen';
  late final Future<WebViewController> controller;
  late WebViewController _webViewController;

  void initState() {
    // if (Platform) {
    //   WebView.platform = SurfaceAndroidWebView();
    // }
    getShopUrl();
    super.initState();
  }

  void getShopUrl() async {
    Config config = Config.fromJson(await SharedPref().read(kAppConfig));
    if (config != null && mounted)
      setState(() {
        shopUrl = config.defaultUrl ?? "";
      });
    final appArtist = context.read<AppArtist>();
    if (appArtist.selectedArtist?.shopUrl != null) {
      print("Shop url updated to ${appArtist.selectedArtist?.shopUrl}");
      setState(() {
        shopUrl = appArtist.selectedArtist!.shopUrl!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppArtist>(builder: (context, appArtist, child) {
      print("Here Shop url updated to ${appArtist.selectedArtist?.shopUrl}");
      if(appArtist.selectedArtist?.shopUrl != null) {
        shopUrl = appArtist.selectedArtist?.shopUrl ?? "";
        _webViewController.loadUrl(shopUrl);
      }
      return Scaffold(
        appBar: getAppBar(title),
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
          initialUrl: shopUrl,
        )));
    });
  }

  void reloadWebView() {
    _webViewController.loadUrl(shopUrl);
    _webViewController.reload();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
