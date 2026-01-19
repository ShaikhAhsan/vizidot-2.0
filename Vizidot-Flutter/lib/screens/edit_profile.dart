import 'package:bmprogresshud/progresshud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/LoginSignup/forgotpassword_screen.dart';
import 'package:vizidot_flutter/LoginSignup/register_screen.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  var emailText =
      TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
  var fullNameText = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName);
  SUser? currentuser;

  @override
  void initState() {
    updateFields();
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  Future<void> updateFields() async {
    SUser user = SUser.fromJson(await SharedPref().read(kCurrentUser));
    emailText.text = user.email ?? "";
    fullNameText.text = user.name ?? "";
    currentuser = user;
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
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: kPrimaryColor, fontFamily: 'OpenSans'),
            enabled: false,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: kPrimaryColor,
              ),
              hintText: 'Enter your Email',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Password',
          style: kLabelProfileScreenStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            obscureText: true,
            style: TextStyle(
              color: kPrimaryColor,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: kPrimaryColor,
              ),
              hintText: 'Enter your Password',
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
        onPressed: () async {
          // await FirebaseAuth.instance.currentUser?.updateDisplayName(fullNameText.text.toString());
          String? token = await FirebaseMessaging.instance.getToken();
          currentuser?.fcmToken = token;
          currentuser?.name = fullNameText.text;
          ProgressHud.showLoading();
          final db = FirebaseFirestore.instance;
          db
              .collection("Users")
              .doc(currentuser?.id.toString())
              .update(currentuser!.toJson())
              .then((value) {
            Fluttertoast.showToast(msg: 'Updated Successfully!');
            SharedPref().save(kCurrentUser, currentuser);
            ProgressHud.dismiss();
            Navigator.pop(context, 'refresh');
          });
        },
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(kButtonBgColor)),
        child: Text(
          'Save',
          style: kButtonTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar("Profile"),
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
                      SizedBox(height: 30.0),
                      _buildFullNameTF(),
                      SizedBox(height: 30.0),
                      _buildEmailTF(),
                      const SizedBox(height: 40.0),
                      _buildLoginBtn(),
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
