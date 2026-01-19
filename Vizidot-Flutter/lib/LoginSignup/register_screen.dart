import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/screens/web_view_ios.dart';
import 'package:vizidot_flutter/screens/web_view_web.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import '../widgets/bottom_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Widget _buildNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Full Name',
          style: kLabelStyle,
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: nameController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(
                Icons.person,
                color: Colors.white,
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
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(
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

  Widget _buildConfirmPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Confirm Password',
          style: kLabelStyle,
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: confirmPasswordController,
            obscureText: true,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: const Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Re enter your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
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
            ProgressHud.showLoading();
            final credential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
                    email: kCurrentUserEmail, password: kCurrentUserPassword);
            if (nameController.text.length == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your name.")));
              return;
            }
            if (emailController.text.isValidEmail() == false) {
              ProgressHud.dismiss();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email is invalid!")));
              return;
            }
            if (passwordController.text.length == 0 ||
                passwordController.text.toString() !=
                    confirmPasswordController.text.toString()) {
              ProgressHud.dismiss();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text("Password and Confirm Password are not matching.")));
              return;
            }
            final CollectionReference _collectionElockerReference =
                FirebaseFirestore.instance.collection("Users");
            QuerySnapshot querySnapShot = await _collectionElockerReference
                .where("email", isEqualTo: emailController.text)
                .get();
            final allData = await querySnapShot.docs
                .map((docSnapshot) => SUser.fromDocumentSnapshot(
                    docSnapshot as DocumentSnapshot<Map<String, dynamic>>))
                .toList();
            ProgressHud.dismiss();
            if (allData.length > 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text("Email already exist. Please use diffrent email.")));
              return;
            }
            SUser user = SUser(
                id: "",
                artistId: "",
                name: nameController.text,
                email: emailController.text,
                password: encryptMyData(passwordController.text),
                photo: "",
                fcmToken: null);
            final db = FirebaseFirestore.instance;
            db
                .collection("Users")
                .add(user.toJson())
                .then((DocumentReference doc) {
              user.id = doc.id;
              db
                  .collection("Users")
                  .doc(user.id.toString())
                  .update(user.toJson())
                  .then((value) {
                ProgressHud.showSuccessAndDismiss(text: "Account created.");
                SharedPref().save(kCurrentUser, user);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MaterialApp(
                              debugShowCheckedModeBanner: false,
                              home: BottomBar(),
                            )));
              });
            });
          } on FirebaseAuthException catch (e) {
            ProgressHud.dismiss();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Your are not connected to internet.")));
          }
          // try {
          //   final credential =
          //       await FirebaseAuth.instance.createUserWithEmailAndPassword(
          //     email: emailController.text,
          //     password: passwordController.text,
          //   );
          //   await FirebaseAuth.instance.currentUser?.updateDisplayName(nameController.text.toString());
          //   final user = <String, dynamic>{
          //     "name": nameController.text.toString(),
          //     "email": emailController.text.toString(),
          //     "userId": FirebaseAuth.instance.currentUser!.uid.toString()
          //   };
          //   FirebaseFirestore.instance
          //       .collection("users")
          //       .add(user)
          //       .then((DocumentReference doc) =>
          //           print('DocumentSnapshot added with ID: ${doc.id}'));
          //   ProgressHud.showSuccessAndDismiss(text: "Account created.");
          //   Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //           builder: (context) => const MaterialApp(
          //                 debugShowCheckedModeBanner: false,
          //                 home: BottomBar(),
          //               )));
          // } on FirebaseAuthException catch (e) {
          //   var errorMessage = e.toString();
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
          //     ScaffoldMessenger.of(context)
          //         .showSnackBar(SnackBar(content: Text(errorMessage)));
          //   ProgressHud.dismiss();
          // } catch (e) {
          //   ScaffoldMessenger.of(context)
          //       .showSnackBar(SnackBar(content: Text(e.toString())));
          //   ProgressHud.dismiss();
          // }
        },
        child: Text(
          'Register',
          style: kButtonTextStyle,
        ),
      ),
    );
  }

  Widget _builPPAndTCBtn() {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: "By clicking Register button I agree to ",
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
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => kIsWeb ? WebScreen(
                          url: kTermsConditionUrl, title: kTermsConditionTitle) : WebScreeniOS(
                          url: kTermsConditionUrl, title: kTermsConditionTitle),
                      fullscreenDialog: true),
                );
              },
          ),
          const TextSpan(
            text: " and ",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => kIsWeb ? WebScreen(
                          url: kPrivacyPolicyUrl, title: kPrivacyPolicyTitle) : WebScreeniOS(
                      url: kPrivacyPolicyUrl, title: kPrivacyPolicyTitle),
                      fullscreenDialog: true),
                );
              },
          )
        ],
      ),
    );
  }

  Widget _buildSigninBtn() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: RichText(
        text: const TextSpan(
          children: [
            const TextSpan(
              text: 'Already have an Account? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign In',
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
                      Text('Sign Up', style: kScreenHeadingTextStyle),
                      const SizedBox(height: 12.0),
                      _buildNameTF(),
                      const SizedBox(height: 12.0),
                      _buildEmailTF(),
                      const SizedBox(height: 12.0),
                      _buildPasswordTF(),
                      const SizedBox(height: 12.0),
                      _buildConfirmPasswordTF(),
                      const SizedBox(height: 12.0),
                      _builPPAndTCBtn(),
                      _buildRegisterBtn(),
                      _buildSigninBtn(),
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
