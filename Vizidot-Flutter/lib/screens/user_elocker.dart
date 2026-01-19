import 'package:bmprogresshud/progresshud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/models/elocker.dart';
import 'package:vizidot_flutter/screens/elocker.dart';
import 'package:vizidot_flutter/screens/user_elocker_item.dart';
import 'package:vizidot_flutter/utils/ButtonWidget.dart';

class UsersElockerScreen extends StatefulWidget {
  SUser user;

  UsersElockerScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UsersElockerScreenState createState() => _UsersElockerScreenState();
}

class _UsersElockerScreenState extends State<UsersElockerScreen> {
  late List<Artist> artists = [];
  Artist? selectedValue;
  int showAddOption = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "User Elocker",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                showAddOption == 0
                    ? ElevatedButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding,
                          ),
                        ),
                        onPressed: () {
                          if (mounted)
                            setState(() {
                              showAddOption = 1;
                            });
                        },
                        icon: Icon(Icons.add),
                        label: Text("Add New"),
                      )
                    : SizedBox(width: 0),
              ],
            ),
            SizedBox(height: 30),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("Elocker")
                      .where("userId", isEqualTo: widget.user?.id)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return new Text('Loading...');
                    return new ListView(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        children: snapshot.data!.docs.map((docSnapshot) {
                          ElockerModel elocker = ElockerModel.fromDocumentSnapshot(
                              docSnapshot
                                  as DocumentSnapshot<Map<String, dynamic>>);
                          return UserElockerItem(elocker: elocker);
                        }).toList());
                  }),
            ),
          ])),
    );
  }
}
