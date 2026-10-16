import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}

class WeatherService {
  Future<Weather> fetchWeather(String cityName) async {
    try {
      // 1) City name -> coordinates
      final geoUrl = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=5');
      final geoRes = await http.get(geoUrl).timeout(const Duration(seconds: 10));
      if (geoRes.statusCode != 200) throw WeatherException('Search failed (${geoRes.statusCode})');

      final geoJson = jsonDecode(geoRes.body);
      final results = geoJson['results'] as List?;
      if (results == null || results.isEmpty) {
        throw WeatherException('City "$cityName" not found');
      }
      final place = results.first;

      // 2) Coordinates -> weather + 7-day forecast
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=${place['latitude']}&longitude=${place['longitude']}'
            '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
            'is_day,precipitation,weather_code,wind_speed_10m'
            '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_probability_max'
            '&temperature_unit=celsius&wind_speed_unit=kmh'
            '&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw WeatherException('Server error (${res.statusCode})');

      return Weather.fromJson(
          jsonDecode(res.body), place['name'], place['country'] ?? '');
    } on SocketException {
      throw WeatherException('No internet connection');
    } on http.ClientException {
      throw WeatherException('Network error. Please try again');
    } on FormatException {
      throw WeatherException('Bad data received from server');
    }
    // TimeoutException falls through to the UI as a generic error
  }
}