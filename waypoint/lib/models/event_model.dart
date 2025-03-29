import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EventModel {
  final String eventId;
  final String activity;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final LatLng location;
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
      startTime: DateTime.parse(data['startTime']),
      endTime: DateTime.parse(data['endTime']),
      location: LatLng(data['location']['latitude'], data['location']['longitude']),
      maxParticipants: data['maxParticipants'] ?? 0,
      organizerId: data['organizerId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': {'latitude': location.latitude, 'longitude': location.longitude},
      'maxParticipants': maxParticipants,
      'organizerId': organizerId,
      'participants': participants,
    };
  }
}