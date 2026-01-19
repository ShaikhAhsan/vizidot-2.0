import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/widgets/home_screen/special_item.dart';

class SpecialList extends StatelessWidget {
  int current;
  final List<Artist> artists;
  final CarouselController carouselController;

  SpecialList(
      {Key? key,
      required this.current,
      required this.artists,
      required this.carouselController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpecialItem(
      current: current,
      artists: artists,
      carouselController: carouselController,
    );
  }
}
