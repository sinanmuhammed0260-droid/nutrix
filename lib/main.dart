import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Added for timeout logic

// Screens
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/user_signup_screen.dart';
import 'screens/doctor_signup_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/camera_view_screen.dart';

Future<void> main() async {
  // Ensure engine is ready
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🛡️ FAILSAFE 1: Initialize with a timeout.
    // If Firebase hangs, it won't block the whole app.
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    print("✅ Firebase Initialized Successfully");
  } catch (e) {
    // If it fails (like a network error or SHA-1 issue), we still run the app
    print("❌ Firebase Initialization Error: $e");
  }

  runApp(const NutrixApp());
}

class NutrixApp extends StatelessWidget {
  const NutrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 🔥 Points to the Gatekeeper
      home: const AuthGate(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/user-signup': (_) => const UserSignupScreen(),
        '/doctor-signup': (_) => const DoctorSignupScreen(),
        '/dashboard': (_) => const HomeDashboardScreen(),
        '/doctor-dashboard': (_) => const DoctorDashboardScreen(),
        '/scanner': (_) => const CameraViewScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🛡️ FAILSAFE 2: If there's an error in the stream, show it!
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Auth Error: ${snapshot.error}")),
          );
        }

        // ⏳ While checking the connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text("Nutrix is checking your session..."),
                ],
              ),
            ),
          );
        }

        // ✅ User is logged in
        if (snapshot.hasData) {
          return const HomeDashboardScreen();
        }

        // ❌ User is not logged in
        return const WelcomeScreen();
      },
    );
  }
}