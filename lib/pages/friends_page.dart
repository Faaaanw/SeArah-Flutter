import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodel/friend_viewmodel.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String? token;
  int? userId;
  final friendIdController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isSearching = false;
  bool showPending = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    userId = prefs.getInt('user_id');

    if (token != null && mounted) {
      final vm = Provider.of<FriendViewModel>(context, listen: false);
      await vm.loadFriends(token!);
      pendingRequests = await vm.loadPendingRequests(token!) ?? [];
      setState(() {});
    }
  }

  Future<void> _searchByName(BuildContext context, String name) async {
    if (name.isEmpty || token == null) return;
    setState(() => isSearching = true);

    final viewModel = context.read<FriendViewModel>();
    final results = await viewModel.searchUserByName(name, token!);

    setState(() {
      searchResults = results ?? [];
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Teman Saya'),
            backgroundColor: const Color(0xFFFA8B60),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  if (token != null) {
                    await viewModel.loadFriends(token!);
                    pendingRequests =
                        await viewModel.loadPendingRequests(token!) ?? [];
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !showPending
                            ? const Color(0xFFFA8B60)
                            : Colors.grey,
                      ),
                      onPressed: () => setState(() => showPending = false),
                      child: const Text("Daftar Teman"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            showPending ? Colors.teal : Colors.grey,
                      ),
                      onPressed: () => setState(() => showPending = true),
                      child: const Text("Permintaan Masuk"),
                    ),
                  ],
                ),
              ),

              if (!showPending)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: friendIdController,
                          decoration: const InputDecoration(
                            labelText: "Masukkan ID atau Nama Teman",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFA8B60),
                            ),
                            onPressed: () async {
                              if (friendIdController.text.isEmpty) return;
                              if (userId == null || token == null) return;

                              final message = await viewModel.addFriend(
                                userId: userId!,
                                friendId:
                                    int.parse(friendIdController.text.trim()),
                                token: token!,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message ?? '')),
                              );

                              friendIdController.clear();
                            },
                            child: const Text("Cari ID"),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            onPressed: () => _searchByName(
                              context,
                              friendIdController.text.trim(),
                            ),
                            child: const Text("Cari Nama"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (isSearching) const Center(child: CircularProgressIndicator()),

              // ======= PERMINTAAN MASUK =======
              if (showPending)
                Expanded(
                  child: pendingRequests.isEmpty
                      ? const Center(child: Text("Tidak ada permintaan baru"))
                      : ListView.builder(
                          itemCount: pendingRequests.length,
                          itemBuilder: (context, index) {
                            final req = pendingRequests[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(req['from_name'] ?? 'Tanpa Nama'),
                              subtitle: Text(req['from_email'] ?? '-'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                onPressed: () async {
                                  // --- 🎯 Solusi: Tambahkan nama parameter 'friendshipId' ---
                                  final message = await viewModel.acceptFriend(
                                    friendshipId: req['id'], // DITAMBAHKAN
                                    token: token!,
                                  );
                                  // --------------------------------------------------------
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message ?? '')),
                                  );
                                  _initData();
                                },
                                child: const Text("Terima"),
                              ),
                            );
                          },
                        ),
                ),

              // ======= DAFTAR TEMAN =======
              if (!showPending)
                Expanded(
                  child: (searchResults.isNotEmpty)
                      ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFA8B60),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(user['name'] ?? 'Tanpa Nama'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFA8B60),
                                ),
                                onPressed: () async {
                                  if (userId == null || token == null) return;

                                  final message = await viewModel.addFriend(
                                    userId: userId!,
                                    friendId: user['id'],
                                    token: token!,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message ?? '')),
                                  );
                                },
                                child: const Text("Tambah"),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: viewModel.friends.length,
                          itemBuilder: (context, index) {
                            final friend = viewModel.friends[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFA8B60),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(friend['name'] ?? 'Tanpa Nama'),
                              subtitle: Text(friend['email'] ?? '-'),
                            );
                          },
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
