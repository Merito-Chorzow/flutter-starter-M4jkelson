import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const GeoJournalApp());
}

class GeoJournalApp extends StatefulWidget {
  const GeoJournalApp({super.key});

  @override
  State<GeoJournalApp> createState() => _GeoJournalAppState();
}

class _GeoJournalAppState extends State<GeoJournalApp> {
  bool _isDark = false;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Journal',
      theme: _isDark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.teal,
            ),
      initialRoute: '/',
      routes: {
        '/': (context) => EntriesListScreen(
              isDark: _isDark,
              onToggleTheme: _toggleTheme,
            ),
        '/detail': (context) => const EntryDetailScreen(),
        '/add': (context) => const AddEntryScreen(),
        '/settings': (context) => SettingsScreen(
              isDark: _isDark,
              onToggleTheme: _toggleTheme,
            ),
      },
    );
  }
}

/// EKRAN 1 – LISTA / MAPA WPISÓW
class EntriesListScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const EntriesListScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Journal'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Przełącz motyw',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Lista wpisów (placeholder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Tutaj będzie lista z API lub mapa z pinami.',
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Przykładowy wpis #1'),
            subtitle: const Text('Kliknij, żeby zobaczyć szczegóły'),
            onTap: () {
              Navigator.pushNamed(context, '/detail', arguments: '1');
            },
          ),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Przykładowy wpis #2'),
            subtitle: const Text('Kliknij, żeby zobaczyć szczegóły'),
            onTap: () {
              Navigator.pushNamed(context, '/detail', arguments: '2');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// EKRAN 2 – SZCZEGÓŁY WPISU
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final entryId = args?.toString() ?? 'brak-id';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły wpisu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wpis ID: $entryId',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tutaj pokażesz tytuł, opis, datę i lokalizację wpisu pobraną z API.',
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Text('Lokalizacja: (lat, lng) – placeholder'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// EKRAN 3 – DODAJ WPIS z DZIAŁAJĄCYM GPS
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

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

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    // tu kiedyś podłączysz POST do API z _lat/_lng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zapisano wpis.\nLokalizacja: '
          '${_lat != null && _lng != null ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}' : 'brak'}',
        ),
      ),
    );

    Navigator.pop(context);

    setState(() {
      _saving = false;
    });
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveEntry,
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

/// EKRAN 4 – USTAWIENIA (GLOBALNY MOTYW)
class SettingsScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Tryb ciemny'),
            subtitle: const Text('Przełącz motyw aplikacji'),
            value: isDark,
            onChanged: (_) => onToggleTheme(),
          ),
          const ListTile(
            title: Text('Info o aplikacji'),
            subtitle: Text('Geo Journal – projekt zaliczeniowy Flutter'),
          ),
        ],
      ),
    );
  }
}
