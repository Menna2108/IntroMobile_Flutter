import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app/screens/appliance/appliance_detail_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/appliance/add_appliance_screen.dart';
import 'screens/map_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      initialData: null,
      value: AuthService().authStateChanges,
      child: MaterialApp(
        title: 'Boromi',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          sliderTheme: const SliderThemeData(
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue,
            thumbColor: Colors.blue,
            overlayColor: Colors.blue,
          ),
          dropdownMenuTheme: const DropdownMenuThemeData(
            textStyle: TextStyle(color: Colors.blue),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/add_appliance': (context) => const AddApplianceScreen(),
          '/map': (context) => const MapScreen(),
          '/appliance_detail': (context) => const ApplianceDetailScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}
