import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/views/main_screen.dart';
import 'package:my_member_link/views/login_screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String username = "User"; // Default username
  String userEmail = "user@example.com"; // Default email

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "User"; // Fetch username
      userEmail =
          prefs.getString('useremail') ?? "user@example.com"; // Fetch email
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored user data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF5A9BE7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      const AssetImage('assets/user.jpg'), // Placeholder image
                ),
                const SizedBox(height: 15),
                Text(
                  "Welcome, $username!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.article_outlined,
                  title: "Newsletter",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_outlined,
                  title: "Events",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.group_outlined,
                  title: "Members",
                  onTap: () {
                    // Define action for Members
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment_outlined,
                  title: "Payments",
                  onTap: () {
                    // Define action for Payments
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  title: "Products",
                  onTap: () {
                    // Define action for Products
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.check_circle_outline,
                  title: "Vetting",
                  onTap: () {
                    // Define action for Vetting
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    // Define action for Settings
                  },
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[300]),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required Function() onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF5A9BE7), // Matching theme color
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      onTap: onTap,
    );
  }
}
