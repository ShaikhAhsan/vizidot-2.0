import 'package:bmprogresshud/progresshud.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/elocker.dart';
import 'package:vizidot_flutter/models/live_stream.dart';
import 'package:vizidot_flutter/screens/broadcast_page.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String check = '';
  late SUser user = SUser(
      id: "",
      artistId: "",
      name: "",
      email: "",
      password: "",
      photo: "",
      fcmToken: "");
  late List<LiveStream> liveStreams;

  @override
  void initState() {
    liveStreams = [];
    fetchUsersLiveStreams();
    fetchUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar("Live Streams"),
        backgroundColor: kBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: Column(children: <Widget>[
          (user == null || user?.artistId?.length == 0)
              ? SizedBox(height: 0)
              : _buildStartLiveStreamButton(),
          liveStreams.length > 0
              ? Expanded(
                  child: ListView.builder(
                  itemBuilder: (context, position) {
                    var liveStream = liveStreams[position];
                    return InkWell(
                      onTap: () async {
                        print("Open Detail");
                        // await [Permission.camera, Permission.microphone]
                        //     .request();
                        print("User Added");
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BroadcastPage(
                              isBroadcaster: false,
                              liveStream: liveStream,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                        padding: const EdgeInsets.all(0),
                        width: 90,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(15),
                          ),
                          color: kBoxColor.withOpacity(0.1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              // color: kPrimaryColor, //kBoxColor.withOpacity(0.1),
                              margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                              height: MediaQuery.of(context).size.height * 0.3,
                              width: MediaQuery.of(context).size.width / 4,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                child: Stack(children: [
                                  CachedNetworkImage(
                                    imageUrl: liveStream.photo,
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                          //colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn)
                                        ),
                                      ),
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: Text(
                                      liveStream.name,
                                      maxLines: 2,
                                      style: kSectionMovieTitle,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.8,
                                    child: Text(
                                      liveStream.desc,
                                      maxLines: 5,
                                      style: kSectionMovieSubtitle.copyWith(
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: liveStreams.length,
                ))
              : Column(
                  children: [
                    SizedBox(height: 200),
                    Center(
                        child: Text(
                      'No Live stream available!\nLive streams will appear here. Please come back later.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: kPrimaryColor),
                      textAlign: TextAlign.center,
                    )),
                  ],
                ),
        ]));
  }

  Future<void> fetchUser() async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.id)
        .snapshots()
        .listen((querySnapShot) {
      SUser user = SUser.fromDocumentSnapshot(querySnapShot);
      if (mounted) {
        setState(() {
          this.user = user;
          print(user.name);
        });
      }
    });
  }

  Future<void> fetchUsersLiveStreams() async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    final CollectionReference _collectionElockerReference =
        FirebaseFirestore.instance.collection("Elocker");
    print(currentUser.id);
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
      print(artistIDS);
      if (artistIDS.length > 0) {
        await FirebaseFirestore.instance
            .collection("LiveStreams")
            .where("dateUpdated",
                isGreaterThan: DateTime.now().millisecondsSinceEpoch)
            .where("channel", whereIn: artistIDS)
            .snapshots()
            .listen((querySnapShot) {
          final allData = querySnapShot.docs
              .map((docSnapshot) => LiveStream.fromDocumentSnapshot(
                  docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
          if (mounted)
            setState(() {
              liveStreams = allData;
              print(allData);
              print("refersh");
            });
          print(allData.first.name);
        });
      }
    });
  }

  Widget _buildStartLiveStreamButton() {
    return Container(
      margin: EdgeInsets.all(15),
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(kButtonBgColor)),
        onPressed: () async {
          await [Permission.camera, Permission.microphone].request();
          ProgressHud.showLoading(text: "Starting...");
          var docSnapshot = await FirebaseFirestore.instance
              .collection("Artists")
              .doc(user.artistId)
              .get();
          if (docSnapshot.exists) {
            Artist artist = Artist.fromDocumentSnapshot(docSnapshot);
            LiveStream liveStream = LiveStream(
                name: artist.name ?? "",
                photo: artist.photo ?? "",
                desc: artist.desc ?? "",
                identifier: artist.id ?? "",
                dateAdded: DateTime.now().millisecondsSinceEpoch,
                channel: artist.id ?? "",
                dateUpdated: DateTime.now().millisecondsSinceEpoch + 30000);
            CollectionReference liveStreams =
                FirebaseFirestore.instance.collection('LiveStreams');
            liveStreams
                .add(liveStream.toMap())
                .then((value) async => {
                      sendPushToAritist(
                          artist.name,
                          artist.name +
                              " have started Live Stream, Please have a look.",
                          artist.id),
                      liveStream.identifier = value.id,
                      ProgressHud.dismiss(),
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BroadcastPage(
                            isBroadcaster: true,
                            liveStream: liveStream,
                          ),
                        ),
                      ),
                    })
                .catchError((error) => {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Failed to start Live Stream"))),
                      print("Failed to add user: $error")
                    });
          }
        },
        child: Text(
          'Start Live Stream',
          style: kButtonTextStyle,
        ),
      ),
    );
  }

  sendPushToAritist(String title, String message, String id) async {
    print(message);
    String url =
        "https://us-central1-vizidot-4b492.cloudfunctions.net/sendPushNotificationToArtist";
    Map<String, String> match = {
      'title': title,
      'message': message,
      'id': id,
    };

    Map<String, String> headers = {
      "Content-Type": "application/x-www-form-urlencoded"
    };

    http.post(Uri.parse(url), body: match, headers: headers).then((response) {
      print(response.body);
    });
  }
}
