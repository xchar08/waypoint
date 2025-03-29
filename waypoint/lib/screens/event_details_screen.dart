import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/geocoding_service.dart';
import '../services/user_service.dart';
import '../models/message_model.dart';
import 'edit_event_screen.dart';
import 'login_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ChatService _chatService = ChatService();
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final GeocodingService _geocodingService = GeocodingService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aiQuestionController = TextEditingController();
  final vertexAI = FirebaseVertexAI.instance;
  String _aiResponse = '';
  bool _isExpanded = false;
  late EventModel _event;
  bool _isAiLoading = false;
  bool _isGeocodingLoading = true;
  String? _address;
  Map<String, String> _userDisplayNames = {};

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _address = _event.address;
    if (_address == null) {
      _fetchAddress();
    } else {
      _isGeocodingLoading = false;
    }
  }

  Future<void> _fetchAddress() async {
    setState(() {
      _isGeocodingLoading = true;
    });
    final result = await _geocodingService.getAddressAndCityFromLatLng(
      _event.location.latitude,
      _event.location.longitude,
      language: 'en',
      region: 'us',
      resultType: 'street_address',
      locationType: 'ROOFTOP',
      components: 'country:US',
    );
    setState(() {
      _address = result['address'];
      _isGeocodingLoading = false;
    });

    // Update the event in Firestore with the fetched address
    final updatedEvent = EventModel(
      eventId: _event.eventId,
      activity: _event.activity,
      description: _event.description,
      startTime: _event.startTime,
      endTime: _event.endTime,
      location: _event.location,
      city: _event.city,
      fetchedCity: _event.fetchedCity,
      address: _address,
      maxParticipants: _event.maxParticipants,
      organizerId: _event.organizerId,
      participants: _event.participants,
    );
    await _eventService.updateEvent(updatedEvent);
    setState(() {
      _event = updatedEvent;
    });
  }

  Future<void> _fetchDisplayName(String userId) async {
    if (!_userDisplayNames.containsKey(userId)) {
      final displayName = await _userService.getUserDisplayName(userId);
      setState(() {
        _userDisplayNames[userId] = displayName;
      });
    }
  }

  Future<void> _askGemini() async {
    if (_aiQuestionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiResponse = '';
    });

    try {
      final model = vertexAI.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 100,
        ),
      );
      final prompt = '''
      Event details:
      - Activity: ${_event.activity}
      - Description: ${_event.description}
      - Start Time: ${_event.startTime}
      - End Time: ${_event.endTime}
      - Location: ${_event.location.latitude}, ${_event.location.longitude}
      - Address: ${_address ?? 'Unknown'}
      - City: ${_event.city}
      - Max Participants: ${_event.maxParticipants}
      Question: ${_aiQuestionController.text}
      Provide a concise, helpful answer based on the event data.
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() {
        _aiResponse = response.text ?? 'Sorry, I couldn’t generate a response.';
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Error: Failed to get a response from the AI assistant.';
      });
    } finally {
      setState(() {
        _isAiLoading = false;
      });
    }
  }

  Future<void> _signUpForEvent() async {
    final String? userId = _authService.getUserId();
    if (userId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

    if (_event.participants.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already signed up for this event')),
      );
      return;
    }

    if (_event.participants.length >= _event.maxParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event is full')),
      );
      return;
    }

    final updatedParticipants = List<String>.from(_event.participants)..add(userId);
    final updatedEvent = EventModel(
      eventId: _event.eventId,
      activity: _event.activity,
      description: _event.description,
      startTime: _event.startTime,
      endTime: _event.endTime,
      location: _event.location,
      city: _event.city,
      fetchedCity: _event.fetchedCity,
      address: _address,
      maxParticipants: _event.maxParticipants,
      organizerId: _event.organizerId,
      participants: updatedParticipants,
    );

    await _eventService.updateEvent(updatedEvent);
    setState(() {
      _event = updatedEvent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _authService.getUserId();

    return Scaffold(
      appBar: AppBar(title: Text(_event.activity)),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? 240 : 100,
            child: Card(
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description: ${_event.description}'),
                      if (_isExpanded) ...[
                        Text('Start: ${_event.startTime}'),
                        Text('End: ${_event.endTime}'),
                        Text('City: ${_event.city}'),
                        _isGeocodingLoading
                            ? const Text('Loading address...')
                            : Text('Address: ${_address ?? 'Unknown location'}'),
                        Text('Coordinates: ${_event.location.latitude}, ${_event.location.longitude}'),
                        Text('Max Participants: ${_event.maxParticipants}'),
                        Text('Current Participants: ${_event.participants.length}'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentUserId == _event.organizerId)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final updatedEvent = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEventScreen(event: _event),
                    ),
                  );
                  if (updatedEvent != null) {
                    setState(() {
                      _event = updatedEvent;
                      _address = updatedEvent.address;
                      if (_address == null) {
                        _fetchAddress();
                      }
                    });
                  }
                },
                child: const Text('Edit Event'),
              ),
            ),
          if (currentUserId != _event.organizerId)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: _signUpForEvent,
                child: const Text('Sign Up for Event'),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_event.eventId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                for (var message in messages) {
                  _fetchDisplayName(message.senderId);
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final displayName = _userDisplayNames[message.senderId] ?? 'Loading...';
                    final formattedTime = DateFormat('hh:mm a').format(message.timestamp);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.blue[800] : Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.content,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Send a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _chatService.sendMessage(
                        _event.eventId,
                        currentUserId ?? '',
                        _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _aiQuestionController,
                  decoration: const InputDecoration(
                    labelText: 'Ask the Event Assistant (e.g., "What should I bring?")',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isAiLoading ? null : _askGemini,
                  child: _isAiLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Ask Gemini'),
                ),
                const SizedBox(height: 8),
                Text(
                  _aiResponse,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}