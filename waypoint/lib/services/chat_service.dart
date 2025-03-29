import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  Stream<List<MessageModel>> getMessages(String eventId) {
    return _messagesCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String eventId, String senderId, String content) async {
    final message = MessageModel(
      messageId: _messagesCollection.doc().id,
      eventId: eventId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
    );
    await _messagesCollection.doc(message.messageId).set(message.toMap());
  }
} 