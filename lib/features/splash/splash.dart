import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_scanner/features/home/home.dart';
import 'package:qr_scanner/features/splash/info_screen.dart';
import 'package:qr_scanner/core/services/hive_database.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Check if it's the first launch
        final isFirstLaunch = HiveDatabase.instance.settingsBox.get('isFirstLaunch', defaultValue: true);

        if (isFirstLaunch) {
          // Navigate to Info Screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const InfoScreen(),
            ),
          );
        } else {
          // Navigate directly to Home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const Home(title: 'QR Scanner'),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Centered Image from assets
                    Image.asset(
                      'assets/qr_img.gif',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'SCAN QR CODE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Making QR code is as easy as reading',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Lottie Animation
              SizedBox(
                width: 150,
                height: 60,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.purple.shade200,
                    BlendMode.srcIn,
                  ),
                  child: Lottie.asset('assets/splash_load.json'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
