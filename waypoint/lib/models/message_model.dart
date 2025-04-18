import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String eventId;
  final String senderId;
  final String content;
  final DateTime timestamp; // Add timestamp field

  MessageModel({
    required this.messageId,
    required this.eventId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return MessageModel(
      messageId: doc.id,
      eventId: data['eventId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}