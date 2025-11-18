import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 26),
                )
              ],
            ),

            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "You have "),
                  TextSpan(
                    text: "3 Notifications",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: " today."),
                ],
              ),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "Today",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            _buildNotifItem(
              name: "Elayamani",
              message: "Liked your DailyUI",
              detail: "045 - Favourites",
              time: "2 h ago",
              avatarUrl: null,
            ),

            _buildNotifItem(
              name: "Arslan Ali",
              message: "Liked your DailyUI",
              detail: "044 - Food menu",
              time: "6 h ago",
              avatarUrl: null,
            ),

            _buildNotifItem(
              name: "Johny vino",
              message: "Mentioned you in a comment",
              detail: "",
              time: "8 h ago",
              avatarUrl: null,
            ),

            const SizedBox(height: 25),
            const Text(
              "This Week",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            _buildNotifItem(
              name: "Brice Seraphin",
              message: "Liked your DailyUI",
              detail: "044 - Food menu",
              time: "6 June",
              avatarUrl: null,
            ),

            _buildNotifItem(
              name: "Best ui design",
              message: "Started following you",
              detail: "",
              time: "5 June",
              avatarUrl: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required String name,
    required String message,
    required String detail,
    required String time,
    String? avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : const AssetImage("assets/default_profile.png")
                        as ImageProvider,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "$name ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: "$message "),
                      if (detail.isNotEmpty)
                        TextSpan(
                          text: detail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          )
        ],
      ),
    );
  }
}
