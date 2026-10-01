import 'song_model.dart';

class QueuedSongModel {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? thumbnail;
  final int? durationMs;
  final String addedByUid;
  final String addedByName;
  final int order;
  final DateTime addedAt;

  const QueuedSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.thumbnail,
    this.durationMs,
    required this.addedByUid,
    required this.addedByName,
    required this.order,
    required this.addedAt,
  });

  factory QueuedSongModel.fromMap(Map<String, dynamic> map, String id) {
    return QueuedSongModel(
      id: id,
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown',
      url: map['url'] ?? '',
      thumbnail: map['thumbnail'],
      durationMs: map['durationMs'],
      addedByUid: map['addedByUid'] ?? '',
      addedByName: map['addedByName'] ?? 'Unknown',
      order: map['order'] ?? 0,
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'url': url,
      'thumbnail': thumbnail,
      'durationMs': durationMs,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'order': order,
      'addedAt': addedAt,
    };
  }

  SongModel toSongModel() => SongModel(
        id: id,
        title: title,
        artist: artist,
        audioUrl: url,
        thumbnail: thumbnail,
        durationMs: durationMs,
      );
}