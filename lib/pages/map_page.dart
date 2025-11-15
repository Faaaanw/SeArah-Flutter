import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  final String locationName;
  final double latitude;
  final double longitude;

  const MapPage({
    super.key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.jpg?key=nkV8u6JfP6d8DPcFsYJe',
                additionalOptions: {'key': 'nkV8u6JfP6d8DPcFsYJe'},
                userAgentPackageName: 'com.searah.app',
                tileSize: 256,
                minZoom: 15,
                maxZoom: 18,
                keepBuffer: 2,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                locationName,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
