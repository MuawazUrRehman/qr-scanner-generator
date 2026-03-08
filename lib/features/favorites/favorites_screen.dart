import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_scanner/features/favorites/favorites_service.dart';
import 'package:qr_scanner/features/result/result_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "Clear Favorites",
            onPressed: () {
              if (favoritesService.getFavorites().isEmpty) return;

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: const Text('Clear Favorites'),
                  content: const Text(
                      'Are you sure you want to remove all favorites?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    TextButton(
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await favoritesService.clearAllFavorites();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: favoritesService.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No favorites yet",
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final items = box.values.toList();
          items.sort((a, b) {
            final tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA); // Descending (Newest first)
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map;
              final code = item['code'] ?? '';
              final type = item['type'] ?? 'Text';
              final customName = item['customName'] as String?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: Colors.redAccent,
                    ),
                  ),
                  title: Text(
                    customName ?? type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: "Unfavorite",
                    onPressed: () {
                      favoritesService.toggleFavorite(code, type);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Removed from Favorites"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultScreen(code: code, onClose: () {}),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type == 'Website') return Icons.public;
    if (type == 'WiFi Network') return Icons.wifi;
    if (type == 'Phone Number') return Icons.phone;
    if (type == 'Email') return Icons.email;
    return Icons.qr_code_2;
  }
}
