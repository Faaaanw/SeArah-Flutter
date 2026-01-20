import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A ready-to-use Flutter widget for location search using the Geoapify Autocomplete API.
///
/// Features:
/// - Debounces user input for efficient API calls.
/// - Caches results to reduce redundant requests.
/// - Filters results for a specific country (Indonesia by default).
/// - Limits the number of suggestions.
/// - Minimalistic UI, easy to integrate.
/// - Handles loading and empty states.
class GeoapifySearch extends StatefulWidget {
  /// Your Geoapify API key.
  final String apiKey;

  /// Callback function that is called when a location is selected.
  /// It returns a map containing the selected location's properties.
  final Function(Map<String, dynamic>) onItemSelected;

  const GeoapifySearch(
      {super.key, required this.apiKey, required this.onItemSelected});

  @override
  State<GeoapifySearch> createState() => _GeoapifySearchState();
}

class _GeoapifySearchState extends State<GeoapifySearch> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.isEmpty) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      if (_cache.containsKey(query)) {
        setState(() {
          _suggestions = _cache[query]!;
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
        'text': query,
        'limit': '5',
        'filter': 'countrycode:id',
        'apiKey': widget.apiKey,
      });

      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = data['features'] as List;
          final suggestions = features.map((feature) {
            return feature['properties'] as Map<String, dynamic>;
          }).toList();

          _cache[query] = suggestions;

          if (mounted) {
            setState(() {
              _suggestions = suggestions;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _suggestions = [];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search Location',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(suggestion['formatted']),
                subtitle: Text(suggestion['address_line2'] ?? ''),
                onTap: () {
                  widget.onItemSelected(suggestion);
                  // Example of how to use the selected item:
                  // 1. Update the TextField
                  _controller.text = suggestion['formatted'];
                  // 2. Clear suggestions
                  setState(() {
                    _suggestions = [];
                  });
                  // 3. Move map camera and update marker (logic should be in the parent widget)
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/*
EXAMPLE USAGE:

class MyMapPage extends StatelessWidget {
  final String geoapifyKey = "a199017186704d06bc293dc2a9368cc2"; // Your API Key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Search')),
      body: GeoapifySearch(
        apiKey: geoapifyKey,
        onItemSelected: (selection) {
          final lat = selection['lat'];
          final lon = selection['lon'];
          final displayName = selection['formatted'];

          print('Selected: $displayName ($lat, $lon)');

          // Here you would typically update your map's state:
          // - Move camera to LatLng(lat, lon)
          // - Add/update a marker at that position
        },
      ),
    );
  }
}
*/
