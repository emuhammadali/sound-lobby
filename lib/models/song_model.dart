class SongModel {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? thumbnail;
  final int? durationMs;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.thumbnail,
    this.durationMs,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? json['channel'] ?? 'Unknown Artist',
      audioUrl: json['audio_url'] ?? '',
      thumbnail: json['thumbnail'],
      durationMs: ((json['duration'] ?? 0) as num).toInt() * 1000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'thumbnail': thumbnail,
      'durationMs': durationMs,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      audioUrl: map['audio_url'] ?? '',
      thumbnail: map['thumbnail'],
      durationMs: map['durationMs'],
    );
  }

  SongModel copyWith({
    String? audioUrl,
  }) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnail: thumbnail,
      durationMs: durationMs,
    );
  }
}