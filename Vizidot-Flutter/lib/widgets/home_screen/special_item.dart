// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/artists.dart';

class SpecialItem extends StatefulWidget {
  int current;
  final List<Artist> artists;
  final CarouselController carouselController;

  SpecialItem({
    Key? key,
    required this.current,
    required this.artists,
    required this.carouselController,
  }) : super(key: key);

  @override
  _SpecialItemState createState() => _SpecialItemState();
}

class _SpecialItemState extends State<SpecialItem> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.4,
          aspectRatio: 16 / 9,
          viewportFraction: 1,
          enlargeCenterPage: true,
          autoPlay: true,
          onPageChanged: (index, reason) {
            setState(() {
              widget.current = index;
            });
          },
        ),
        carouselController: widget.carouselController,
        items: [
          ...widget.artists.map(
            (item) => GestureDetector(
              onTap: () {
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => DetailScreen(
                //       cover: posterUrl + item.posterPath.toString(),
                //       title: item.title.toString(),
                //       rating: item.voteAverage.toString(),
                //       date: item.releaseDate.toString(),
                //       overview: item.overview.toString(),
                //       adult: item.adult!,
                //       id: item.id!.toInt(),
                //     ),
                //   ),
                // );
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.width,
                    child: CachedNetworkImage(
                      imageUrl: item.photo.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item.desc.toString(),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: kSpecial,

                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 60,
                          child: Center(
                            child: Text(
                              item.name.toString(),
                              style: kMovieTitle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
