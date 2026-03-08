import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner/features/favorites/favorites_screen.dart';
import 'package:qr_scanner/features/settings/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.purple.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, "Appearance"),
              _buildSwitchTile(
                "Dark mode",
                settings.isDarkMode,
                (val) => settings.toggleTheme(val),
              ),
              const Divider(),

              _buildSectionHeader(context, "Scanner"),
              _buildSwitchTile(
                "Vibrate",
                settings.vibrate,
                (val) => settings.setVibrate(val),
              ),
              _buildSwitchTile(
                "Sound",
                settings.sound,
                (val) => settings.setSound(val),
              ),
              _buildSwitchTile(
                "Auto-copy to clipboard",
                settings.autoCopy,
                (val) => settings.setAutoCopy(val),
              ),
              _buildSwitchTile(
                "Open websites automatically",
                settings.openWeb,
                (val) => settings.setOpenWeb(val),
              ),
              _buildSwitchTile(
                "Batch Scan",
                settings.batchScan,
                (val) => settings.setBatchScan(val),
              ),
              _buildSwitchTile(
                "Add to History",
                settings.addToHistory,
                (val) => settings.setAddToHistory(val),
              ),
              const Divider(),

              _buildSectionHeader(
                context,
                "Favorites",
              ), // As per image request, keeping "Search" title or changing logic? User said "search wala card... isma tum na aik favrorite wala text likhna"
              // User request: "search wala card... isma tum na aik favrorite wala text likhna or oska neecha language wala"
              // The header in image is "Search". User wants to repurpose it or just use that section style.
              // I will stick to the visual style but maybe the content requested.
              ListTile(
                title: const Text("Favorites", style: TextStyle(fontSize: 16)),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              // _buildSimpleTile(context, "Language"),
              const Divider(),

              _buildSectionHeader(context, "Information"),
              _buildIconTile(context, Icons.privacy_tip, "Privacy policy"),
              _buildIconTile(context, Icons.share, "Recommend this app"),
              _buildIconTile(
                context,
                Icons.edit,
                "Error, feedback or suggestion?",
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor:
          Colors.purple.shade800, // Matches the image's greenish/teal toggle
    );
  }

  Widget _buildSimpleTile(BuildContext context, String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // Placeholder for future nav
      },
    );
  }

  Widget _buildIconTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // Placeholder
      },
    );
  }
}
