import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class CustomAlertDialog extends StatelessWidget {
  final Color bgColor;
  final String title;
  final String message;
  final String? positiveBtnText;
  final String? negativeBtnText;
  final Function onPostivePressed;
  final Function onNegativePressed;
  final double circularBorderRadius;

  CustomAlertDialog({
    required this.title,
    required this.message,
    this.circularBorderRadius = 15.0,
    this.bgColor = Colors.white,
    required this.positiveBtnText,
    required this.negativeBtnText,
    required this.onPostivePressed,
    required this.onNegativePressed,
  })  : assert(bgColor != null),
        assert(circularBorderRadius != null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title != null ? Text(title, style: kDeleteButtonTextStyle) : null,
      content: message != null ? Text(message, style: TextStyle(
          color: Colors.black
      )) : null,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(circularBorderRadius)),
      actions: <Widget>[
        positiveBtnText != null
            ? TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onNegativePressed != null) {
                    onNegativePressed();
                  }
                },
                child: Text(
                  negativeBtnText ?? "Cancel",
                  style: TextStyle(
                      color: Colors.black
                  ),
                ),
              )
            : SizedBox(height: 0),
        positiveBtnText != null
            ? TextButton(
                child: Text(
                  positiveBtnText ?? "yes",
                  style: TextStyle(
                    color: kDeleteButtonTextColor
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPostivePressed != null) {
                    onPostivePressed();
                  }
                },
              )
            : SizedBox(height: 0),
      ],
    );
  }
}
