import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/geocoding_service.dart';
import 'login_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const CreateEventScreen({super.key, this.initialLocation});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final GeocodingService _geocodingService = GeocodingService();
  String _activity = '';
  String _description = '';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  int _maxParticipants = 10;
  late LatLng _selectedLocation;
  String _city = '';
  String? _fetchedCity;
  String? _address;
  bool _isLoading = false;
  bool _isGeocodingLoading = true;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(32.7357, -97.1081);
    _fetchAddressAndCity();
  }

  Future<void> _fetchAddressAndCity() async {
    if (!mounted) return; // Prevent action if already disposed
    setState(() {
      _isGeocodingLoading = true;
    });
    try {
      final result = await _geocodingService.getAddressAndCityFromLatLng(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
        language: 'en',
        region: 'us',
        resultType: 'street_address',
        locationType: 'ROOFTOP',
        components: 'country:US',
      );
      if (!mounted) return; // Check before updating state
      setState(() {
        _address = result['address'];
        _fetchedCity = result['city'];
        _city = _fetchedCity ?? '';
        _cityController.text = _city;
        _isGeocodingLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Prevent setState if disposed
      print('Error fetching address: $e');
      setState(() {
        _address = 'Unknown address';
        _fetchedCity = null;
        _city = '';
        _cityController.text = '';
        _isGeocodingLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Activity'),
                    validator: (value) => value!.isEmpty ? 'Enter an activity' : null,
                    onSaved: (value) => _activity = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Enter a description' : null,
                    onSaved: (value) => _description = value!,
                  ),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value!.isEmpty ? 'Enter a city' : null,
                    onSaved: (value) => _city = value!,
                  ),
                  ListTile(
                    title: _isGeocodingLoading
                        ? const Text('Loading location...')
                        : Text('Location: ${_address ?? 'Unknown location'}'),
                    subtitle: Text('Coordinates: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}'),
                  ),
                  ListTile(
                    title: Text('Start Time: ${_startTime.toString()}'),
                    onTap: () async {
                      final picked = await showDateTimePicker(context, _startTime);
                      if (picked != null && mounted) {
                        setState(() => _startTime = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('End Time: ${_endTime.toString()}'),
                    onTap: () async {
                      final picked = await showDateTimePicker(context, _endTime);
                      if (picked != null && mounted) {
                        setState(() => _endTime = picked);
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Max Participants'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Enter a number' : null,
                    onSaved: (value) => _maxParticipants = int.parse(value!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              if (_endTime.isBefore(_startTime)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('End time must be after start time')),
                                );
                                return;
                              }
                              final userId = _authService.getUserId();
                              if (userId == null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => LoginScreen()),
                                );
                                return;
                              }
                              if (!mounted) return; // Prevent action if disposed
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                final event = EventModel(
                                  eventId: DateTime.now().millisecondsSinceEpoch.toString(),
                                  activity: _activity,
                                  description: _description,
                                  startTime: _startTime,
                                  endTime: _endTime,
                                  location: _selectedLocation,
                                  maxParticipants: _maxParticipants,
                                  organizerId: userId,
                                  participants: [],
                                  city: _city,
                                  fetchedCity: _fetchedCity,
                                  address: _address,
                                );
                                await _eventService.createEvent(event);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error creating event: $e')),
                                  );
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Event'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time != null) {
        return DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    }
    return null;
  }
}