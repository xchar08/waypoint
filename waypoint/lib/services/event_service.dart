import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart'; // Added this import for LatLng
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EventModel>> getEvents() {
    try {
      return _firestore.collection('events').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return EventModel.fromFirestore(doc);
          } catch (e) {
            print('Error parsing event ${doc.id}: $e');
            return EventModel(
              eventId: doc.id,
              activity: 'Error',
              description: 'Failed to load event',
              startTime: DateTime.now(),
              endTime: DateTime.now(),
              location: const LatLng(0.0, 0.0), // Now valid with import
              city: '',
              maxParticipants: 0,
              organizerId: '',
              participants: [],
            ); // Fallback event
          }
        }).toList();
      });
    } catch (e) {
      print('Error streaming events: $e');
      return Stream.value([]); // Return empty list on stream failure
    }
  }

  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore.collection('events').doc(event.eventId).set(event.toMap());
    } catch (e) {
      print('Error creating event ${event.eventId}: $e');
      rethrow; // Rethrow to handle in UI if needed
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore.collection('events').doc(event.eventId).update(event.toMap());
    } catch (e) {
      print('Error updating event ${event.eventId}: $e');
      rethrow; // Rethrow to handle in UI if needed
    }
  }

  Future<List<EventModel>> getPopularEventsInCity(String city) async {
    try {
      final query = await _firestore
          .collection('events')
          .where('city', isEqualTo: city)
          .get();
      final events = query.docs.map((doc) {
        try {
          return EventModel.fromFirestore(doc);
        } catch (e) {
          print('Error parsing popular event ${doc.id}: $e');
          return EventModel(
            eventId: doc.id,
            activity: 'Error',
            description: 'Failed to load event',
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            location: const LatLng(0.0, 0.0), // Now valid with import
            city: city,
            maxParticipants: 0,
            organizerId: '',
            participants: [],
          ); // Fallback event
        }
      }).toList();
      events.sort((a, b) => b.participants.length.compareTo(a.participants.length));
      return events.take(5).toList(); // Return top 5 popular events
    } catch (e) {
      print('Error fetching popular events in city $city: $e');
      return []; // Return empty list on error
    }
  }
}