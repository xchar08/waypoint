import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/event_model.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aiQuestionController = TextEditingController();
  final vertexAI = FirebaseVertexAI.instance;
  String _aiResponse = '';
  bool _isExpanded = false;

  Future<void> _askGemini() async {
    final model = vertexAI.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 100,
      ),
    );
    final prompt = '''
    Event details:
    - Activity: ${widget.event.activity}
    - Description: ${widget.event.description}
    - Start Time: ${widget.event.startTime}
    - End Time: ${widget.event.endTime}
    - Location: ${widget.event.location.latitude}, ${widget.event.location.longitude}
    - Max Participants: ${widget.event.maxParticipants}
    Question: ${_aiQuestionController.text}
    Provide a concise, helpful answer based on the event data.
    ''';
    final response = await model.generateContent([Content.text(prompt)]);
    setState(() {
      _aiResponse = response.text ?? 'Sorry, I couldn’t generate a response.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.activity)),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? 200 : 100,
            child: Card(
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description: ${widget.event.description}'),
                      if (_isExpanded) ...[
                        Text('Start: ${widget.event.startTime}'),
                        Text('End: ${widget.event.endTime}'),
                        Text('Location: ${widget.event.location.latitude}, ${widget.event.location.longitude}'),
                        Text('Max Participants: ${widget.event.maxParticipants}'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.event.eventId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(messages[index].content),
                    subtitle: Text(messages[index].senderId),
                  ),
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
                    _chatService.sendMessage(
                      widget.event.eventId,
                      widget.event.organizerId,
                      _messageController.text,
                    );
                    _messageController.clear();
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
                  onPressed: _askGemini,
                  child: const Text('Ask Gemini'),
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