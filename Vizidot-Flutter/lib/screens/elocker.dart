import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/config.dart';
import 'package:vizidot_flutter/models/elocker.dart';
import 'package:vizidot_flutter/screens/elocker_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';

class Elocker extends StatefulWidget {
  const Elocker({Key? key}) : super(key: key);

  @override
  State<Elocker> createState() => _ElockerState();
}

class _ElockerState extends State<Elocker> {
  late List<Artist> artists = [];
  String sponserIcon = '';
  StreamSubscription? _subscription;

  @override
  void initState() {
    artists = [];
    fetch();
    getSponserIcon();
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Future<void> fetch() async {
  //   final CollectionReference _collectionElockerReference =
  //       FirebaseFirestore.instance.collection("Elocker");
  //   SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
  //   await _collectionElockerReference
  //       .where("userId", isEqualTo: currentUser.id)
  //       .snapshots()
  //       .listen((event) async {
  //     final elockerData = event.docs
  //         .map((docSnapshot) => ElockerModel.fromDocumentSnapshot(
  //             docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
  //         .toList();
  //     var artistIDS = [];
  //     elockerData.forEach((element) {
  //       artistIDS.add(element.artistId);
  //     });
  //
  //     final CollectionReference _collectionReference =
  //         FirebaseFirestore.instance.collection("Artists");
  //     if (artistIDS.length > 0) {
  //       QuerySnapshot querySnapShot =
  //           await _collectionReference.where("id", whereIn: artistIDS).get();
  //       final allData = querySnapShot.docs
  //           .map((docSnapshot) => Artist.fromDocumentSnapshot(
  //               docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
  //           .toList();
  //       if (mounted)
  //         setState(() {
  //           artists = allData;
  //         });
  //     } else {
  //       setState(() {});
  //     }
  //   });
  // }

  Future<StreamSubscription> fetch() async {
    final CollectionReference _collectionElockerReference =
        FirebaseFirestore.instance.collection("Elocker");

    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));

    StreamSubscription subscription = _collectionElockerReference
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

      final CollectionReference _collectionReference =
          FirebaseFirestore.instance.collection("Artists");

      if (artistIDS.length > 0) {
        QuerySnapshot querySnapShot =
            await _collectionReference.where("id", whereIn: artistIDS).get();

        final allData = querySnapShot.docs
            .map((docSnapshot) => Artist.fromDocumentSnapshot(
                docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        if (mounted) {
          setState(() {
            artists = allData;
          });
        }
      } else {
        setState(() {artists = [];});
      }
    });

    return subscription;
  }

  void getSponserIcon() async {
    Config config = Config.fromJson(await SharedPref().read(kAppConfig));
    if (config != null && mounted)
      setState(() {
        sponserIcon = config.sponserIcon ?? "";
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
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
                artists.length > 0
                    ? Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, position) {
                            return ElockerItem(artist: artists[position]);
                          },
                          itemCount: artists.length,
                        ),
                      )
                    : Center(
                        child: Column(
                        children: [
                          SizedBox(height: 350),
                          Text(
                            'Your eLocker is empty\nPlease scan to add artists in your eLocker',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: kPrimaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )),
              ]),
        ),
        appBar: getAppBar("eLocker"));
  }
}
