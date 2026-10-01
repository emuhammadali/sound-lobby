class MusicRequestModel {
  final String id;
  final String uid;
  final String requesterName;
  final String songQuery;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  const MusicRequestModel({
    required this.id,
    required this.uid,
    required this.requesterName,
    required this.songQuery,
    required this.status,
    required this.requestedAt,
  });

  factory MusicRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return MusicRequestModel(
      id: id,
      uid: map['uid'] ?? '',
      requesterName: map['requesterName'] ?? 'Unknown',
      songQuery: map['songQuery'] ?? '',
      status: map['status'] ?? 'pending',
      requestedAt: map['requestedAt'] != null
          ? (map['requestedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'requesterName': requesterName,
      'songQuery': songQuery,
      'status': status,
      'requestedAt': requestedAt,
    };
  }

  bool get isPending => status == 'pending';
}