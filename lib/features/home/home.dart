import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner/features/history/history_screen.dart';
import 'package:qr_scanner/features/history/history_service.dart';
import 'package:qr_scanner/features/result/result_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_scanner/features/settings/settings_provider.dart';
import 'package:qr_scanner/features/create/create_qr_screen.dart';
import 'package:qr_scanner/features/settings/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_scanner/features/batch/batch_service.dart';
import 'package:qr_scanner/features/batch/batch_list_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key, required String title});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver, TickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  AnimationController? _buttonController;
  late AudioPlayer _audioPlayer;
  int _selectedIndex = 0;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: true,
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.repeat(reverse: true);

    _buttonController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2)
    )..repeat(); // Continuous ripple
    
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop); // Optimization
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _animationController.dispose();
    _buttonController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ... (lifecycle methods)

  // ... (methods)




  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isScanning) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _scannerController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _scannerController.stop();
        break;
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) {
             _handleScannedData(code);
             return;
          }
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No QR code found in image")));
      }
    }
  }

  void _onScanButtonPressed() {
    setState(() {
      _isScanning = true;
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 0) {
        _isScanning = false;
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_isScanning) {
      setState(() {
        _isScanning = false;
      });
      return false; // Don't close the app
    }
    return true; // Close the app
  }

  void _handleScannedData(String code) {
    // Get Settings
    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // Feedback
    if (settings.vibrate) HapticFeedback.vibrate();
    if (settings.sound) {
      _audioPlayer.play(AssetSource('scan_beep.ogg'));
    }
    
    // Stop if not batch mode
    if (!settings.batchScan) {
      _scannerController.stop();
    }

    String type = 'Text';
    if (code.startsWith('http')) {
      type = 'Website';
    } else if (code.startsWith('WIFI:'))
      type = 'WiFi Network';
    else if (code.startsWith('smsto:'))
      type = 'SMS Message';
    else if (code.startsWith('tel:'))
      type = 'Phone Number';
    else if (code.startsWith('mailto:'))
      type = 'Email';

    // Save to History
    if (settings.addToHistory) {
      HistoryService().addToHistory(code, type);
    }

    // Auto Handlers
    if (settings.autoCopy) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard")),
      );
    }

    if (settings.openWeb && type == 'Website') {
      launchUrl(
        Uri.parse(code),
        mode: LaunchMode.externalApplication,
      );
    }

    // Navigation Logic
    // Navigation Logic
    if (settings.batchScan) {
      if (!BatchService().contains(code)) {
        BatchService().addScan(code, type);
      }
    } else {
       // Check if widget is mounted before navigating (important for async gallery pick)
       if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultScreen(code: code, onClose: () {}),
            ),
          ).then((_) {
            _scannerController.start(); // Resume scanning on return
          });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isScanning,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isScanning) {
          setState(() {
            _isScanning = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Show Scanner only when index is 0 (Scan) and _isScanning is true
            if (_selectedIndex == 0 && _isScanning) _buildScannerView(),

            // Show initial context view when index is 0 and not scanning
            if (_selectedIndex == 0 && !_isScanning)
              SafeArea(child: _buildContextView()), // Keep context view safe
            // If index == 1 (History), show HistoryScreen.
            if (_selectedIndex == 1) const HistoryScreen(),

            if (_selectedIndex == 3) const SettingsScreen(),

            if (_selectedIndex == 2) const CreateQrScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildContextView() {
    _buttonController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
    )..repeat();
    
    // Use local variable for null safety promotion
    final controller = _buttonController!;

    return SizedBox(
      width: double.infinity, // Ensure full width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Enforce center alignment
        children: [
          const SizedBox(height: 20),
          Text(
            'SCAN QR CODE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating Gradient Border/Glow
                  Transform.rotate(
                    angle: controller.value * 2 * 3.14159,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                            Colors.blue.shade400, // Loop back
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Main Button
                  GestureDetector(
                    onTap: _onScanButtonPressed,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor, // Mask the center
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.3),
                             blurRadius: 10,
                             spreadRadius: 2,
                           )
                        ]
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5), // Border thickness
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.purple.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'TAP TO SCAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanWindow = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: 250,
          height: 250,
        );

        return Stack(
          children: [
            MobileScanner(
              scanWindow: scanWindow,
              controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                final code = barcode.rawValue!;
                debugPrint('Barcode found: $code');
                _handleScannedData(code);
                break; // Only handle the first barcode
              }
            }
          },
        ),
        // Overlay with hole and corners
        CustomPaint(painter: ScannerOverlayPainter(), child: Container()),
        
        // Scanning Line Animation
        Center(
          child: SizedBox(
            width: 250, // Matches scanAreaSize
            height: 250,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: _animationController.value * 250,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Zoom Controls
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: ZoomControls(controller: _scannerController),
        ),
        // Top Back Button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isScanning = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26, 
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Placeholder for spacing if needed, or empty
                ],
              ),
            ),
          ),
        ),

        // Bottom Control Bar (Gallery, Flash, Flip, Batch)
        Positioned(
          bottom: 80, // Above Zoom Controls
          left: 0,
          right: 0,
          child: Center(
            child: Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 32),
                      
                      // Flash
                      ValueListenableBuilder(
                        valueListenable: _scannerController,
                        builder: (context, value, child) {
                          final isAuth = value.torchState == TorchState.on;
                          return GestureDetector(
                            onTap: () => _scannerController.toggleTorch(),
                            child: Icon(
                              isAuth ? Icons.flash_on : Icons.flash_off,
                              color: isAuth ? Colors.amber : Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 32),
                      
                      // Flip
                      GestureDetector(
                        onTap: () => _scannerController.switchCamera(),
                        child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 28),
                      ),

                      // Batch Icon (Conditional)
                      if (settings.batchScan) ...[
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchListScreen()));
                          },
                          child: const Icon(Icons.layers_outlined, color: Colors.blueAccent, size: 28),
                        ),
                      ],
                    ],
                  ),
                );
              }
            ),
          ),
        ),

        // Batch Counter Card (Floating above controls)
        Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (!settings.batchScan) return const SizedBox.shrink();
            return Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder<Box>(
                  valueListenable: BatchService().listenable(),
                  builder: (context, box, _) {
                    if (box.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchListScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9), // Glassy Blue
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                          ],
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${box.length} Scanned",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            );
          },
        ),
      ],
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 10), // Add padding
      decoration: BoxDecoration(
        color:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Only care about bottom safe area
        child: SizedBox(
          height: 60, // Fixed height for the content inside safe area
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'assets/ic_scan.svg', 'Scan'),
              _buildNavItem(1, 'assets/ic_history.svg', 'History'),
              _buildNavItem(2, 'assets/ic_qr.svg', 'Create QR'),
              _buildNavItem(3, 'assets/ic_setting.svg', 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String assetPath, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.blue : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ZoomControls extends StatefulWidget {
  final MobileScannerController controller;

  const ZoomControls({super.key, required this.controller});

  @override
  State<ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> {
  double _zoomLevel = 0.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.zoom_out, color: Colors.white),
        Expanded(
          child: Slider(
            value: _zoomLevel,
            onChanged: (value) {
              setState(() {
                _zoomLevel = value;
              });
              widget.controller.setZoomScale(value);
            },
            activeColor: Colors.purple.shade200,
            inactiveColor: Colors.white24,
          ),
        ),
        const Icon(Icons.zoom_in, color: Colors.white),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final scanAreaSize = 250.0;
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw background with hole
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    final holePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(
      scanRect,
      holePaint,
    );
    canvas.restore();

    // Draw Corners
    final borderPaint = Paint()
      ..color = Colors.purple.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right - cornerLength, scanRect.bottom),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + cornerLength, scanRect.bottom)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left, scanRect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
