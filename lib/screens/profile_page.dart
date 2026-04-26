import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          /// FOTO PROFIL
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueGrey,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fayyaz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Daily Budget User',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// DARK MODE
          Card(
            child: SwitchListTile(
              value: isDark,
              title: const Text('Dark Mode'),
              subtitle: const Text('Aktifkan mode gelap'),
              onChanged: (value) {
                isDarkMode.value = value;
              },
            ),
          ),

          /// ABOUT
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              subtitle: const Text('Daibudge v1.0'),
            ),
          ),

          /// LOGOUT (optional)
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}