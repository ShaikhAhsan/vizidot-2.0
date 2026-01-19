import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/LoginSignup/login_screen.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/screens/AddArtistController.dart';
import 'package:vizidot_flutter/screens/edit_profile.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import 'package:vizidot_flutter/widgets/base_alert_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var emailText =
      TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
  var fullNameText = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName);
  String artistId = "";

  @override
  void initState() {
    fetch();
    super.initState();
  }

  Future<void> fetch() async {
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    print(currentUser.id);
    FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.id)
        .snapshots()
        .listen((querySnapShot) {
      print("Response");

      print(querySnapShot.data());
      SUser user = SUser.fromDocumentSnapshot(querySnapShot);
      if (mounted) {
        setState(() {
          SharedPref().save(kCurrentUser, user);
        });
      }
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    updateFields();
  }

  Future<void> updateFields() async {
    print("Set State updateFields");
    SUser currentUser = SUser.fromJson(await SharedPref().read(kCurrentUser));
    emailText.text = currentUser.email ?? "";
    fullNameText.text = currentUser.name ?? "";
    artistId = currentUser.artistId ?? "";
  }

  Widget _buildFullNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Full Name',
          style: kLabelProfileScreenStyle,
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationProfileStyle,
          height: 60.0,
          child: TextField(
            enabled: false,
            controller: fullNameText,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: kPrimaryColor,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: kPrimaryColor,
              ),
              hintText: 'Enter your Full Name',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Email',
          style: kLabelProfileScreenStyle,
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationProfileStyle,
          height: 60.0,
          child: TextField(
            controller: emailText,
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: kPrimaryColor,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: kPrimaryColor,
              ),
              hintText: '',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
                TextStyle(color: Colors.red)),
            backgroundColor: MaterialStateProperty.all<Color>(kButtonBgColor)),
        onPressed: () async {
          audioHandler.updateQueue([]);
          audioHandler.stop();
          SharedPref().save(kCurrentUser, null);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreen(), fullscreenDialog: true));
        },
        child: Text(
          'Logout',
          style: kButtonTextStyle,
        ),
      ),
    );
  }

  Widget _buildDeleteBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          audioHandler.updateQueue([]);
          audioHandler.stop();
          var dialog = CustomAlertDialog(
            title: "Delete Account",
            message:
                "Are you sure you want to Delete your account? All the data linked to your account will be deleted.",
            onPostivePressed: () async {
              SUser user =
                  SUser.fromJson(await SharedPref().read(kCurrentUser));
              final db = FirebaseFirestore.instance;
              db.collection("Users").doc(user.id).delete().then((value) => {
                    SharedPref().save(kCurrentUser, null),
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                            fullscreenDialog: true)),
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account Deleted successfully!'),
                      ),
                    )
                  });
            },
            positiveBtnText: 'Delete',
            negativeBtnText: 'Cancel',
            onNegativePressed: () {},
          );
          showDialog(
              context: context, builder: (BuildContext context) => dialog);
        },
        child: Text(
          'Delete Account',
          style: TextStyle(
            color: kDeleteButtonTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildElockerBtn() {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        width: double.infinity,
        child: ElevatedButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: EdgeInsets.symmetric(
              horizontal: defaultPadding * 1.5,
              vertical: defaultPadding,
            ),
          ),
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddArtistController(artistId),
                    fullscreenDialog: true));
          },
          icon: Icon(Icons.login),
          label: Text("Manage My eLocker"),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
          title: Text("Profile"),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0, top: 20),
                child: GestureDetector(
                  onTap: () async {
                    String refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfile(),
                            fullscreenDialog: true));
                    if (refresh == 'refresh') {
                      updateFields();
                      if (mounted) setState(() {});
                    }
                  },
                  child: Text("Edit",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold)),
                ))
          ]),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              // backgroundContainer,
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: artistId.isEmpty == false ? 40.0 : 0),
                      artistId.isEmpty == false
                          ? _buildElockerBtn()
                          : SizedBox(height: 0),
                      SizedBox(height: 30.0),
                      _buildFullNameTF(),
                      SizedBox(height: 30.0),
                      _buildEmailTF(),
                      const SizedBox(height: 40.0),
                      _buildLoginBtn(),
                      const SizedBox(height: 50.0),
                      _buildDeleteBtn(),
                      const SizedBox(height: 40.0),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
