import 'package:flutter/material.dart';
import 'database/tables/event_tabel.dart';
import 'models/event_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Demo',
      home: EventPage(),
    );
  }
}

class EventPage extends StatefulWidget {
  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final eventTable = EventTable();
  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final data = await eventTable.getAllEvents();
    setState(() => events = data);
  }

  Future<void> _addEvent() async {
    final event = Event(
      creatorId: 1,
      title: 'Nongkrong di Cianjur',
      description: 'Ngopi bareng teman lama',
      locationName: 'Kopi Janji Jiwa',
      latitude: -6.8166,
      longitude: 107.1423,
      startTime: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await eventTable.insertEvent(event);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Event')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];
          return ListTile(
            title: Text(e.title),
            subtitle: Text(e.locationName),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
     ),
);
}
}