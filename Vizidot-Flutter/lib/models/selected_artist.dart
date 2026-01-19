import 'package:flutter/foundation.dart';
import 'package:vizidot_flutter/models/artists.dart';

class AppArtist extends ChangeNotifier {
  Artist? _selectedArtist;

  Artist? get selectedArtist => _selectedArtist;

  set selectedArtist(Artist? artist) {
    _selectedArtist = artist;
    notifyListeners();
  }
}