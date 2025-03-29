import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EventModel>> getEvents() {
    return _firestore.collection('events').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.eventId).set(event.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.eventId).update(event.toMap());
  }

  Future<List<EventModel>> getPopularEventsInCity(String city) async {
    // This is a simplified example; you may need to adjust based on how you store city data
    final query = await _firestore
        .collection('events')
        .where('city', isEqualTo: city) // Assumes events have a city field
        .get();
    final events = query.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    // Sort by number of participants (popularity)
    events.sort((a, b) => b.participants.length.compareTo(a.participants.length));
    return events.take(5).toList(); // Return top 5 popular events
  }
}