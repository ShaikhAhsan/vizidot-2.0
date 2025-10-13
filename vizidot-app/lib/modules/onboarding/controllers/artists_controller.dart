import 'package:get/get.dart';

class ArtistItem {
  final String name;
  final String asset;
  ArtistItem(this.name, this.asset);
}

class ArtistsController extends GetxController {
  final items = <ArtistItem>[
    ArtistItem('Martina', 'assets/artists/Martina.png'),
    ArtistItem('Jason Derulo', 'assets/artists/Jason Derulo.png'),
    ArtistItem('Julia Styles', 'assets/artists/Julia Styles.png'),
    ArtistItem('Travis', 'assets/artists/Travis.png'),
    ArtistItem('Choc B', 'assets/artists/Choc B.png'),
    ArtistItem('Halsey', 'assets/artists/Halsey.png'),
    ArtistItem('Betty Daniels', 'assets/artists/Betty Daniels.png'),
    ArtistItem('Blair', 'assets/artists/Blair.png'),
    ArtistItem('Aalyah', 'assets/artists/Aalyah.png'),
  ].obs;

  final selected = <int>{}.obs;

  bool get canContinue => selected.length >= 3;

  void toggle(int index) {
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
    selected.refresh();
  }
}



