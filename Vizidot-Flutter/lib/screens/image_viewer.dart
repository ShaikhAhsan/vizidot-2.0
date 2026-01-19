import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewerGallery extends StatefulWidget {
  ImageViewerGallery({Key? key, required this.galleryItems}) : super(key: key);
  int selectedIndex = 0;
  List<String> galleryItems = [];

  @override
  _ImageViewerGalleryState createState() => _ImageViewerGalleryState();
}

class _ImageViewerGalleryState extends State<ImageViewerGallery> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
        title: Text(
            'Images ${widget.selectedIndex + 1} of ${widget.galleryItems.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
          child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider:
                CachedNetworkImageProvider(widget.galleryItems[index]),
            initialScale: PhotoViewComputedScale.contained * 0.8,
            heroAttributes:
                PhotoViewHeroAttributes(tag: widget.galleryItems[index]),
          );
        },
        itemCount: widget.galleryItems.length,
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null ? 0 : 0,
            ),
          ),
        ),

        onPageChanged: (index) {
          if (mounted)
            setState(() {
              widget.selectedIndex = index;
            });
        },
        //backgroundDecoration: backgroundDecoration,
        //pageController: widget.pageController,
      )),
    );
  }
}
