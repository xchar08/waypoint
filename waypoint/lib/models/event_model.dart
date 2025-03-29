import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EventModel {
  final String eventId;
  final String activity;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final LatLng location;
  final String city; // User-entered or edited city
  final String? fetchedCity; // City fetched from geocoding (for reference)
  final String? address; // Fetched address
  final int maxParticipants;
  final String organizerId;
  final List<String> participants;

  EventModel({
    required this.eventId,
    required this.activity,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.city,
    this.fetchedCity,
    this.address,
    required this.maxParticipants,
    required this.organizerId,
    required this.participants,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return EventModel(
      eventId: doc.id,
      activity: data['activity'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: LatLng(
        data['location']['latitude'] ?? 0.0,
        data['location']['longitude'] ?? 0.0,
      ),
      city: data['city'] ?? '',
      fetchedCity: data['fetchedCity'],
      address: data['address'],
      maxParticipants: data['maxParticipants'] ?? 0,
      organizerId: data['organizerId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'city': city,
      'fetchedCity': fetchedCity,
      'address': address,
      'maxParticipants': maxParticipants,
      'organizerId': organizerId,
      'participants': participants,
    };
  }
}