import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/flexible_image.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import '../services/api_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasSavedCreds = false;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _initAndCheckSaved();
  }

  Future<void> _initAndCheckSaved() async {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final pass = prefs.getString('saved_password');
    if (email != null && email.isNotEmpty && pass != null && pass.isNotEmpty) {
      setState(() {
        _hasSavedCreds = true;
        _savedEmail = email;
      });
      // don't auto navigate; wait for user to tap the button
    } else {
      // no saved creds: navigate to login after short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
    }
  }

  Future<void> _loginWithSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    if (email == null || password == null) return;
    try {
      final resp = await http.post(Uri.parse(API_BASE_URL), body: {'email': email, 'password': password});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true) {
          final userRole = data['user']['role_id'];
          final userName = data['user']['name'];
          // save user_id similarly to login screen
          final prefs2 = await SharedPreferences.getInstance();
          final userId = data['user']['id']?.toString() ?? '';
          if (userId.isNotEmpty) await prefs2.setString('user_id', userId);
          // navigate based on role
          String routeDestination;
          switch (userRole) {
            case 1:
              routeDestination = '/admin';
              break;
            case 2:
              routeDestination = '/cliente';
              break;
            case 3:
              routeDestination = '/repartidor';
              break;
            case 4:
              routeDestination = '/empleado';
              break;
            default:
              routeDestination = '/cliente';
          }
          Navigator.pushReplacementNamed(context, routeDestination);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bienvenido, $userName')));
        } else {
          // fallback to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 4,
                ), // Gris claro
              ),
              child: ClipOval(
                child: FlexibleImage(
                  source: 'assets/LogoPinequitas.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'Bienvenido a las Pinequitas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Texto en negro
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_hasSavedCreds)
              Column(
                children: [
                  Text('Continuar como $_savedEmail'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loginWithSaved,
                    child: const Text('Ingresar como cliente'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Usar otra cuenta'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
