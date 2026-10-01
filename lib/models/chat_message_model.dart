class ChatMessageModel {
  final String id;
  final String uid;
  final String senderName;
  final String message;
  final bool isRequest;
  final String? requestSongQuery;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.uid,
    required this.senderName,
    required this.message,
    required this.isRequest,
    this.requestSongQuery,
    required this.sentAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      uid: map['uid'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      message: map['message'] ?? '',
      isRequest: map['isRequest'] ?? false,
      requestSongQuery: map['requestSongQuery'],
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'senderName': senderName,
      'message': message,
      'isRequest': isRequest,
      'requestSongQuery': requestSongQuery,
      'sentAt': sentAt,
    };
  }
}