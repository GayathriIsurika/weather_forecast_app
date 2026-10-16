import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _service = WeatherService();

  Timer? _timer;
  String _lastCity = 'Colombo';

  Weather? _weather;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search(_lastCity);
    // Auto-refresh every 10 minutes (silent: no spinner)
    _timer = Timer.periodic(
      const Duration(minutes: 10),
          (_) => _search(_lastCity, silent: true),
    );
  }

  // Refresh when the app comes back to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _search(_lastCity, silent: true);
  }

  Future<void> _search(String city, {bool silent = false}) async {
    if (city.trim().isEmpty) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final w = await _service.fetchWeather(city.trim());
      if (!mounted) return;
      setState(() {
        _weather = w;
        _error = null;
        _lastCity = city.trim(); // remember the city
      });
    } catch (e) {
      if (!mounted) return;
      // On a silent refresh, keep showing the old data instead of an error
      if (!silent) {
        setState(() =>
        _error = e is WeatherException ? e.message : 'Something went wrong');
      }
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today Weather')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search city...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
          strokeWidth: 4,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _search(
                _controller.text.isEmpty ? _lastCity : _controller.text),
            child: const Text('Retry'),
          ),
        ]),
      );
    }

    final w = _weather;
    if (w == null) return const Center(child: Text('Search for a city'));

    final (label, icon) = describeCode(w.code);
    return RefreshIndicator(
      onRefresh: () => _search(w.city, silent: true),
      child: ListView(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('${w.city}, ${w.country}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(icon, style: const TextStyle(fontSize: 64)),
                Text('${w.temp.round()}°C',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w300)),
                Text(label, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _info(Icons.thermostat, 'Feels like',
                        '${w.feelsLike.round()}°'),
                    _info(Icons.water_drop, 'Humidity', '${w.humidity}%'),
                    _info(Icons.air, 'Wind', '${w.wind} km/h'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Updated: ${w.updatedAt.replaceFirst('T', ' ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('7-Day Forecast',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...w.daily.map(_forecastTile),
        ],
      ),
    );
  }

  Widget _info(IconData i, String label, String value) => Column(children: [
    Icon(i),
    Text(label, style: const TextStyle(fontSize: 12)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  ]);

  Widget _forecastTile(DailyForecast d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final (label, icon) = describeCode(d.code);
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 28)),
      title: Text('${days[d.date.weekday - 1]}, ${d.date.day}/${d.date.month}'),
      subtitle: Text(label),
      trailing: Text('${d.maxTemp.round()}° / ${d.minTemp.round()}°',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}