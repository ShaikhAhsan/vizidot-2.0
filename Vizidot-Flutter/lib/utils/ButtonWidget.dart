import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          backgroundColor: MaterialStateProperty.all(kPrimaryColor),
          padding: MaterialStateProperty.all(
              EdgeInsets.symmetric(horizontal: 32, vertical: 0)),
        ),
        child: Text(text),
        onPressed: onClicked,
      );
}
