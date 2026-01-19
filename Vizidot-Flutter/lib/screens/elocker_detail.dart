import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/models/artists.dart';
import 'package:vizidot_flutter/widgets/home_screen/photos_list.dart';
import 'package:vizidot_flutter/widgets/home_screen/special_list.dart';
import 'package:vizidot_flutter/widgets/home_screen/trending_list.dart';

class ElockerDetail extends StatefulWidget {
  final Artist artist;
  const ElockerDetail({Key? key, required this.artist}) : super(key: key);

  @override
  _ElockerDetailState createState() => _ElockerDetailState();
}

class _ElockerDetailState extends State<ElockerDetail> {
  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(widget.artist.name),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              (widget.artist.sponserIcon ?? "").length > 0
                  ? Container(
                      padding: EdgeInsets.all(5),
                      color: Colors.white,
                      height: 60,
                      child: CachedNetworkImage(
                        imageUrl: widget.artist.sponserIcon ?? "",
                      ))
                  : SizedBox(height: 0),
              SpecialList(
                  current: _current,
                  artists: [widget.artist],
                  carouselController: _carouselController),
              DefaultTabController(
                  length: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TabBar(
                          indicatorWeight: 2,
                          indicatorColor: kPrimaryColor,
                          labelColor: kPrimaryColor,
                          labelStyle: kButtonTextStyle,
                          unselectedLabelColor: kTabBarUnSelectedColor,
                          tabs: const [
                            Tab(text: 'Audio Songs'),
                            Tab(text: 'Videos')
                          ],
                          onTap: (index) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                        Builder(builder: (_) {
                          if (_current == 0) {
                            return PhotosList(
                                photos: widget.artist.images.length > 0
                                    ? widget.artist.images
                                    : [],
                                title: "Audio Songs", artist: widget?.artist);
                          } else {
                            return VideosList(
                              videosList: widget.artist.videos.length > 0
                                  ? widget.artist.videos
                                  : [],
                              title: "Videos",
                            );
                          }
                        }),
                      ])),
            ],
          ),
        ),
      ),
    );
    ;
  }
}
