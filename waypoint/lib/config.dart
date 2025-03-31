import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get vertexAiApiKey => dotenv.env['VERTEX_AI_API_KEY'] ?? '';
}