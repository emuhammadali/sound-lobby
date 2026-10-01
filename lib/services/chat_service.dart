import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../models/music_request_model.dart';

class ChatService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference _chat(String lobbyId) =>
      _fs.collection('lobbies').doc(lobbyId).collection('chat');

  CollectionReference _requests(String lobbyId) =>
      _fs.collection('lobbies').doc(lobbyId).collection('musicRequests');

  Future<void> sendMessage({
    required String lobbyId,
    required String uid,
    required String senderName,
    required String message,
  }) async {
    await _chat(lobbyId).add({
      'uid': uid,
      'senderName': senderName,
      'message': message,
      'isRequest': false,
      'requestSongQuery': null,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendRequest({
    required String lobbyId,
    required String uid,
    required String requesterName,
    required String songQuery,
  }) async {
    // Add to chat as a request bubble
    await _chat(lobbyId).add({
      'uid': uid,
      'senderName': requesterName,
      'message': '🎵 Requested: $songQuery',
      'isRequest': true,
      'requestSongQuery': songQuery,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // Add to the DJ request queue
    await _requests(lobbyId).add({
      'uid': uid,
      'requesterName': requesterName,
      'songQuery': songQuery,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRequestStatus({
    required String lobbyId,
    required String requestId,
    required String status, // 'approved' or 'rejected'
  }) async {
    await _requests(lobbyId).doc(requestId).update({'status': status});
  }

  Stream<List<ChatMessageModel>> chatStream(String lobbyId) {
    return _chat(lobbyId)
        .orderBy('sentAt', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Stream<List<MusicRequestModel>> pendingRequestsStream(String lobbyId) {
    return _requests(lobbyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MusicRequestModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}