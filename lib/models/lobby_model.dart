class LobbyModel {
  final String id;
  final String name;
  final String adminId;
  final List<String> djIds;
  final List<String> participantIds;
  final bool isPlaying;
  final String? currentSongTitle;
  final String? currentSongArtist;
  final String? currentSongUrl;
  final String? currentSongThumbnail;
  final int currentPositionMs;
  final DateTime? playbackStartedAt;

  const LobbyModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.djIds,
    required this.participantIds,
    this.isPlaying = false,
    this.currentSongTitle,
    this.currentSongArtist,
    this.currentSongUrl,
    this.currentSongThumbnail,
    this.currentPositionMs = 0,
    this.playbackStartedAt,
  });

  factory LobbyModel.fromMap(Map<String, dynamic> map, String id) {
    return LobbyModel(
      id: id,
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      djIds: List<String>.from(map['djIds'] ?? []),
      participantIds: List<String>.from(map['participantIds'] ?? []),
      isPlaying: map['isPlaying'] ?? false,
      currentSongTitle: map['currentSongTitle'],
      currentSongArtist: map['currentSongArtist'],
      currentSongUrl: map['currentSongUrl'],
      currentSongThumbnail: map['currentSongThumbnail'],
      currentPositionMs: map['currentPositionMs'] ?? 0,
      playbackStartedAt: map['playbackStartedAt'] != null
          ? (map['playbackStartedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminId': adminId,
      'djIds': djIds,
      'participantIds': participantIds,
      'isPlaying': isPlaying,
      'currentSongTitle': currentSongTitle,
      'currentSongArtist': currentSongArtist,
      'currentSongUrl': currentSongUrl,
      'currentSongThumbnail': currentSongThumbnail,
      'currentPositionMs': currentPositionMs,
      'playbackStartedAt': playbackStartedAt,
    };
  }

  bool isAdmin(String uid) => adminId == uid;
  bool isDJ(String uid) => djIds.contains(uid) || adminId == uid;
  bool isParticipant(String uid) => participantIds.contains(uid);

  LobbyModel copyWith({
    String? id,
    String? name,
    String? adminId,
    List<String>? djIds,
    List<String>? participantIds,
    bool? isPlaying,
    String? currentSongTitle,
    String? currentSongArtist,
    String? currentSongUrl,
    String? currentSongThumbnail,
    int? currentPositionMs,
    DateTime? playbackStartedAt,
  }) {
    return LobbyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      djIds: djIds ?? this.djIds,
      participantIds: participantIds ?? this.participantIds,
      isPlaying: isPlaying ?? this.isPlaying,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentSongArtist: currentSongArtist ?? this.currentSongArtist,
      currentSongUrl: currentSongUrl ?? this.currentSongUrl,
      currentSongThumbnail: currentSongThumbnail ?? this.currentSongThumbnail,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      playbackStartedAt: playbackStartedAt ?? this.playbackStartedAt,
    );
  }
}