import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'map_page.dart';

class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _results = [];

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final results = await ApiService.searchLocation(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencari lokasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Cari lokasi...',
            border: InputBorder.none,
          ),
          onChanged: (q) {
            if (q.length > 2) _search(q);
          },
          onSubmitted: _search,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final loc = _results[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(loc['display_name'] ?? 'Unknown'),
                  onTap: () {
                    final lat = double.tryParse(loc['lat'] ?? '0') ?? 0;
                    final lon = double.tryParse(loc['lon'] ?? '0') ?? 0;
                    final name = loc['display_name'] ?? 'Lokasi tanpa nama';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPage(
                          locationName: name,
                          latitude: lat,
                          longitude: lon,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
