import 'package:get/get.dart';

import '../network/apis/settings_api.dart';

/// Global selected artist from settings API response (profile.assignedArtists).
/// Updated whenever settings are loaded; use [selectedArtist] everywhere for current identity.
class SelectedArtistService extends GetxService {
  final Rx<AssignedArtistData?> _selectedArtist = Rx<AssignedArtistData?>(null);
  final RxList<AssignedArtistData> _assignedArtists = <AssignedArtistData>[].obs;

  /// Current selected artist (first from assignedArtists when updated from settings). Null if none.
  AssignedArtistData? get selectedArtist => _selectedArtist.value;
  Rx<AssignedArtistData?> get selectedArtistRx => _selectedArtist;

  /// All assigned artists from last settings response. Use for lists/tabs.
  List<AssignedArtistData> get assignedArtists => _assignedArtists.toList();
  RxList<AssignedArtistData> get assignedArtistsRx => _assignedArtists;

  /// Called when settings API responds. Updates [assignedArtists] and [selectedArtist].
  void updateFromProfile(
    List<AssignedArtistData>? assignedArtists,
  ) {
    _assignedArtists.assignAll(assignedArtists ?? []);
    if (_assignedArtists.isEmpty) {
      _selectedArtist.value = null;
    } else {
      // Keep current selection if still in list; otherwise select first
      final current = _selectedArtist.value;
      final stillInList = current != null &&
          _assignedArtists.any((a) => a.artistId == current.artistId);
      _selectedArtist.value =
          stillInList ? current : _assignedArtists.first;
    }
  }

  /// Select a specific artist (e.g. when user has multiple and picks one).
  void selectArtist(AssignedArtistData? artist) {
    _selectedArtist.value = artist;
  }

  /// Clear selection (e.g. on logout). Call when profile is cleared.
  void clear() {
    _assignedArtists.clear();
    _selectedArtist.value = null;
  }

  /// Broadcast UID for "Streaming now" filter and LiveStreams: artist id when artist, else use Firebase UID.
  String? broadcasterUidOrNull(String? firebaseUid) {
    if (firebaseUid == null) return null;
    final artist = _selectedArtist.value;
    if (artist != null) return artist.artistId.toString();
    return firebaseUid;
  }
}
