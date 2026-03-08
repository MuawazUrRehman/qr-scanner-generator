import 'dart:io';
import 'dart:ui' as ui;

import 'package:qr_scanner/features/favorites/favorites_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_scanner/features/history/history_service.dart';

enum QrType {
  url,
  wifi,
  contact,
  sms,
  phone,
  email,
  geo,
  calendar,
  whatsapp,
  skype,
  facetime,
  paypal,
  bitcoin,
  ethereum,
  instagram,
  facebook,
  twitter,
  youtube,
  tiktok,
  playStore,
  appStore,
  text,
}

class ResultScreen extends StatefulWidget {
  final String code;
  final Function() onClose;

  const ResultScreen({super.key, required this.code, required this.onClose});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? _customTitle;
  late String _originalTypeTitle; // To fallback

  @override
  void initState() {
    super.initState();
    _loadCustomName();
  }

  Future<void> _loadCustomName() async {
    // Check Favorites (Sync)
    final favTitle = FavoritesService().getTitle(widget.code);
    if (favTitle != null) {
      if (mounted) setState(() => _customTitle = favTitle);
      return;
    }

    // Check History (Async)
    // We iterate history to find the most recent one? Or any.
    // HistoryService doesn't expose findItem.
    // Let's implement a simple find.
    // Actually, getting all history and searching is okay.
    final history = await HistoryService().getHistory();
    try {
      final item = history.firstWhere((e) => e.code == widget.code && e.customName != null);
      if (mounted) setState(() => _customTitle = item.customName);
    } catch (_) {
      // Not found
    }
  }

  void _showRenameDialog() {
     final controller = TextEditingController(text: _customTitle ?? _originalTypeTitle);
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: Theme.of(context).cardColor,
         title: const Text("Rename"),
         content: TextField(
           controller: controller,
           decoration: const InputDecoration(hintText: "Enter custom name"),
           autofocus: true,
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text("Cancel"),
           ),
           TextButton(
             onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() => _customTitle = newName);
                  // Update Services
                  await FavoritesService().updateTitle(widget.code, newName);
                  await HistoryService().updateTitle(widget.code, newName);
                }
                if (context.mounted) Navigator.pop(context);
             },
             child: const Text("Save"),
           ),
         ],
       ),
     );
  }

  QrType _determineType(String data) {
    final lowerData = data.toLowerCase();

    // Calendar
    if (lowerData.contains('begin:vevent')) return QrType.calendar;

    // Contact / People
    if (lowerData.startsWith('mecard:') || lowerData.startsWith('vcard:')) {
      return QrType.contact;
    }

    // Communication
    if (lowerData.startsWith('tel:')) return QrType.phone;
    if (lowerData.startsWith('smsto:') || lowerData.startsWith('sms:')) {
      return QrType.sms;
    }
    if (lowerData.startsWith('mailto:') || lowerData.startsWith('matmsg:')) {
      return QrType.email;
    }
    if (lowerData.startsWith('whatsapp:') || lowerData.contains('wa.me/')) {
      return QrType.whatsapp;
    }
    if (lowerData.startsWith('skype:')) return QrType.skype;
    if (lowerData.startsWith('facetime:') ||
        lowerData.startsWith('facetime-audio:')) {
      return QrType.facetime;
    }

    // Geo
    if (lowerData.startsWith('geo:')) return QrType.geo;

    // Wifi
    if (lowerData.startsWith('wifi:')) return QrType.wifi;

    // Financial
    if (lowerData.contains('paypal.me')) return QrType.paypal;
    if (lowerData.startsWith('bitcoin:')) return QrType.bitcoin;
    if (lowerData.startsWith('ethereum:')) return QrType.ethereum;

    // Stores
    if (lowerData.startsWith('market://') ||
        lowerData.contains('play.google.com')) {
      return QrType.playStore;
    }
    if (lowerData.startsWith('itms-apps://') ||
        lowerData.contains('apps.apple.com')) {
      return QrType.appStore;
    }

    // Social Media
    if (lowerData.contains('instagram.com') ||
        lowerData.startsWith('instagram://')) {
      return QrType.instagram;
    }
    if (lowerData.contains('facebook.com') ||
        lowerData.contains('fb.com') ||
        lowerData.startsWith('fb://')) {
      return QrType.facebook;
    }
    if (lowerData.contains('twitter.com') ||
        lowerData.contains('x.com') ||
        lowerData.startsWith('twitter://')) {
      return QrType.twitter;
    }
    if (lowerData.contains('youtube.com') || lowerData.contains('youtu.be')) {
      return QrType.youtube;
    }
    if (lowerData.contains('tiktok.com')) return QrType.tiktok;

    // Generic URL
    if (lowerData.startsWith('http://') || lowerData.startsWith('https://')) {
      return QrType.url;
    }

    return QrType.text;
  }

  String _getTypeTitle(QrType type) {
    switch (type) {
      case QrType.url:
        return 'Website';
      case QrType.wifi:
        return 'WiFi Network';
      case QrType.contact:
        return 'Contact';
      case QrType.sms:
        return 'SMS Message';
      case QrType.phone:
        return 'Phone Number';
      case QrType.email:
        return 'Email';
      case QrType.geo:
        return 'Location';
      case QrType.calendar:
        return 'Calendar Event';
      case QrType.whatsapp:
        return 'WhatsApp';
      case QrType.skype:
        return 'Skype';
      case QrType.facetime:
        return 'FaceTime';
      case QrType.paypal:
        return 'PayPal';
      case QrType.bitcoin:
        return 'Bitcoin';
      case QrType.ethereum:
        return 'Ethereum';
      case QrType.instagram:
        return 'Instagram';
      case QrType.facebook:
        return 'Facebook';
      case QrType.twitter:
        return 'Twitter / X';
      case QrType.youtube:
        return 'YouTube';
      case QrType.tiktok:
        return 'TikTok';
      case QrType.playStore:
        return 'Google Play Store';
      case QrType.appStore:
        return 'Apple App Store';
      case QrType.text:
        return 'Text Result';
    }
  }

  IconData _getTypeIcon(QrType type) {
    switch (type) {
      case QrType.url:
        return Icons.language;
      case QrType.wifi:
        return Icons.wifi;
      case QrType.contact:
        return Icons.person_outline;
      case QrType.sms:
        return Icons.sms_outlined;
      case QrType.phone:
        return Icons.phone_outlined;
      case QrType.email:
        return Icons.email_outlined;
      case QrType.geo:
        return Icons.location_on_outlined;
      case QrType.calendar:
        return Icons.calendar_today;
      case QrType.whatsapp:
        return Icons.chat_bubble_outline;
      case QrType.skype:
        return Icons.video_call_outlined;
      case QrType.facetime:
        return Icons.video_camera_front_outlined;
      case QrType.paypal:
        return Icons.payment;
      case QrType.bitcoin:
        return Icons.currency_bitcoin;
      case QrType.ethereum:
        return Icons.currency_exchange;
      case QrType.instagram:
        return Icons.camera_alt_outlined;
      case QrType.facebook:
        return Icons.facebook;
      case QrType.twitter:
        return Icons.alternate_email;
      case QrType.youtube:
        return Icons.play_circle_outline;
      case QrType.tiktok:
        return Icons.music_note;
      case QrType.playStore:
        return Icons.shop;
      case QrType.appStore:
        return Icons.apple;
      case QrType.text:
        return Icons.text_fields;
    }
  }

  Future<void> _launchIntent(String uriString, BuildContext context) async {
    // Basic fix for SMS encoding
    if (uriString.toLowerCase().startsWith('smsto:')) {
      final parts = uriString.substring(6).split(':');
      final number = parts[0];
      final body = parts.length > 1 ? parts.sublist(1).join(':') : '';
      uriString = 'sms:$number?body=${Uri.encodeComponent(body)}';
    }

    final Uri url = Uri.parse(uriString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch action: $e')));
      }
    }
  }

  Future<void> _launchWifiSettings(BuildContext context) async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WiFi settings')),
        );
      }
    }
  }

  Future<void> _saveQrCode(BuildContext context) async {
    try {
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

      // Generate image data
      final image = await QrPainter(
        data: widget.code,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(800);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Write to file
      final file = await File(path).create();
      await file.writeAsBytes(buffer);

      // Save to gallery using Gal
      await Gal.putImage(path);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  Future<void> _addContact(BuildContext context) async {
    try {
      if (await Permission.contacts.request().isGranted) {
        String firstName = '';
        String lastName = '';
        String phone = '';
        String email = '';

        // Simplistic VCard/MeCard Parsing
        final parts = widget.code.split(';');
        for (final part in parts) {
          final p = part.trim();
          if (p.startsWith('N:')) {
            final nameParts = p.substring(2).split(',');
            if (nameParts.isNotEmpty) lastName = nameParts[0];
            if (nameParts.length > 1) firstName = nameParts[1];
          } else if (p.startsWith('TEL:')) {
            phone = p.substring(4);
          } else if (p.startsWith('EMAIL:')) {
            email = p.substring(6);
          }
        }

        // If MECARD format (N:Name,FirstName;TEL:...)
        if (widget.code.startsWith('MECARD:')) {
          // simplified logic above works for generic structure, usually MECARD:N:Name;TEL:123;;
        }

        final newContact = Contact()
          ..name.first = firstName
          ..name.last = lastName
          ..phones = [Phone(phone)]
          ..emails = [Email(email)];

        await FlutterContacts.openExternalInsert(newContact);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact permission denied')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding contact: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _determineType(widget.code);
    final typeTitle = _getTypeTitle(type);
    _originalTypeTitle = typeTitle; // Store original
    final typeIcon = _getTypeIcon(type);
    
    // Display Title: Custom or Type
    final displayTitle = _customTitle ?? typeTitle;

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
        title: Text(typeTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            widget.onClose();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: "Rename",
            onPressed: _showRenameDialog,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Code Image
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Keep white for QR Code visibility? Yes, QR needs white background usually.
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.code,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Details Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, color: Colors.blue.shade400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (_customTitle != null)
                        const Icon(Icons.edit, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.code,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Created: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Dynamic Contextual Action
                if (type == QrType.url ||
                    type == QrType.instagram ||
                    type == QrType.facebook ||
                    type == QrType.twitter ||
                    type == QrType.youtube ||
                    type == QrType.tiktok ||
                    type == QrType.paypal ||
                    type == QrType.skype ||
                    type == QrType.playStore ||
                    type == QrType.appStore)
                  _buildActionButton(
                    context,
                    icon: Icons.open_in_browser,
                    label: 'Open',
                    color: Colors.blue,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.whatsapp)
                  _buildActionButton(
                    context,
                    icon: Icons.chat,
                    label: 'Chat',
                    color: Colors.green,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.bitcoin || type == QrType.ethereum)
                  _buildActionButton(
                    context,
                    icon: Icons.currency_bitcoin,
                    label: 'Pay',
                    color: Colors.orange,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.wifi)
                  _buildActionButton(
                    context,
                    icon: Icons.wifi_find,
                    label: 'Connect',
                    color: Colors.blue,
                    onTap: () => _launchWifiSettings(context),
                  ),

                if (type == QrType.contact)
                  _buildActionButton(
                    context,
                    icon: Icons.person_add,
                    label: 'Add Contact',
                    color: Colors.blue,
                    onTap: () => _addContact(context),
                  ),

                if (type == QrType.calendar)
                  _buildActionButton(
                    context,
                    icon: Icons.event,
                    label: 'Add Event',
                    color: Colors.purple,
                    onTap: () {
                      // Calendar intent parsing is complex, sharing is a safe fallback for now
                      Share.share(widget.code, subject: 'New Event');
                    },
                  ),

                if (type == QrType.sms)
                  _buildActionButton(
                    context,
                    icon: Icons.sms,
                    label: 'Send SMS',
                    color: Colors.blue,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.phone)
                  _buildActionButton(
                    context,
                    icon: Icons.call,
                    label: 'Call',
                    color: Colors.green,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.email)
                  _buildActionButton(
                    context,
                    icon: Icons.email,
                    label: 'Send Email',
                    color: Colors.redAccent,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                if (type == QrType.geo)
                  _buildActionButton(
                    context,
                    icon: Icons.map,
                    label: 'Open Map',
                    color: Colors.green,
                    onTap: () => _launchIntent(widget.code, context),
                  ),

                // Standard Actions
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.blueGrey,
                  onTap: () {
                    Share.share(widget.code);
                  },
                ),
                ValueListenableBuilder<Box>(
                  valueListenable: FavoritesService().listenable(),
                  builder: (context, box, _) {
                    final isFav = FavoritesService().isFavorite(widget.code);
                    return _buildActionButton(
                      context,
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      label: 'Favorite', // Keep label simple or 'Saved'? User: "scan or scan result ma kabi favrorite wala icon laga doo"
                      color: Colors.red,
                      onTap: () {
                        // Pass displayTitle as the initial title if needed, or original
                        FavoritesService().toggleFavorite(widget.code, _originalTypeTitle);
                        // If it's a new favorite, should we assume current custom name?
                        // If we have custom name, update it.
                         if (_customTitle != null && !isFav) { // If adding
                           FavoritesService().updateTitle(widget.code, _customTitle!);
                         }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFav ? "Removed from Favorites" : "Added to Favorites"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.save,
                  label: 'Save',
                  color: Colors.green,
                  onTap: () => _saveQrCode(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.copy,
                  label: 'Copy',
                  color: Colors.orange,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
                // Delete
                _buildActionButton(
                  context,
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.grey,
                  onTap: () {
                    widget.onClose();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Deleted')));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
