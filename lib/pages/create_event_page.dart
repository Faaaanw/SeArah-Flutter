import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';
import 'package:intl/intl.dart';

// Asumsi warna utama (ambil dari Sign Up button di screenshot)
const Color _kPrimaryColor = Color(0xFFFF9467);
const Color _kAccentColor = Color(0xFFE9446D); // Warna aksen yang mirip
const String _kPoppinsFontFamily =
    'Poppins'; // Asumsi Poppins sudah tersedia di assets/theme

class CreateEventPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final int groupId;

  const CreateEventPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.groupId,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final titleC = TextEditingController();
  final descC = TextEditingController();

  DateTime? startTime;
  DateTime? endTime;

  // Helper untuk memformat tanggal
  String get _formattedStartTime => startTime == null
      ? "Pilih Waktu Mulai"
      : DateFormat('dd MMM yyyy HH:mm').format(startTime!);

  String get _formattedEndTime => endTime == null
      ? "Pilih Waktu Selesai"
      : DateFormat('dd MMM yyyy HH:mm').format(endTime!);

  // --- Fungsi Picker ---

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

            // --- Location Info Card ---
            _buildLocationCard(context),

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
                if (titleC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title wajib diisi')));
                  return;
                }
                // Tambahkan validasi waktu
                if (startTime != null &&
                    endTime != null &&
                    endTime!.isBefore(startTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Waktu Selesai harus setelah Waktu Mulai')));
                  return;
                }

                // Pakai startTime dan endTime jika sudah dipilih, kalau belum default 1-2 jam dari sekarang
                final start =
                    startTime ?? DateTime.now().add(const Duration(hours: 1));
                final end =
                    endTime ?? DateTime.now().add(const Duration(hours: 2));

                try {
                  final event = await vm.createEvent(
                    groupId: widget.groupId,
                    title: titleC.text,
                    description: descC.text.isEmpty ? null : descC.text,
                    startTime: start,
                    endTime: end,
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    locationName: widget.locationName,
                  );

                  vm.setCurrentEvent(event);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuat event: $e')),
                  );
                }
              },
              child: const Text("Create Event",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: _kPoppinsFontFamily)), // Poppins
            ),
          ],
        ),
      ),
    );
  }

  // --- Custom Widgets ---

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: _kPoppinsFontFamily), // Poppins
        prefixIcon: Icon(icon, color: _kPrimaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimaryColor, width: 2),
        ),
      ),
      style: const TextStyle(
          fontFamily: _kPoppinsFontFamily), // Poppins untuk teks input
      maxLines: label.contains("Description") ? 3 : 1,
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: _kAccentColor, size: 24),
                const SizedBox(width: 8),
                Text("Event Location",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: _kPoppinsFontFamily)), // Poppins
              ],
            ),
            const Divider(height: 16),
            Text(widget.locationName,
                // FONT SIZE DARI titleLarge diubah menjadi bodyLarge
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kPoppinsFontFamily)), // Poppins
            const SizedBox(height: 8),
            Text(
                "Lat: ${widget.latitude.toStringAsFixed(6)}, Lon: ${widget.longitude.toStringAsFixed(6)}",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey.shade600,
                    fontFamily: _kPoppinsFontFamily)), // Poppins
          ],
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
                          fontFamily: _kPoppinsFontFamily)), // Poppins
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontWeight: value.contains("Pilih")
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: value.contains("Pilih")
                              ? Colors.grey
                              : Colors.black87,
                          fontFamily: _kPoppinsFontFamily)), // Poppins
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
