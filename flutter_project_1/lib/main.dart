import 'package:flutter/material.dart';

void main() {
  runApp(const GeoJournalApp());
}

class GeoJournalApp extends StatelessWidget {
  const GeoJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Journal',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      // domyślnie lista wpisów
      initialRoute: '/',
      routes: {
        '/': (context) => const EntriesListScreen(),
        '/detail': (context) => const EntryDetailScreen(),
        '/add': (context) => const AddEntryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

/// EKRAN 1 – LISTA / MAPA WPISÓW
class EntriesListScreen extends StatelessWidget {
  const EntriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // tu później podłączysz API (lista wpisów) i/lub mapę
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Journal'),
        actions: [
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
          // kilka przykładowych itemów do kliknięcia
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Przykładowy wpis #1'),
            subtitle: const Text('Kliknij, żeby zobaczyć szczegóły'),
            onTap: () {
              // docelowo przekażesz ID wpisu
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
    // docelowo dostaniesz tutaj ID przez arguments
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

/// EKRAN 3 – DODAJ WPIS
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: tu później wyślesz POST do API + pobierzesz lokalizację
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zapisano (na razie tylko lokalnie)')),
    );

    Navigator.pop(context); // cofka do listy
  }

  void _getLocation() {
    // TODO: tu później wywołasz natywną funkcję (geolocator)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pobieranie lokalizacji (placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj wpis'),
      ),
      body: Padding(
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
                        const Expanded(
                          child: Text('Lokalizacja: (jeszcze nie ustawiona)'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _getLocation,
                          icon: const Icon(Icons.my_location),
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
                onPressed: _saveEntry,
                child: const Text('Zapisz wpis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EKRAN 4 – USTAWIENIA
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false; // na razie lokalny przełącznik – placeholder

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
            subtitle: const Text('Na razie tylko przykład przełącznika'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // TODO: podłącz prawdziwe przełączanie motywu w GeoJournalApp
            },
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
