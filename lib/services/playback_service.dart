import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';

class PlaybackService {
  final _fs = FirebaseFirestore.instance;

  DocumentReference _ref(String lobbyId) =>
      _fs.collection('lobbies').doc(lobbyId);

  /// Start playing a new song from the beginning
  Future<void> playSong({
    required String lobbyId,
    required SongModel song,
    int startPositionMs = 0,
  }) =>
      _ref(lobbyId).update({
        'isPlaying': true,
        'currentSongTitle': song.title,
        'currentSongArtist': song.artist,
        'currentSongUrl': song.audioUrl,
        'currentSongThumbnail': song.thumbnail,
        'currentPositionMs': startPositionMs,
        'playbackStartedAt': FieldValue.serverTimestamp(),
      });

  /// Stop — wipes all song state
  Future<void> stop(String lobbyId) => _ref(lobbyId).update({
        'isPlaying': false,
        'currentSongTitle': null,
        'currentSongArtist': null,
        'currentSongUrl': null,
        'currentSongThumbnail': null,
        'currentPositionMs': 0,
        'playbackStartedAt': null,
      });

  /// Calculates where playback should be right now for a joining listener
  int calculateSyncPosition({
    required int storedPositionMs,
    required DateTime playbackStartedAt,
  }) {
    final now = Timestamp.now().toDate();

    final elapsed = now.difference(playbackStartedAt).inMilliseconds;

    final safeElapsed = elapsed < 0 ? 0 : elapsed;

    return (storedPositionMs + safeElapsed).clamp(0, 2147483647);
  }
}