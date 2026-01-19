import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Email',
          style: kLabelStyle,
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(Icons.email, color: Colors.white),
              hintText: 'Enter your Email',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendBtn() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 25.0),
        width: double.infinity,
        // ignore: deprecated_member_use
        child: ElevatedButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              backgroundColor:
                  MaterialStateProperty.all<Color>(kButtonBgColor)),
          onPressed: () async {
            ProgressHud.showLoading(text: "Sending Password reset email...");
            ProgressHud.showLoading(text: "Signing in...");
            final CollectionReference _collectionElockerReference =
                FirebaseFirestore.instance.collection("Users");
            QuerySnapshot querySnapShot = await _collectionElockerReference
                .where("email", isEqualTo: emailController.text)
                .get();
            final allData = querySnapShot.docs
                .map((docSnapshot) => SUser.fromDocumentSnapshot(
                    docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
                .toList();
            ProgressHud.dismiss();
            if (allData.length > 0) {
              SUser currentUser = allData.first;
              print(currentUser.password);
              String password = "";
              try {
                password = decryptMyData(currentUser.password ?? "");
              } catch (e) {}
              print(password);
              String url =
                  "https://us-central1-vizidot-4b492.cloudfunctions.net/sendEmail";
              Map<String, String> match = {
                'email': currentUser.email,
                'password': password
              };
              Map<String, String> headers = {
                "Content-Type": "application/x-www-form-urlencoded"
              };

              http
                  .post(Uri.parse(url), body: match, headers: headers)
                  .then((response) {
                if (response.body == 'Sent!') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Password reset email sent.")));
                }
                print(response.body);
              });
            }
          },
          child: Text(
            'Send',
            style: kButtonTextStyle,
          ),
        ));
  }

  Widget _builText() {
    return const Text(
      "If you forgot your password please enter your email, We will send you reset password link to your email.",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _builSignIn() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: "Click here to ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              backgroundContainer,
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 50.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Image(
                          image: AssetImage("assets/logo.png"), height: 150),
                      Text('Forgot Password', style: kScreenHeadingTextStyle),
                      const SizedBox(height: 30.0),
                      _builText(),
                      const SizedBox(height: 30.0),
                      _buildEmailTF(),
                      const SizedBox(height: 15.0),
                      _buildSendBtn(),
                      const SizedBox(height: 15.0),
                      _builSignIn()
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
