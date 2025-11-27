import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/home_viewmodel.dart';
import 'dart:async';

// --- Konstanta Warna & Font ---
const Color _kPrimaryColor = Color(0xFFFF9467);
const Color _kAccentColor = Color(0xFFE9446D);
const String _kPoppinsFontFamily = 'Poppins';

// ============================================================================
// 1. HALAMAN CREATE EVENT (FORM)
// ============================================================================

class CreateEventPage extends StatefulWidget {
  final int groupId;

  const CreateEventPage({
    super.key,
    required this.groupId,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final titleC = TextEditingController();
  final descC = TextEditingController();

  // State untuk Lokasi
  LatLng? _selectedLocation;
  String _selectedAddress = "Belum ada lokasi dipilih";

  DateTime? startTime;
  DateTime? endTime;

  String get _formattedStartTime => startTime == null
      ? "Pilih Waktu Mulai"
      : DateFormat('dd MMM yyyy HH:mm').format(startTime!);

  String get _formattedEndTime => endTime == null
      ? "Pilih Waktu Selesai"
      : DateFormat('dd MMM yyyy HH:mm').format(endTime!);

  // --- Fungsi Navigasi ke Map Picker ---
  Future<void> _openLocationPicker() async {
    // Buka halaman peta untuk memilih lokasi
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerPage(),
      ),
    );

    // Jika user kembali membawa data (Map<String, dynamic>)
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLocation = result['latlng'] as LatLng;
        _selectedAddress = result['address'] as String;
      });
    }
  }

  // --- Fungsi Date Picker ---
  Future<void> _pickDateTime(bool isStart) async {
    final initialDate =
        isStart ? DateTime.now() : (startTime ?? DateTime.now());
    final firstDate = isStart ? DateTime.now() : (startTime ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      final selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );

      if (isStart) {
        startTime = selectedDateTime;
      } else {
        endTime = selectedDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Event",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontFamily: _kPoppinsFontFamily)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
            color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Input Title ---
            _buildTextField(titleC, "Event Title", Icons.celebration),
            const SizedBox(height: 16),

            // --- Input Description ---
            _buildTextField(descC, "Description (Opsional)", Icons.description),

            const SizedBox(height: 24),

            // --- Location Picker Button (Modified) ---
            _buildLocationPickerTrigger(context),

            const SizedBox(height: 24),

            // --- Date/Time Pickers ---
            Text("Event Schedule",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: _kPoppinsFontFamily)),
            const SizedBox(height: 12),

            _buildTimePickerButton("Start Time", _formattedStartTime, true),
            const SizedBox(height: 12),
            _buildTimePickerButton("End Time", _formattedEndTime, false),

            const SizedBox(height: 40),

            // --- Create Event Button ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Validasi Input
                if (titleC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title wajib diisi')));
                  return;
                }
                if (_selectedLocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lokasi wajib dipilih')));
                  return;
                }
                if (startTime != null &&
                    endTime != null &&
                    endTime!.isBefore(startTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Waktu Selesai harus setelah Waktu Mulai')));
                  return;
                }

                final start =
                    startTime ?? DateTime.now().add(const Duration(hours: 1));
                final end =
                    endTime ?? DateTime.now().add(const Duration(hours: 2));

                try {
                  // Panggil ViewModel untuk create event
                  final event = await vm.createEvent(
                    groupId: widget.groupId,
                    title: titleC.text,
                    description: descC.text.isEmpty ? null : descC.text,
                    startTime: start,
                    endTime: end,
                    latitude: _selectedLocation!.latitude,
                    longitude: _selectedLocation!.longitude,
                    locationName: _selectedAddress,
                  );

                  vm.setCurrentEvent(event);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuat event: $e')),
                    );
                  }
                }
              },
              child: const Text("Create Event",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: _kPoppinsFontFamily)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget TextField Standar ---
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Container(
      // 1. Shadow dan Border Radius dipindahkan ke Container
      decoration: BoxDecoration(
        color:
            Colors.white, // Background putih wajib ada agar shadow tidak tembus
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Opacity disesuaikan
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: _kPoppinsFontFamily),
          prefixIcon: Icon(icon, color: _kPrimaryColor),

          // 2. Hilangkan border bawaan TextFormField agar tidak menumpuk
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,

          // Tambahkan padding agar teks tidak terlalu mepet ke pinggir container
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontFamily: _kPoppinsFontFamily),
        maxLines: label.contains("Description") ? 3 : 1,
      ),
    );
  }

  // --- Widget Pemicu Map Picker ---
  Widget _buildLocationPickerTrigger(BuildContext context) {
    return InkWell(
      onTap: _openLocationPicker, // Buka halaman map
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: _kAccentColor, size: 24),
                      const SizedBox(width: 8),
                      Text("Event Location",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: _kPoppinsFontFamily)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              const Divider(height: 20),
              // Tampilkan Lokasi yang dipilih
              Text(
                _selectedAddress,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: _selectedLocation == null
                        ? Colors.grey
                        : _kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kPoppinsFontFamily),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (_selectedLocation != null)
                Text(
                  "Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lon: ${_selectedLocation!.longitude.toStringAsFixed(5)}",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey.shade600,
                      fontFamily: _kPoppinsFontFamily),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(String label, String value, bool isStart) {
    return InkWell(
      onTap: () => _pickDateTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(isStart ? Icons.play_arrow : Icons.stop, color: _kAccentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                          fontFamily: _kPoppinsFontFamily)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontWeight: value.contains("Pilih")
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: value.contains("Pilih")
                              ? Colors.grey
                              : Colors.black87,
                          fontFamily: _kPoppinsFontFamily)),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar, color: _kPrimaryColor),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. HALAMAN LOCATION PICKER (MAP & SEARCH)
// ============================================================================

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _localSearchController = TextEditingController();

  // --- LOCAL STATE (Agar tidak ganggu Home Page) ---
  List<dynamic> _localSearchResults = [];
  bool _isLocalSearching = false;
  Timer? _debounceTimer; // Timer lokal

  LatLng _pickedLocation = const LatLng(-6.175392, 106.827153);
  String _pickedAddress = "Pinned Location";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HomeViewModel>();
      // Kita set lokasi awal map sesuai user location
      if (vm.userLocation.latitude != 0) {
        setState(() {
          _pickedLocation = vm.userLocation;
        });
        _mapController.move(_pickedLocation, 15);
      }
    });
  }

  @override
  void dispose() {
    _localSearchController.dispose();
    _mapController.dispose();
    _debounceTimer?.cancel(); // Matikan timer saat keluar
    super.dispose();
  }

  // --- LOGIC PENCARIAN LOKAL ---
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.isEmpty) {
      setState(() {
        _localSearchResults = [];
        _isLocalSearching = false;
      });
      return;
    }

    // Debounce 400ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLocalSearching = true);

      // Panggil fungsi BARU di ViewModel yang tidak mengubah state global
      final vm = context.read<HomeViewModel>();
      final results = await vm.searchLocationDirectly(query);

      if (mounted) {
        setState(() {
          _localSearchResults = results;
          _isLocalSearching = false;
        });
      }
    });
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
      _pickedAddress = "Lokasi Terpilih";
      _localSearchController.clear();
      _localSearchResults = []; // Bersihkan list lokal
    });
    FocusScope.of(context).unfocus();
  }

  void _selectSearchResult(Map<String, dynamic> locationData) {
    final lat = double.tryParse(locationData['lat'] ?? '0') ?? 0.0;
    final lon = double.tryParse(locationData['lon'] ?? '0') ?? 0.0;
    final displayName = locationData['display_name'] ?? 'Unknown Location';

    setState(() {
      _pickedLocation = LatLng(lat, lon);
      _pickedAddress = displayName;
      _localSearchController.text = displayName;
      _localSearchResults = []; // Bersihkan list lokal
    });

    _mapController.move(_pickedLocation, 16);
    FocusScope.of(context).unfocus();
  }

  // Hapus PopScope dan clearSearchResults() karena kita sudah pakai state lokal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. Map Layer (TIDAK BERUBAH) ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.jpg?key=nkV8u6JfP6d8DPcFsYJe',
                additionalOptions: const {'key': 'nkV8u6JfP6d8DPcFsYJe'},
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on,
                        color: _kAccentColor, size: 50),
                  ),
                ],
              ),
            ],
          ),

          // --- 2. GABUNGAN SEARCH BAR & BACK BUTTON ---
          Positioned(
            top: 50, // Jarak dari atas (Safe Area)
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Container Putih Utama
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30), // Bentuk Capsule
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      // A. Tombol Back (Di dalam Container yang sama)
                      IconButton(
                        padding: const EdgeInsets.only(left: 8),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // B. Input Search
                      Expanded(
                        child: TextField(
                          controller: _localSearchController,
                          decoration: InputDecoration(
                            hintText: "Cari lokasi...",
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontFamily: _kPoppinsFontFamily),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                            // Tombol Clear (X)
                            suffixIcon: _localSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey),
                                    onPressed: () {
                                      _localSearchController.clear();
                                      setState(() => _localSearchResults = []);
                                    },
                                  )
                                : const Icon(Icons.search,
                                    color:
                                        _kPrimaryColor), // Icon search di kanan
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- LOADING LOCAL ---
                if (_isLocalSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 10, right: 10),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      color: _kPrimaryColor,
                      backgroundColor: Colors.white,
                    ),
                  ),

                // --- LIST SUGGESTION LOKAL ---
                if (_localSearchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5)
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _localSearchResults.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (ctx, i) {
                        final item = _localSearchResults[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              size: 20, color: Colors.grey),
                          title: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontFamily: _kPoppinsFontFamily),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  )
              ],
            ),
          ),

          // --- 3. Confirm Button (Tetap di Bawah) ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'latlng': _pickedLocation,
                  'address': _pickedAddress,
                });
              },
              child: const Text("Pilih Lokasi Ini",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: _kPoppinsFontFamily)),
            ),
          ),
        ],
      ),
    );
  }
}
