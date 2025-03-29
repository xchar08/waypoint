import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String eventId, String senderId, String content) async {
    final message = MessageModel(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: eventId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
    );
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toMap());
  }

  Stream<List<MessageModel>> getMessages(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }
}