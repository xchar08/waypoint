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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Helper function to parse Timestamp or String into DateTime
    DateTime parseDateTime(dynamic value, {required String fieldName}) {
      try {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          return DateTime.parse(value); // Parse ISO 8601 string
        }
        print('Invalid $fieldName format: $value. Using current time as fallback.');
        return DateTime.now(); // Fallback for invalid data
      } catch (e) {
        print('Error parsing $fieldName: $e. Using current time as fallback.');
        return DateTime.now();
      }
    }

    return EventModel(
      eventId: doc.id,
      activity: data['activity'] as String? ?? '',
      description: data['description'] as String? ?? '',
      startTime: parseDateTime(data['startTime'], fieldName: 'startTime'),
      endTime: parseDateTime(data['endTime'], fieldName: 'endTime'),
      location: LatLng(
        (data['location']?['latitude'] as num?)?.toDouble() ?? 0.0,
        (data['location']?['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      city: data['city'] as String? ?? '',
      fetchedCity: data['fetchedCity'] as String?,
      address: data['address'] as String?,
      maxParticipants: data['maxParticipants'] as int? ?? 0,
      organizerId: data['organizerId'] as String? ?? '',
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