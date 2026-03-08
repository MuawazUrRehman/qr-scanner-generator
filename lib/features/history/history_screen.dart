import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_scanner/features/history/history_service.dart';
import 'package:qr_scanner/features/result/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<HistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _historyService.getHistory();
    });
  }

  IconData _getIconForType(String typeTitle) {
    switch (typeTitle) {
      case 'Website':
        return Icons.language;
      case 'WiFi Network':
        return Icons.wifi;
      case 'Contact':
        return Icons.person_outline;
      case 'SMS Message':
        return Icons.sms_outlined;
      case 'Phone Number':
        return Icons.phone_outlined;
      case 'Email':
        return Icons.email_outlined;
      case 'Location':
        return Icons.location_on_outlined;
      case 'Calendar Event':
        return Icons.calendar_today;
      case 'WhatsApp':
        return Icons.chat_bubble_outline;
      case 'Skype':
        return Icons.video_call_outlined;
      case 'FaceTime':
        return Icons.video_camera_front_outlined;
      case 'PayPal':
        return Icons.payment;
      case 'Bitcoin':
        return Icons.currency_bitcoin;
      case 'Ethereum':
        return Icons.currency_exchange;
      case 'Instagram':
        return Icons.camera_alt_outlined;
      case 'Facebook':
        return Icons.facebook;
      case 'Twitter / X':
        return Icons.alternate_email;
      case 'YouTube':
        return Icons.play_circle_outline;
      case 'TikTok':
        return Icons.music_note;
      case 'Google Play Store':
        return Icons.shop;
      case 'Apple App Store':
        return Icons.apple;
      default:
        return Icons.qr_code;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: "Clear History",
            onPressed: () async {
              // Show confirmation dialog before clearing
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: const Text('Clear History'),
                  content: const Text(
                    'Are you sure you want to delete all scans?',
                  ),
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
                        await _historyService.clearHistory();
                        _refreshHistory();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No scan history yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data!;

          // Sort just in case, though usually sorted by insert
          // history.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length + _calculateHeaderCount(history),
            itemBuilder: (context, index) {
              final itemOrHeader = _getItemWithHeaders(history, index);

              if (itemOrHeader is String) {
                // Header
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                  child: Text(
                    itemOrHeader,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final item = itemOrHeader as HistoryModel;
              final icon = _getIconForType(item.type);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(item.date.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  onDismissed: (direction) async {
                    // We need to find the REAL index in the original list
                    final realIndex = history.indexOf(item);
                    await _historyService.deleteItem(realIndex);
                    _refreshHistory();
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(
                            code: item.code,
                            onClose: () {
                              _refreshHistory();
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon Container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.purple.shade300,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.customName ?? item.type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('h:mm a').format(item.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _calculateHeaderCount(List<HistoryModel> history) {
    int count = 0;
    String? lastHeader;
    for (var item in history) {
      final header = _getDateHeader(item.date);
      if (header != lastHeader) {
        count++;
        lastHeader = header;
      }
    }
    return count;
  }

  dynamic _getItemWithHeaders(List<HistoryModel> history, int index) {
    int currentIndex = 0;
    String? lastHeader;

    for (var item in history) {
      final header = _getDateHeader(item.date);
      if (header != lastHeader) {
        if (currentIndex == index) return header;
        lastHeader = header;
        currentIndex++;
      }

      if (currentIndex == index) return item;
      currentIndex++;
    }
    return history.last; // Fallback
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return "Today";
    if (itemDate == yesterday) return "Yesterday";
    return DateFormat("MMMM d, y").format(date);
  }
}
