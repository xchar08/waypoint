import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/geocoding_service.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final GeocodingService _geocodingService = GeocodingService();
  late String _activity;
  late String _description;
  late DateTime _startTime;
  late DateTime _endTime;
  late int _maxParticipants;
  late LatLng _selectedLocation;
  late String _city;
  String? _fetchedCity;
  String? _address;
  bool _isLoading = false;
  bool _isGeocodingLoading = true;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _activity = widget.event.activity;
    _description = widget.event.description;
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _maxParticipants = widget.event.maxParticipants;
    _selectedLocation = widget.event.location;
    _city = widget.event.city;
    _fetchedCity = widget.event.fetchedCity;
    _address = widget.event.address;
    _cityController = TextEditingController(text: _city);
    if (_address == null) {
      _fetchAddressAndCity();
    } else {
      _isGeocodingLoading = false;
    }
  }

  Future<void> _fetchAddressAndCity() async {
    setState(() {
      _isGeocodingLoading = true;
    });
    final result = await _geocodingService.getAddressAndCityFromLatLng(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
      language: 'en',
      region: 'us',
      resultType: 'street_address',
      locationType: 'ROOFTOP',
      components: 'country:US',
    );
    setState(() {
      _address = result['address'];
      _fetchedCity = result['city'];
      if (_city.isEmpty) {
        _city = _fetchedCity ?? '';
        _cityController.text = _city;
      }
      _isGeocodingLoading = false;
    });
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
        title: const Text('Edit Event'),
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
                    initialValue: _activity,
                    decoration: const InputDecoration(labelText: 'Activity'),
                    validator: (value) => value!.isEmpty ? 'Enter an activity' : null,
                    onSaved: (value) => _activity = value!,
                  ),
                  TextFormField(
                    initialValue: _description,
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
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                  ListTile(
                    title: Text('End Time: ${_endTime.toString()}'),
                    onTap: () async {
                      final picked = await showDateTimePicker(context, _endTime);
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                  TextFormField(
                    initialValue: _maxParticipants.toString(),
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
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                final updatedEvent = EventModel(
                                  eventId: widget.event.eventId,
                                  activity: _activity,
                                  description: _description,
                                  startTime: _startTime,
                                  endTime: _endTime,
                                  location: _selectedLocation,
                                  maxParticipants: _maxParticipants,
                                  organizerId: widget.event.organizerId,
                                  participants: widget.event.participants,
                                  city: _city,
                                  fetchedCity: _fetchedCity,
                                  address: _address,
                                );
                                await _eventService.updateEvent(updatedEvent);
                                Navigator.pop(context, updatedEvent);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating event: $e')),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
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