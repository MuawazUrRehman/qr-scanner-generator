import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_scanner/features/batch/batch_service.dart';
import 'package:qr_scanner/features/result/result_screen.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batchService = BatchService();

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
        title: const Text('Batch Results', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: "Clear All",
            onPressed: () {
               showDialog(context: context, builder: (ctx) => AlertDialog(
                 backgroundColor: Theme.of(context).cardColor,
                 title: const Text("Clear Batch?"),
                 content: const Text("This will remove all scanned items."),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                   TextButton(onPressed: () {
                      batchService.clearAll();
                      Navigator.pop(ctx);
                   }, child: const Text("Clear", style: TextStyle(color: Colors.red))),
                 ],
               ));
            },
          )
        ],
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: batchService.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.layers_clear, size: 80, color: Colors.grey.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text("No items scanned", style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final items = box.values.toList().reversed.toList(); // Newest first

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map;
              final code = item['code'] ?? '';
              final type = item['type'] ?? 'Text';

              return Dismissible(
                key: Key(code + index.toString()),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                   // Calculate original index since we reversed the list
                   // Original list: [0, 1, 2] -> Reversed: [2, 1, 0]
                   // If we delete index 0 (which is 2), we deleteAt(2).
                   // The index from builder is 'index'.
                   // So original index = (length - 1) - index.
                   int realIndex = (box.length - 1) - index;
                   batchService.deleteAt(realIndex);
                   
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted")));
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForType(type),
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text(
                      type,
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
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(code: code, onClose: () {}),
                        ),
                      );
                    },
                  ),
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
