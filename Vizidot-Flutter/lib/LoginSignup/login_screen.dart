import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/LoginSignup/forgotpassword_screen.dart';
import 'package:vizidot_flutter/LoginSignup/register_screen.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/screens/web_view_ios.dart';
import 'package:vizidot_flutter/screens/web_view_web.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import '../../widgets/bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bmprogresshud/bmprogresshud.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    // emailController.text = "a@a.com";
    // passwordController.text = "123456";
    super.initState();
  }

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
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(
                Icons.email,
                color: Colors.white,
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
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Enter your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordBtn() {
    return Container(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ButtonStyle(
            // padding: const EdgeInsets.only(right: 0.0),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(kPrimaryColor)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ForgotPasswordScreen(),
                fullscreenDialog: true),
          );
        },
        child: Text(
          'Forgot Password?',
          style: kLabelStyle,
        ),
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Container(
      height: 20.0,
      child: Row(
        children: <Widget>[
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white),
            child: Checkbox(
              value: _rememberMe,
              checkColor: kSecondaryColor,
              activeColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value!;
                });
              },
            ),
          ),
          Text(
            'Remember me',
            style: kLabelStyle,
          ),
        ],
      ),
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
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(kButtonBgColor)),
        onPressed: () async {
          try {
            ProgressHud.showLoading(text: "Signing in...");
            final credential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
                    email: kCurrentUserEmail, password: kCurrentUserPassword);

            if (emailController.text.isValidEmail() == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email is invalid!")));
              ProgressHud.dismiss();
              return;
            }
            final CollectionReference _collectionElockerReference =
                FirebaseFirestore.instance.collection("Users");
            QuerySnapshot querySnapShot = await _collectionElockerReference
                .where("email", isEqualTo: emailController.text)
                .where("password",
                    isEqualTo: encryptMyData(passwordController.text))
                .get();
            final allData = querySnapShot.docs
                .map((docSnapshot) => SUser.fromDocumentSnapshot(
                    docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
                .toList();
            ProgressHud.dismiss();
            if (allData.length > 0) {
              SUser currentUser = allData.first;
              SharedPref().save(kCurrentUser, currentUser);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Signed in successfully.")));
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MaterialApp(
                            debugShowCheckedModeBanner: false,
                            home: BottomBar(),
                          )));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Your email or password in incorrect please try again.")));
              ProgressHud.dismiss();
            }
          } on FirebaseAuthException catch (e) {
            ProgressHud.dismiss();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Your are not connected to internet.")));
          }
          // _collectionElockerReference
          // listen((event) async {
          //   final elockerData = event.docs
          //       .map((docSnapshot) => ElockerModel.fromDocumentSnapshot(
          //       docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
          //       .toList();
          //   var artistIDS = [];
          //   elockerData.forEach((element) {
          //     artistIDS.add(element.artistId);
          //   });

          // await FirebaseAuth.instance
          //     .signInWithEmailAndPassword(
          //         email: emailController.text,
          //         password: passwordController.text)
          //     .then((value) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text("Signed in successfully.")));
          //   ProgressHud.dismiss();
          //   Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //           builder: (context) => const MaterialApp(
          //                 debugShowCheckedModeBanner: false,
          //                 home: BottomBar(),
          //               )));
          // }).catchError((e) {
          //   var errorMessage = e.toString();
          //   if (e != null) {
          //     if (e.code == 'user-not-found') {
          //       errorMessage = 'No user found for that email.';
          //     } else if (e.code == 'wrong-password') {
          //       errorMessage = 'Wrong password provided for that user.';
          //     } else if (e.code == 'weak-password') {
          //       errorMessage = 'The password is too weak.';
          //     } else if (e.code == 'email-already-in-use') {
          //       errorMessage = 'The account already exists for that email.';
          //     } else if (e.code == 'invalid-email') {
          //       errorMessage = 'The email address is not valid';
          //     }
          //   }
          //   ScaffoldMessenger.of(context)
          //       .showSnackBar(SnackBar(content: Text(errorMessage)));
          //   ProgressHud.dismiss();
          // });
        },
        child: Text(
          'LOGIN',
          style: kButtonTextStyle,
        ),
      ),
    );
  }

  Widget _buildSignInWithText() {
    return Row(
      children: <Widget>[
        const Text(
          '- OR -',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          "Don't have an account?",
          style: kLabelStyle,
        ),
      ],
    );
  }

  Widget _buildSocialBtn(Function onTap, AssetImage logo) {
    return GestureDetector(
      onTap: () => print('Social Button Pressed'),
      child: Container(
        height: 60.0,
        width: 60.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 6.0,
            ),
          ],
          image: DecorationImage(
            image: logo,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupBtn() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RegisterScreen(), fullscreenDialog: true),
        );
      },
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Don\'t have an Account? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _builPPAndTCBtn() {
    return RichText(
      textAlign: TextAlign.center,
      text:  TextSpan(
        children: [
          TextSpan(
            text: "By clicking LOGIN button I agree to ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),

          TextSpan(
            text: 'Terms & Condition',
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
            recognizer:  TapGestureRecognizer()
            ..onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => kIsWeb ? WebScreen(url: kTermsConditionUrl, title: kTermsConditionTitle) : WebScreeniOS(url: kTermsConditionUrl, title: kTermsConditionTitle),
                    fullscreenDialog: true),
              );
            },
          ),
          TextSpan(
            text: " and ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
            recognizer:  TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => kIsWeb ? WebScreen(url: kPrivacyPolicyUrl, title: kPrivacyPolicyTitle) : WebScreeniOS(url: kPrivacyPolicyUrl, title: kPrivacyPolicyTitle),
                      fullscreenDialog: true),
                );
              },
          )
        ],
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
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 50.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(image: AssetImage("assets/logo.png"), height: 150),
                      Text(
                        'Sign In',
                        style: kScreenHeadingTextStyle,
                      ),
                      SizedBox(height: 30.0),
                      _buildEmailTF(),
                      const SizedBox(height: 30.0),
                      _buildPasswordTF(),
                      SizedBox(height: 20.0),
                      _buildForgotPasswordBtn(),
                      const SizedBox(height: 40.0),
                      // _buildRememberMeCheckbox(),
                      const SizedBox(height: 20.0),
                      _buildLoginBtn(),
                      // const SizedBox(height: 25.0),
                      _builPPAndTCBtn(),
                      const SizedBox(height: 25.0),
                      _buildSignupBtn(),
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
