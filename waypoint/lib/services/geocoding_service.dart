import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class GeocodingService {
  // Add configurable options for the API request
  Future<Map<String, String>> getAddressAndCityFromLatLng(
    double latitude,
    double longitude, {
    String language = 'en', // Default to English
    String? region, // Optional region bias (e.g., 'us' for United States)
    String? resultType, // Optional result type (e.g., 'street_address')
    String? locationType, // Optional location type (e.g., 'ROOFTOP')
    String? components, // Optional components filter (e.g., 'country:US')
  }) async {
    try {
      // Build the API request URL with optional parameters
      final queryParameters = {
        'latlng': '$latitude,$longitude',
        'key': Config.googleMapsApiKey,
        'language': language,
        if (region != null) 'region': region,
        if (resultType != null) 'result_type': resultType,
        if (locationType != null) 'location_type': locationType,
        if (components != null) 'components': components,
      };

      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        queryParameters,
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final result = data['results'][0];
          final address = result['formatted_address'] ?? 'Unknown location';
          String city = 'Unknown City';

          // Extract the city from the address components
          for (var component in result['address_components']) {
            if (component['types'].contains('locality')) {
              city = component['long_name'];
              break;
            }
          }

          return {
            'address': address,
            'city': city,
          };
        } else {
          // Handle specific API errors
          String errorMessage;
          switch (data['status']) {
            case 'ZERO_RESULTS':
              errorMessage = 'No results found for the given coordinates.';
              break;
            case 'OVER_QUERY_LIMIT':
              errorMessage = 'Quota exceeded. Please try again later.';
              break;
            case 'REQUEST_DENIED':
              errorMessage = 'Request denied. Check your API key and permissions.';
              break;
            case 'INVALID_REQUEST':
              errorMessage = 'Invalid request. Check the coordinates.';
              break;
            default:
              errorMessage = 'Error: ${data['status']}';
          }
          return {
            'address': errorMessage,
            'city': 'Unknown City',
          };
        }
      } else {
        return {
          'address': 'Error: HTTP ${response.statusCode}',
          'city': 'Unknown City',
        };
      }
    } catch (e) {
      return {
        'address': 'Error fetching address: $e',
        'city': 'Unknown City',
      };
    }
  }
}