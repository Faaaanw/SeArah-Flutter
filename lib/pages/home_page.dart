import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import '../database/tables/event_tabel.dart';
import '../database/tables/friendship_tabel.dart';
import '../models/event_model.dart';
import '../models/friendship_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _position;
  int _batteryLevel = 0;
  List<Friendship> _friends = [];
  List<Event> _events = [];

  final battery = Battery();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getLocation();
    await _getBatteryLevel();
    await _loadFriends();
    await _loadEvents();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _position = pos);
  }

  Future<void> _getBatteryLevel() async {
    final level = await battery.batteryLevel;
    setState(() => _batteryLevel = level);
  }

  Future<void> _loadFriends() async {
    final friendshipTable = FriendshipTable();
    final list = await friendshipTable.getAll();
    setState(
        () => _friends = list.where((f) => f.status == "accepted").toList());
  }

  Future<void> _loadEvents() async {
    final eventTable = EventTable();
    final list = await eventTable.getAllEvents();
    setState(() => _events = list);
  }

  @override
  Widget build(BuildContext context) {
    final hasFriends = _friends.isNotEmpty;
    final hasEvent = _events.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMap(),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: _buildSearchBar(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCard(hasFriends, hasEvent),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildMap() {
    final userLatLng = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : LatLng(-6.817, 107.142); // default Cianjur

    return FlutterMap(
      options: MapOptions(center: userLatLng, zoom: 15),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: userLatLng,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.orange,
                size: 40,
              ),
            ),
            ..._friends.map(
              (f) => Marker(
                point: LatLng(
                    -6.82 + f.friendId * 0.001, 107.14), // dummy posisi teman
                width: 35,
                height: 35,
                child: const Icon(
                  Icons.person,
                  color: Colors.deepOrange,
                  size: 35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFA8C60).withOpacity(0.3), blurRadius: 6)
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Color(0xFFFA8C60)),
          SizedBox(width: 8),
          Text('Search Location',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          Spacer(),
          Icon(Icons.people, color: Color(0xFFFA8C60)),
        ],
      ),
    );
  }

  Widget _buildBottomCard(bool hasFriends, bool hasEvent) {
    if (!hasFriends) {
      // 👤 Mode belum ada teman
      return _noFriendsCard();
    } else if (hasEvent) {
      // 📅 Mode ada event
      return _eventCard(_events.first);
    } else {
      // 👥 Mode sudah ada teman
      return _friendsListCard();
    }
  }

  Widget _noFriendsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/world_connect1.png', height: 120),
          const SizedBox(height: 10),
          const Text(
            "You're not connected with your friend yet",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA8C60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Text('Connect Now', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendsListCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Your Friend's",
            style: TextStyle(
                color: Color(0xFFFA8C60),
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._friends.map(
            (f) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFA8C60),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('User ${f.friendId}'),
              subtitle: Text('Location sharing: ${f.shareType}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.battery_std, color: Color(0xFFFA8C60), size: 20),
                  Text(' $_batteryLevel%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Event event) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFA8C60))),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFFFA8C60)),
              const SizedBox(width: 6),
              Text(event.startTime),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFA8C60)),
              const SizedBox(width: 6),
              Text(event.locationName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(255, 255, 250, 248),
      selectedItemColor: const Color(0xFFFA8C60),
      unselectedItemColor: const Color(0xFFFA8C60),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}
