import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
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
  String _activity = '';
  String _description = '';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  int _maxParticipants = 10;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(32.7357, -97.1081);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Form(
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
                decoration: const InputDecoration(labelText: 'Max Participants'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter a number' : null,
                onSaved: (value) => _maxParticipants = int.parse(value!),
              ),
              ListTile(
                title: Text('Location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final userId = _authService.getUserId();
                    if (userId == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                      return;
                    }
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
                    );
                    await _eventService.createEvent(event);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create Event'),
              ),
            ],
          ),
        ),
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