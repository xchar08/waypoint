import 'package:flutter/material.dart';
import '../models/event_model.dart';

class AnimatedMarker extends StatelessWidget {
  final EventModel event;
  final Animation<double> animation;

  AnimatedMarker({required this.event, required this.animation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(animation),
      child: Icon(
        Icons.location_pin,
        color: event.participants.length < event.maxParticipants ? Colors.green : Colors.red,
        size: 40,
      ),
    );
  }
}