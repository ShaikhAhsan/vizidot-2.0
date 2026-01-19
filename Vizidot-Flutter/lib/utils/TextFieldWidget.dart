import 'package:flutter/material.dart';
import 'package:vizidot_flutter/constants.dart';

class TextFieldWidget extends StatefulWidget {
  final int maxLines;
  final String label;
  final String text;
  final ValueChanged<String> onChanged;

  const TextFieldWidget({
    Key? key,
    this.maxLines = 1,
    required this.label,
    required this.text,
    required this.onChanged,
  }) : super(key: key);

  @override
  _TextFieldWidgetState createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kPrimaryColor),
          ),
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.centerLeft,
            decoration: kBoxDecorationProfileStyle,
            height: 60.0,
            child: TextField(
              minLines: 1,
              controller: controller,
              style: TextStyle(
                color: kPrimaryColor,
                fontFamily: 'OpenSans',
              ),
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                // border: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(14),
                // ),
              ),
              maxLines: widget.maxLines,
            ),
          ),
        ],
      );
}
