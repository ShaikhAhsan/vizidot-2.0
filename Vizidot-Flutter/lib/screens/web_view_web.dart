import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/config.dart';
import 'package:vizidot_flutter/models/selected_artist.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:webviewx/webviewx.dart';
import 'package:provider/provider.dart';

class WebScreen extends StatefulWidget {
  String url;
  String title;

  WebScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  int pos = 1;
  late WebViewXController webviewController;

  @override
  void initState() {
    super.initState();
    getShopUrl();
  }

  void getShopUrl() async {
    await Permission.camera.request();
    Config config = Config.fromJson(await SharedPref().read(kAppConfig));
    if (config != null && mounted) {
      setState(() {
        widget.url = config.defaultUrl ?? "";
      });
    }
    webviewController.loadContent(widget.url, SourceType.url);
  }
  Size get screenSize => MediaQuery.of(context as BuildContext).size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(widget.title),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: WebViewX(
          key: const ValueKey('webviewx'),
          initialContent: widget.url,
          javascriptMode: JavascriptMode.unrestricted,
          initialSourceType: SourceType.url,
          height: screenSize.height,
          width: screenSize.width,
          onWebViewCreated: (controller) => webviewController = controller,
          onPageStarted: (src) => debugPrint('A new page has started loading: $src\n'),
          onPageFinished: (src) => debugPrint('The page has finished loading: $src\n'),
          jsContent: const {
            EmbeddedJsContent(
              js: "function testPlatformIndependentMethod() { console.log('Hi from JS') }",
            ),
            EmbeddedJsContent(
              webJs: "function testPlatformSpecificMethod(msg) { TestDartCallback('Web callback says: ' + msg) }",
              mobileJs: "function testPlatformSpecificMethod(msg) { TestDartCallback.postMessage('Mobile callback says: ' + msg) }",
            ),
          },
          dartCallBacks: {
            DartCallback(
              name: 'TestDartCallback',
              callBack: (msg) {
                print(msg.toString());
              },
            )
          },
          webSpecificParams: const WebSpecificParams(
            printDebugInfo: true,
          ),
          mobileSpecificParams: const MobileSpecificParams(
            androidEnableHybridComposition: true,
          ),
          navigationDelegate: (navigation) {
            debugPrint(navigation.content.sourceType.toString());
            return NavigationDecision.navigate;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }
}