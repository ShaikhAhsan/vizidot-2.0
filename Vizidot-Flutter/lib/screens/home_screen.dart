import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share/share.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/config.dart';
import 'package:vizidot_flutter/models/elocker.dart';
import 'package:vizidot_flutter/models/selected_artist.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:vizidot_flutter/widgets/home_screen/photos_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vizidot_flutter/widgets/home_screen/trending_list.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _current = 0;
  int selectedArtistIndex = 0;
  String _token = "";
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final PageController _pageController = PageController();
  String sponserIcon = '';
  late List<Artist> artists;

  @override
  void initState() {
    setupToken();
    getAppConfig();
    artists = [];
    fetch();
    super.initState();
  }

  Future<void> saveTokenToDatabase(String token) async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    final db = FirebaseFirestore.instance;
    const collectionName = "Elocker";
    final batch = db.batch();
    QuerySnapshot<Map<String, dynamic>> querySnapShot = await db
        .collection(collectionName)
        .where("userId", isEqualTo: currentUser.id)
        .get();
    final allData = querySnapShot.docs
        .map((docSnapshot) => Artist.fromDocumentSnapshot(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
    querySnapShot.docs.forEach((element) {
      batch.update(
          db.collection(collectionName).doc(element.id), {"fcmToken": token});
    });
    batch.update(
        db.collection('Users').doc(currentUser.id), {"fcmToken": token});
    batch.commit().then((_) {
      print("Updated");
    });
  }

  Future<void> getAppConfig() async {
    final CollectionReference _collectionElockerReference =
        FirebaseFirestore.instance.collection("Config");
    var configSnap = await _collectionElockerReference.doc("AppConfig").get();
    Config config = Config.fromDocumentSnapshot(
        configSnap as DocumentSnapshot<Map<String, dynamic>>);
    SharedPref().save(kAppConfig, config);
    if (config != null && mounted)
      setState(() {
        sponserIcon = config.sponserIcon ?? "";
      });
  }

  Future<void> setupToken() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    NotificationSettings setting =
        await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
// Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();
// Save the initial token to the database
    await saveTokenToDatabase(token!);
// Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }

  Future<void> fetch() async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    final CollectionReference _collectionElockerReference =
        FirebaseFirestore.instance.collection("Elocker");
    await _collectionElockerReference
        .where("userId", isEqualTo: currentUser.id)
        .snapshots()
        .listen((event) async {
      final elockerData = event.docs
          .map((docSnapshot) => ElockerModel.fromDocumentSnapshot(
              docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      var artistIDS = [];
      elockerData.forEach((element) {
        artistIDS.add(element.artistId);
      });
      if (artistIDS.length > 0) {
        final CollectionReference _collectionReference =
            FirebaseFirestore.instance.collection("Artists");
        QuerySnapshot querySnapShot =
            await _collectionReference.where("id", whereIn: artistIDS).get();
        final allData = querySnapShot.docs
            .map((docSnapshot) => Artist.fromDocumentSnapshot(
                docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        if (mounted)
          setState(() {
            artists = allData;
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBarWithRightButton("Home", context, false),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: artists.length > 0
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    (sponserIcon ?? "").length > 0
                        ? Container(
                            padding: EdgeInsets.all(5),
                            color: Colors.white,
                            height: 60,
                            child: CachedNetworkImage(
                              imageUrl: sponserIcon ?? "",
                            ))
                        : SizedBox(height: 0),
                    Container(
                      height: 350,
                      child: PageView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: artists.length,
                          onPageChanged: (index) {
                            print(index);
                            if (mounted)
                              setState(() {
                                selectedArtistIndex = index;
                                final appArtist = context.read<AppArtist>();
                                appArtist.selectedArtist = artists[index];
                              });
                          },
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                SizedBox(
                                  height: 250,
                                  width: double.infinity,
                                  child: CachedNetworkImage(
                                    imageUrl: artists[index].photo.toString(),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        artists[index].desc.toString(),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        style: kSpecial,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                60,
                                            child: Center(
                                              child: Text(
                                                artists[index].name.toString(),
                                                style: kMovieTitle,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          new IconButton(
                                            color: kPrimaryColor,
                                            iconSize: 20,
                                            onPressed: () async {
                                              Share.share(
                                                  'Hey there, Vizidot fan. Download my app',
                                                  subject: artists[index].name);
                                            },
                                            icon: const Icon(Icons.share),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
// ),
                            );
                          }),
                    ),
                    DefaultTabController(
                        length: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TabBar(
                                indicatorWeight: 2,
                                indicatorColor: kPrimaryColor,
                                labelColor: kPrimaryColor,
                                labelStyle: kButtonTextStyle,
                                unselectedLabelColor: kTabBarUnSelectedColor,
                                tabs: const [
                                  Tab(text: 'Audio Songs'),
                                  Tab(text: 'Videos')
                                ],
                                onTap: (index) {
                                  setState(() {
                                    _current = index;
                                  });
                                },
                              ),
                              Builder(builder: (_) {
                                if (_current == 0) {
                                  return PhotosList(
                                      photos: artists.length > 0
                                          ? artists[selectedArtistIndex].images
                                          : [],
                                      title: "Audio Songs",
                                      artist: artists[selectedArtistIndex]);
                                } else {
                                  return VideosList(
                                    videosList: artists.length > 0
                                        ? artists[selectedArtistIndex].videos
                                        : [],
                                    title: "Videos",
                                  );
                                }
                              }),
                            ])),
                  ],
                ),
              )
            : Center(
                child: Text(
                'Your eLocker is empty\nPlease scan to add artists in your eLocker',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: kPrimaryColor),
                textAlign: TextAlign.center,
              )),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
