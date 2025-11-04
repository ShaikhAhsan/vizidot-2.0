import 'package:get/get.dart';

class Artist {
  final String name;
  final String genre;
  final String asset;
  final bool isBookmarked;

  Artist({
    required this.name,
    required this.genre,
    required this.asset,
    this.isBookmarked = false,
  });
}

class ELockerController extends GetxController {
  // Featured artists - horizontal scroll
  final featuredArtists = <Artist>[
    Artist(
      name: 'Baynk',
      genre: 'Pop / Chill',
      asset: 'assets/artists/Aalyah.png',
    ),
    Artist(
      name: 'Hozier',
      genre: 'Chill / Techno',
      asset: 'assets/artists/Blair.png',
    ),
    Artist(
      name: 'Baynk',
      genre: 'Pop / Chill',
      asset: 'assets/artists/Choc B.png',
    ),
    Artist(
      name: 'Hozier',
      genre: 'Chill / Techno',
      asset: 'assets/artists/Halsey.png',
    ),
    Artist(
      name: 'Jason Derulo',
      genre: 'Pop / Chill',
      asset: 'assets/artists/Jason Derulo.png',
    ),
  ].obs;

  // Rising stars - vertical list
  final risingStars = <Artist>[
    Artist(
      name: 'Natalie',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Aalyah.png',
    ),
    Artist(
      name: 'Jonnathan Bear',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Blair.png',
    ),
    Artist(
      name: 'Damon Layer',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Choc B.png',
    ),
    Artist(
      name: 'Anna Leinz',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Halsey.png',
    ),
    Artist(
      name: 'Mainate',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Jason Derulo.png',
    ),
    Artist(
      name: 'Coleco',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Julia Styles.png',
    ),
    Artist(
      name: 'Betty Daniels',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Betty Daniels.png',
    ),
    Artist(
      name: 'Martina',
      genre: 'Pop / Chill / Techno',
      asset: 'assets/artists/Martina.png',
    ),
  ].obs;

  void toggleBookmark(int index, {bool isRisingStar = false}) {
    if (isRisingStar) {
      if (index < risingStars.length) {
        final artist = risingStars[index];
        risingStars[index] = Artist(
          name: artist.name,
          genre: artist.genre,
          asset: artist.asset,
          isBookmarked: !artist.isBookmarked,
        );
      }
    } else {
      if (index < featuredArtists.length) {
        final artist = featuredArtists[index];
        featuredArtists[index] = Artist(
          name: artist.name,
          genre: artist.genre,
          asset: artist.asset,
          isBookmarked: !artist.isBookmarked,
        );
      }
    }
  }
}

