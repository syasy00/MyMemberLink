import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/views/products/product_screen.dart';
import 'package:my_member_link/views/news%20/main_screen.dart';
import 'package:my_member_link/views/authentication%20/login_screen.dart';
import 'package:my_member_link/views/events%20/event_screen.dart';
import 'package:my_member_link/views/subscription/subscription_screen.dart';

class MyDrawer extends StatefulWidget {
  final String activePage; // Pass the active page name as a parameter

  const MyDrawer({super.key, required this.activePage});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String username = "User";
  String userEmail = "user@example.com";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "User";
      userEmail = prefs.getString('useremail') ?? "user@example.com";
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0E0E0),
                  child: const Icon(Icons.person, size: 28, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E0E0)),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: "Home",
                  isSelected: widget.activePage == "Home",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_outlined,
                  title: "Events",
                  isSelected: widget.activePage == "Events",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EventScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.group_outlined,
                  title: "Members",
                  isSelected: widget.activePage == "Members",
                  onTap: () {
                    // Define action for Members
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  title: "Products",
                  isSelected: widget.activePage == "Products",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductListScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment_outlined,
                  title: "Payments",
                  isSelected: widget.activePage == "Payments",
                  onTap: () {
                    // Define action for Payments
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_outlined,
                  title: "Subscription",
                  isSelected: widget.activePage == "Subscription",
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (widget.activePage != "Subscription") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionScreen(),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  isSelected: widget.activePage == "Settings",
                  onTap: () {
                    // Define action for Settings
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E0E0)),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required Function() onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : const Color(0xFF5A9BE7),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue : const Color(0xFF333333),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
