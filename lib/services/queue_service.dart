import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queued_song_model.dart';
import '../models/song_model.dart';

class QueueService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference _queue(String lobbyId) =>
      _fs.collection('lobbies').doc(lobbyId).collection('queue');

  Future<void> addToQueue({
    required String lobbyId,
    required SongModel song,
    required String addedByUid,
    required String addedByName,
  }) async {
    // Get current max order
    final snap =
        await _queue(lobbyId).orderBy('order', descending: true).limit(1).get();

    final nextOrder =
        snap.docs.isEmpty ? 0 : (snap.docs.first['order'] as int) + 1;

    await _queue(lobbyId).add({
      'title': song.title,
      'artist': song.artist,
      'url': song.audioUrl,
      'thumbnail': song.thumbnail,
      'durationMs': song.durationMs,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'order': nextOrder,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromQueue({
    required String lobbyId,
    required String queueItemId,
  }) async {
    await _queue(lobbyId).doc(queueItemId).delete();
  }

  Future<QueuedSongModel?> popNext(String lobbyId) async {
    final snap = await _queue(lobbyId)
        .orderBy('order', descending: false)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final item =
        QueuedSongModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    await doc.reference.delete();
    return item;
  }

  Stream<List<QueuedSongModel>> queueStream(String lobbyId) {
    return _queue(lobbyId).orderBy('order', descending: false).snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                QueuedSongModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}