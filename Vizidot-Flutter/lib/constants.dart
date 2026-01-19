// import 'dart:html' as dartHtml;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:vizidot_flutter/main.dart';
import 'package:vizidot_flutter/screens/audio_player.dart';
import 'package:vizidot_flutter/screens/profile.dart';
import '../screens/edit_profile.dart';
import 'package:encrypt/encrypt.dart' as ENC;
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;


void playVideo(String atUrl) {
  audioHandler.updateQueue([]);
  audioHandler.stop();
  if(kIsWeb) {
    final v = html.window.document.getElementById('videoPlayer');
    if(v != null) {
      v.setInnerHtml(
          '<source type="video/mp4" src="$atUrl">',
          validator: html.NodeValidatorBuilder()
            ..allowElement('source', attributes: ['src', 'type']));
      final a = html.window.document.getElementById( 'triggerVideoPlayer' );
      if(a != null) {
        a.dispatchEvent(html.MouseEvent('click'));
      }
    }
  } else {
    // we're not on the web platform
    // and should use the video_player package
  }
}

late AudioPlayerHandler audioHandler;

Color kBackgroundColor = const Color(0xff000000);
Color kTextColor = const Color(0xffffffff);
Color kAccentColor = const Color(0xff231f1f);
Color kShadeColor = const Color(0xff969696);
Color kSoftShadeColor = const Color(0xffe7e7e7);
Color kBoxColor = const Color(0xFFC4C4C4);
Color kPrimaryColor = Color(0xFFFCB518);
Color kSecondaryColor = Color(0xFFFF6701);
Color kTabBarUnSelectedColor = const Color(0xFFDBDADB);
Color kTextTitleColor = const Color(0x01000000);
Color kErrorColor = const Color(0x01C42D19);
Color kButtonBackgroundColor = Colors.white;
Color kButtonProfileBackgroundColor = kPrimaryColor;
Color kButtonBgColor = Color(0xFFFCB518);
Color kButtonTextColor = Colors.white;
String kCurrentUser = "currentUser";
String kCurrentArtist = "currentArtist";
String kAppConfig = "appConfig";
const defaultPadding = 16.0;
Color kDeleteButtonTextColor = Colors.red;

String kTermsConditionUrl = "http://vizidots.com/terms-and-conditions/";
String kTermsConditionTitle = "Terms and Condition";
String kPrivacyPolicyUrl = "http://vizidots.com/privacy_policy/";
String kPrivacyPolicyTitle = "Privacy Policy";

String kCurrentUserEmail = "vizidot@app.com";
String kCurrentUserPassword = "vizidot!)(*";

final kHeaderTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    fontFamily: 'Nexa',
    color: kTextColor);

final kHeaderSubtitle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  fontFamily: 'Poppins',
  color: kTextColor,
);

final kSearchHint = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  fontFamily: 'Poppins',
  color: kShadeColor,
);
final kSectionTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
  color: kTextColor,
);
// special for you
final kCategoryTitle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  fontFamily: 'Poppins',
  color: kTextColor,
);
final kMovieTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    fontFamily: 'Nexa',
    color: kTextColor);
final kMovieTags = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
  color: kTextColor,
);
// movie rating with black color
final kMovieRating = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
  fontFamily: 'Poppins',
  color: kTextColor,
);
TextStyle kMovieGenre = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  fontFamily: 'Poppins',
  color: kTextColor,
);
TextStyle kMovieWatch = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
  color: kTextColor,
);
TextStyle kSpecial = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
  color: kTextColor,
);

final kSectionMovieTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  fontFamily: 'Nexa',
  color: kPrimaryColor,
);

final kSectionMovieSubtitle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w400,
  fontFamily: 'Poppins',
  color: kSoftShadeColor,
);

final kErrorText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  fontFamily: 'Nexa',
  color: kPrimaryColor,
);

final kTitleLabelStyle =
    TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: kTextColor);

TextStyle kHintTextStyle = TextStyle(
  color: Colors.white54,
  fontFamily: "OpenSans",
);

final kLabelStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kBoxDecorationStyle = BoxDecoration(
  color: Color(0xFFfcb518),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

final backgroundContainer = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFfcb518),
        Color.fromARGB(255, 219, 159, 28),
        Color.fromARGB(255, 202, 145, 23),
        Color.fromARGB(255, 168, 127, 38),
      ],
      stops: [0.1, 0.4, 0.7, 0.9],
    ),
  ),
);

final kScreenHeadingTextStyle = TextStyle(
  color: Colors.white,
  fontFamily: 'OpenSans',
  fontSize: 30.0,
  fontWeight: FontWeight.bold,
);

final kButtonTextStyle = TextStyle(
  color: kButtonTextColor,
  letterSpacing: 1.2,
  fontSize: 17.0,
  fontWeight: FontWeight.w700,
  fontFamily: 'OpenSans',
);

final kDeleteButtonTextStyle = TextStyle(
  color: kDeleteButtonTextColor,
  letterSpacing: 1.2,
  fontSize: 17.0,
  fontWeight: FontWeight.w500,
  fontFamily: 'OpenSans',
);

AppBar getAppBarWithBackButton(String title, BuildContext context) {
  final kAppBar = AppBar(
    backgroundColor: kPrimaryColor,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
    title: Text(title),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    ),
  );
  return kAppBar;
}

AppBar getAppBarWithRightButton(
    String title, BuildContext context, bool isEditProfile) {
  final kAppBar = AppBar(
      backgroundColor: kPrimaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
      title: Text(title),
      actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: isEditProfile ? 20.0 : 20.0, top: isEditProfile ? 20 : 0),
            child: GestureDetector(
              onTap: () {
                if (isEditProfile) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfile(),
                          fullscreenDialog: true));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                          fullscreenDialog: true));
                }
              },
              child: isEditProfile
                  ? Text("Edit",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold))
                  : const Icon(Icons.person),
            ))
      ]);
  return kAppBar;
}

AppBar getAppBar(String title) {
  final kAppBar = AppBar(
    backgroundColor: kPrimaryColor,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
    title: Text(title),
  );
  return kAppBar;
}

final kBoxDecorationProfileStyle = BoxDecoration(
  color: Color.fromARGB(255, 52, 51, 50),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(
      color: Color.fromARGB(31, 11, 0, 0),
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

final kLabelProfileScreenStyle = TextStyle(
  color: kPrimaryColor,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kButtonProfileTextStyle = TextStyle(
  color: Colors.white,
  letterSpacing: 1.5,
  fontSize: 18.0,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kButtonLogoutStyle = TextStyle(
  color: Colors.white,
  letterSpacing: 1,
  fontSize: 18.0,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

String getFileName(String url) {
  const examplePath = '/my-secret/some-path/abcxyz/my-book.pdf';

  final File _file = File(url) as File;
  final _filename = basename(_file.path);
  final _extension = extension(_file.path);
  final _nameWithoutExtension = basenameWithoutExtension(_file.path);
  // print('Filename: $_filename');
  // print('Filename without extension: $_nameWithoutExtension');
  // print('Extension: $_extension');
  return _nameWithoutExtension.replaceAll("uploads%2F", "");
}

final key = ENC.Key.fromUtf8('put32charactershereeeeeeeeeeeee!'); //32 chars
final iv = ENC.IV.fromUtf8('put16characters!'); //16 chars

//encrypt
String encryptMyData(String text) {
  final e = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted_data = e.encrypt(text, iv: iv);
  return encrypted_data.base64;
}

//dycrypt
String decryptMyData(String text) {
  final e = Encrypter(AES(key, mode: AESMode.cbc));
  final decrypted_data = e.decrypt(Encrypted.fromBase64(text), iv: iv);
  return decrypted_data;
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

