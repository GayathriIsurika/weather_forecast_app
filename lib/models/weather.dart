class DailyForecast {
  final DateTime date;
  final int code;
  final double maxTemp;
  final double minTemp;

  DailyForecast(this.date, this.code, this.maxTemp, this.minTemp);
}

class Weather {
  final String city;
  final String country;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double wind;
  final int code;
  final String updatedAt;
  final List<DailyForecast> daily;

  Weather({
    required this.city,
    required this.country,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.updatedAt,
    required this.daily,
  });

  factory Weather.fromJson(Map<String, dynamic> json, String city, String country) {
    final c = json['current'];
    final d = json['daily'];
    final days = <DailyForecast>[];
    for (int i = 0; i < (d['time'] as List).length; i++) {
      days.add(DailyForecast(
        DateTime.parse(d['time'][i]),
        d['weather_code'][i],
        (d['temperature_2m_max'][i] as num).toDouble(),
        (d['temperature_2m_min'][i] as num).toDouble(),
      ));
    }
    return Weather(
      city: city,
      country: country,
      temp: (c['temperature_2m'] as num).toDouble(),
      feelsLike: (c['apparent_temperature'] as num).toDouble(),
      humidity: c['relative_humidity_2m'],
      wind: (c['wind_speed_10m'] as num).toDouble(),
      code: c['weather_code'],
      updatedAt: c['time'],
      daily: days,
    );
  }
}

/// Converts Open-Meteo weather codes to a label and emoji.
(String, String) describeCode(int code) {
  if (code == 0) return ('Clear sky', '☀️');
  if (code <= 3) return ('Partly cloudy', '⛅');
  if (code == 45 || code == 48) return ('Fog', '🌫️');
  if (code >= 51 && code <= 57) return ('Drizzle', '🌦️');
  if (code >= 61 && code <= 67) return ('Rain', '🌧️');
  if (code >= 71 && code <= 77) return ('Snow', '❄️');
  if (code >= 80 && code <= 82) return ('Rain showers', '🌧️');
  if (code >= 95) return ('Thunderstorm', '⛈️');
  return ('Unknown', '🌡️');
}