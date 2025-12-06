import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const GeoJournalApp());
}

/// MODEL

class JournalEntry {
  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  JournalEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// API SERVICE

class JournalApiService {
  // Android emulator
  static const String baseUrl = 'http://10.0.2.2:3000';
  // iOS/web/desktop: 'http://localhost:3000';

  final http.Client _client;

  JournalApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<JournalEntry>> fetchEntries() async {
    final uri = Uri.parse('$baseUrl/entries?_sort=createdAt&_order=desc');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania wpisów: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => JournalEntry.fromJson(e)).toList();
  }

  Future<JournalEntry> fetchEntryById(int id) async {
    final uri = Uri.parse('$baseUrl/entries/$id');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania wpisu: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return JournalEntry.fromJson(data);
  }

  Future<JournalEntry> createEntry({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/entries');
    final body = jsonEncode({
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Błąd zapisu wpisu: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return JournalEntry.fromJson(data);
  }

  Future<void> deleteEntry(int id) async {
    final uri = Uri.parse('$baseUrl/entries/$id');
    final response = await _client.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Błąd usuwania wpisu: ${response.statusCode}');
    }
  }
}

/// ROOT APP – z ThemeMode

class GeoJournalApp extends StatefulWidget {
  const GeoJournalApp({super.key});

  @override
  State<GeoJournalApp> createState() => _GeoJournalAppState();
}

class _GeoJournalAppState extends State<GeoJournalApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _api = JournalApiService();

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Journal',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      routes: {
        '/': (context) => EntriesListScreen(
              api: _api,
              toggleTheme: _toggleTheme,
              themeMode: _themeMode,
            ),
        '/add': (context) => AddEntryScreen(api: _api),
      },
      onGenerateRoute: (settings) {
        if (settings.name == EntryDetailScreen.routeName) {
          final entryId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => EntryDetailScreen(
              api: _api,
              entryId: entryId,
            ),
          );
        }
        return null;
      },
    );
  }
}

/// SCREEN 1 – LISTA WPISÓW (z usuwaniem)

class EntriesListScreen extends StatefulWidget {
  final JournalApiService api;
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const EntriesListScreen({
    super.key,
    required this.api,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<EntriesListScreen> createState() => _EntriesListScreenState();
}

class _EntriesListScreenState extends State<EntriesListScreen> {
  late Future<List<JournalEntry>> _futureEntries;

  @override
  void initState() {
    super.initState();
    _futureEntries = widget.api.fetchEntries();
  }

  void _reload() {
    setState(() {
      _futureEntries = widget.api.fetchEntries();
    });
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result == true) {
      _reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano nowy wpis')),
        );
      }
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń wpis'),
        content: Text('Na pewno chcesz usunąć "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteEntry(entry.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wpis usunięty')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Journal'),
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Przełącz motyw',
          ),
        ],
      ),
      body: FutureBuilder<List<JournalEntry>>(
        future: _futureEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Coś poszło nie tak 😅'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Brak wpisów',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Dodaj pierwszy wpis przyciskiem "+" na dole.'),
                ],
              ),
            );
          }

          final entries = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
            },
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = entries[index];
                final d = e.createdAt.toLocal();
                final dateStr =
                    '${d.day.toString().padLeft(2, '0')}.'
                    '${d.month.toString().padLeft(2, '0')}.'
                    '${d.year} '
                    '${d.hour.toString().padLeft(2, '0')}:'
                    '${d.minute.toString().padLeft(2, '0')}';

                final hasLocation = e.latitude != null && e.longitude != null;

                return ListTile(
                  title: Text(e.title),
                  subtitle: Text(
                    '$dateStr${hasLocation ? ' · (${e.latitude!.toStringAsFixed(4)}, ${e.longitude!.toStringAsFixed(4)})' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(e),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      EntryDetailScreen.routeName,
                      arguments: e.id,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// SCREEN 2 – SZCZEGÓŁY

class EntryDetailScreen extends StatefulWidget {
  static const String routeName = '/detail';

  final JournalApiService api;
  final int entryId;

  const EntryDetailScreen({
    super.key,
    required this.api,
    required this.entryId,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late Future<JournalEntry> _futureEntry;

  @override
  void initState() {
    super.initState();
    _futureEntry = widget.api.fetchEntryById(widget.entryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły wpisu'),
      ),
      body: FutureBuilder<JournalEntry>(
        future: _futureEntry,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nie udało się pobrać wpisu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Brak danych wpisu'));
          }

          final entry = snapshot.data!;
          final d = entry.createdAt.toLocal();
          final dateStr =
              '${d.day.toString().padLeft(2, '0')}.'
              '${d.month.toString().padLeft(2, '0')}.'
              '${d.year} '
              '${d.hour.toString().padLeft(2, '0')}:'
              '${d.minute.toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (entry.latitude != null && entry.longitude != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text(
                        'Lokacja: ${entry.latitude!.toStringAsFixed(5)}, ${entry.longitude!.toStringAsFixed(5)}',
                      ),
                    ],
                  )
                else
                  const Text('Brak zapisanej lokalizacji'),
                const SizedBox(height: 24),
                Text(
                  entry.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// SCREEN 3 – DODAJ WPIS (GPS)

class AddEntryScreen extends StatefulWidget {
  final JournalApiService api;

  const AddEntryScreen({super.key, required this.api});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _saving = false;
  bool _locLoading = false;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _locLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS jest wyłączony')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brak uprawnień do lokalizacji')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania lokalizacji: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.api.createEntry(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        latitude: _lat,
        longitude: _lng,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać wpisu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locText = _lat != null && _lng != null
        ? 'Lokalizacja: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
        : 'Lokalizacja nie ustawiona';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj wpis'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tytuł',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Podaj tytuł';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Opis',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Podaj opis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text(locText)),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _locLoading ? null : _getLocation,
                            icon: _locLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location),
                            label: const Text('Pobierz lokalizację'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Zapisz wpis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
