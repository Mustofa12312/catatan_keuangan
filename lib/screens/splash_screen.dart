import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_lock_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // Tunggu beberapa detik untuk menampilkan animasi
    await Future.delayed(const Duration(milliseconds: 3500), () {});
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final lockEnabled = prefs.getBool('app_lock_enabled') ?? false;

    if (!mounted) return;

    if (lockEnabled) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PinLockScreen(
            mode: PinLockMode.validate,
          ),
        ),
      );
    } else {
      // Ganti ke halaman utama dengan efek fade
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Samakan dengan warna background app
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animation/Welcome.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 100,
                  color: Color(0xFF4F8EF7),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Tabungan Titipan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola titipan tabungan dengan mudah',
              style: TextStyle(
                color: Color(0xFF8899BB),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
