import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:vizidot_flutter/screens/shop_screen_ios.dart';
import '../../constants.dart';
import '../../screens/profile.dart';
import '../../screens/home_screen.dart';
import '../../screens/elocker.dart';
import '../../screens/shopscreen.dart';
import '../../screens/scan_image.dart';
import '../../screens/liveStreamHome.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _selectedIndex = 0;
  List<Widget> screen = [];
  List<BottomNavigationBarItem> items = [];

  @override
  void initState() {
    screen.add(HomeScreen());
    screen.add(Elocker());
    if (kIsWeb == false) {
      screen.add(ImageDetectionPage(changePage: _onItemTapped));
    }
    print(kIsWeb ? "it's web view" : "it's not web view");
    screen.add(kIsWeb ? ShopScreen() : ShopScreeniOS());
    screen.add(MyHomePage());
    items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.home, color: Colors.white),
        activeIcon: Icon(Icons.home, color: kPrimaryColor),
        label: 'Home'));
    items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.library_music, color: Colors.white),
        activeIcon: Icon(Icons.library_music, color: kPrimaryColor),
        label: 'eLocker'));
    if (kIsWeb == false) {
      items.add(BottomNavigationBarItem(
          icon: Image(image: AssetImage('assets/transparent.png')),
          activeIcon: Image(image: AssetImage('assets/transparent.png')),
          label: 'Scan'));
    }
    items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.shop_rounded, color: Colors.white),
        activeIcon: Icon(Icons.shop_rounded, color: kPrimaryColor),
        label: 'Shop'));
    items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.ondemand_video_sharp, color: Colors.white),
        activeIcon: Icon(Icons.person, color: kPrimaryColor),
        label: 'Live Stream'));

    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screen,
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      extendBody: true,
      floatingActionButton: kIsWeb == true
          ? null
          : FloatingActionButton(
        child: const Icon(Icons.camera_alt_outlined),
        backgroundColor: kPrimaryColor,
        onPressed: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0.0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kBackgroundColor.withOpacity(1.0),
        items: items,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        unselectedItemColor: Colors.white,
        selectedItemColor: kPrimaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        enableFeedback: false,
        onTap: _onItemTapped,
        currentIndex: _selectedIndex,
      ),
    );
  }
}
