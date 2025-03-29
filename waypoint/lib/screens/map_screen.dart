import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
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
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  late AnimationController _controller;
  late Animation<double> _animation;
  LatLng? _selectedLocation;
  String _searchQuery = '';
  bool _showFutureEventsOnly = false;
  bool _showFriendsEventsOnly = false; // New filter for friends' events
  List<String> _friendsList = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadFriendsList();
    _showTour();
  }

  Future<void> _loadFriendsList() async {
    final userId = _authService.getUserId();
    if (userId != null) {
      final friends = await _userService.getFriendsList(userId);
      setState(() {
        _friendsList = friends;
      });
    }
  }

  Future<void> _showTour() async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    final userEmail = await _userService.getUserEmail(userId);
    if (userEmail == null) return;

    final city = await _userService.getUserCity(userEmail);
    if (city == null) return;

    final popularEvents = await _eventService.getPopularEventsInCity(city);
    if (popularEvents.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Popular Events in $city'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: popularEvents.length,
            itemBuilder: (context, index) {
              final event = popularEvents[index];
              return ListTile(
                title: Text(event.activity),
                subtitle: Text('Participants: ${event.participants.length}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsScreen(event: event),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      body: Column(
        children: [
          // Search Bar and Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Events by Activity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Show Future Events Only'),
                    Switch(
                      value: _showFutureEventsOnly,
                      onChanged: (value) {
                        setState(() {
                          _showFutureEventsOnly = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Show Friends\' Events Only'),
                    Switch(
                      value: _showFriendsEventsOnly,
                      onChanged: (value) {
                        setState(() {
                          _showFriendsEventsOnly = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(32.7357, -97.1081),
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
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
                        // Apply search and filters
                        final filteredEvents = events.where((event) {
                          final matchesSearch = _searchQuery.isEmpty ||
                              event.activity.toLowerCase().contains(_searchQuery);
                          final matchesDate = !_showFutureEventsOnly ||
                              event.startTime.isAfter(DateTime.now());
                          final matchesFriends = !_showFriendsEventsOnly ||
                              _friendsList.contains(event.organizerId);
                          return matchesSearch && matchesDate && matchesFriends;
                        }).toList();
                        List<Marker> markers = filteredEvents
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateEventScreen(
                              initialLocation: _selectedLocation,
                            ),
                          ),
                        ).then((_) {
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
          ),
        ],
      ),
      floatingActionButton: _selectedLocation == null
          ? FloatingActionButton(
              onPressed: () {
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