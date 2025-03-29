import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/animated_marker.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late AnimationController _controller;
  late Animation<double> _animation;
  LatLng? _selectedLocation; // Store the tapped location

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waypoint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(32.7357, -97.1081), // Default: UTA
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point; // Store the tapped location
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              StreamBuilder<List<EventModel>>(
                stream: _eventService.getEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading events'));
                  }
                  final events = snapshot.data ?? [];
                  List<Marker> markers = events
                      .map((event) => Marker(
                            point: event.location,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => EventDetailsScreen(event: event))),
                              child: AnimatedMarker(event: event, animation: _animation),
                            ),
                          ))
                      .toList();
                  if (_selectedLocation != null) {
                    markers.add(
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    );
                  }
                  return MarkerLayer(markers: markers);
                },
              ),
            ],
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Pass the selected location to CreateEventScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEventScreen(
                        initialLocation: _selectedLocation,
                      ),
                    ),
                  ).then((_) {
                    // Clear the selected location when returning from CreateEventScreen
                    setState(() {
                      _selectedLocation = null;
                    });
                  });
                },
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedLocation == null
          ? FloatingActionButton(
              onPressed: () {
                // If no location is selected, use the default location
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}