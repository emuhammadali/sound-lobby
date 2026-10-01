import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lobby_model.dart';
import '../models/participant_model.dart';
import '../models/user_model.dart';

class LobbyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _lobbies => _firestore.collection('lobbies');

  // Generate a short room code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueCode() async {
    while (true) {
      final code = _generateCode();

      final exists = await _lobbies.doc(code).get();

      if (!exists.exists) {
        return code;
      }
    }
  }

  // Create a new lobby
  Future<LobbyModel> createLobby({
    required String name,
    required UserModel creator,
  }) async {
    final code = await _generateUniqueCode();
    final lobbyRef = _lobbies.doc(code);

    final lobby = LobbyModel(
      id: code,
      name: name,
      adminId: creator.uid,
      djIds: [],
      participantIds: [creator.uid],
    );

    final batch = _firestore.batch();

    // Create lobby document
    batch.set(lobbyRef, lobby.toMap());

    // Add creator as participant with admin role
    batch.set(
      lobbyRef.collection('participants').doc(creator.uid),
      ParticipantModel(
        uid: creator.uid,
        fullName: creator.fullName,
        role: 'admin',
        joinedAt: DateTime.now(),
      ).toMap(),
    );

    await batch.commit();
    return lobby;
  }

  // Join an existing lobby
  Future<LobbyModel> joinLobby({
    required String code,
    required UserModel user,
  }) async {
    final lobbyRef = _lobbies.doc(code.toUpperCase());
    final doc = await lobbyRef.get();

    if (!doc.exists) {
      throw Exception('Lobby not found. Check the code and try again.');
    }

    final lobby =
        LobbyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    if (lobby.isParticipant(user.uid)) return lobby;

    final batch = _firestore.batch();

    batch.update(lobbyRef, {
      'participantIds': FieldValue.arrayUnion([user.uid]),
    });

    batch.set(
      lobbyRef.collection('participants').doc(user.uid),
      ParticipantModel(
        uid: user.uid,
        fullName: user.fullName,
        role: 'listener',
        joinedAt: DateTime.now(),
      ).toMap(),
    );

    await batch.commit();
    return lobby;
  }

  // Leave a lobby
  Future<void> leaveLobby({
    required String lobbyId,
    required String uid,
  }) async {
    final lobbyRef = _lobbies.doc(lobbyId);
    final doc = await lobbyRef.get();
    if (!doc.exists) return;

    final lobby =
        LobbyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    final batch = _firestore.batch();

    // Remove participant sub-doc
    batch.delete(lobbyRef.collection('participants').doc(uid));

    final remaining = lobby.participantIds.where((id) => id != uid).toList();

    if (remaining.isEmpty) {
      // Last person left — delete the lobby
      batch.delete(lobbyRef);
    } else {
      String newAdminId = lobby.adminId;

      if (lobby.adminId == uid) {
        // Transfer admin to a random remaining participant
        final rand = Random.secure();
        newAdminId = remaining[rand.nextInt(remaining.length)];

        // Update their participant doc role to admin
        batch.update(
          lobbyRef.collection('participants').doc(newAdminId),
          {'role': 'admin'},
        );
      }

      batch.update(lobbyRef, {
        'participantIds': FieldValue.arrayRemove([uid]),
        'djIds': FieldValue.arrayRemove([uid]),
        if (lobby.adminId == uid) 'adminId': newAdminId,
      });
    }

    await batch.commit();
  }

  // Kick a user
  Future<void> kickUser({
    required String lobbyId,
    required String targetUid,
  }) async {
    final lobbyRef = _lobbies.doc(lobbyId);
    final batch = _firestore.batch();

    batch.delete(lobbyRef.collection('participants').doc(targetUid));
    batch.update(lobbyRef, {
      'participantIds': FieldValue.arrayRemove([targetUid]),
      'djIds': FieldValue.arrayRemove([targetUid]),
    });

    await batch.commit();
  }

  // Assign DJ role
  Future<void> assignDJ({
    required String lobbyId,
    required String targetUid,
  }) async {
    final lobbyRef = _lobbies.doc(lobbyId);
    final batch = _firestore.batch();

    batch.update(lobbyRef, {
      'djIds': FieldValue.arrayUnion([targetUid]),
    });
    batch.update(
      lobbyRef.collection('participants').doc(targetUid),
      {'role': 'dj'},
    );

    await batch.commit();
  }

  // Revoke DJ role
  Future<void> revokeDJ({
    required String lobbyId,
    required String targetUid,
  }) async {
    final lobbyRef = _lobbies.doc(lobbyId);
    final batch = _firestore.batch();

    batch.update(lobbyRef, {
      'djIds': FieldValue.arrayRemove([targetUid]),
    });
    batch.update(
      lobbyRef.collection('participants').doc(targetUid),
      {'role': 'listener'},
    );

    await batch.commit();
  }

  // Transfer Admin ownership
  Future<void> transferAdmin({
    required String lobbyId,
    required String currentAdminId,
    required String newAdminId,
  }) async {
    final lobbyRef = _lobbies.doc(lobbyId);
    final batch = _firestore.batch();

    batch.update(lobbyRef, {'adminId': newAdminId});
    batch.update(
      lobbyRef.collection('participants').doc(currentAdminId),
      {'role': 'listener'},
    );
    batch.update(
      lobbyRef.collection('participants').doc(newAdminId),
      {'role': 'admin'},
    );

    await batch.commit();
  }

  // Streams
  Stream<LobbyModel?> lobbyStream(String lobbyId) {
    return _lobbies.doc(lobbyId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return LobbyModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  Stream<List<ParticipantModel>> participantsStream(String lobbyId) {
    return _lobbies
        .doc(lobbyId)
        .collection('participants')
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ParticipantModel.fromMap(d.data(), d.id))
            .toList());
  }
}