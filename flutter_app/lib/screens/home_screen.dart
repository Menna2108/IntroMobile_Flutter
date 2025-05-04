import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String _userName = 'Gebruiker';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _authService.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists &&
            userData.data() != null &&
            userData.data()!.containsKey('name')) {
          if (mounted) {
            setState(() {
              _userName = userData.data()!['name'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Navigate to search screen
      Navigator.pushNamed(context, '/search');
    } else if (index == 2) {
      // Navigate to add appliance screen
      Navigator.pushNamed(context, '/add_appliance');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showProfileDialog() async {
    final User? user = _authService.currentUser;
    String email = user?.email ?? 'Geen e-mail beschikbaar';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mijn Profiel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Simplified to just show the logout option
                _buildProfileMenuItem(Icons.logout, 'Uitloggen', () {
                  Navigator.of(context).pop();
                  _showLogoutConfirmation();
                }, color: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.blue[700]),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: color ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Uitloggen'),
          content: const Text('Weet je zeker dat je wilt uitloggen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Uitloggen'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deze lijsten kunnen vervangen worden door echte data van Firebase
    final List<Map<String, dynamic>> featuredItems = [
      {
        'title': 'Boormachine',
        'price': '€5/dag',
        'image': 'assets/images/drill.jpg',
        'distance': '1.2 km',
      },
      {
        'title': 'Grasmaaier',
        'price': '€10/dag',
        'image': 'assets/images/mower.jpg',
        'distance': '0.8 km',
      },
      {
        'title': 'Stofzuiger',
        'price': '€3/dag',
        'image': 'assets/images/vacuum.jpg',
        'distance': '2.3 km',
      },
    ];

    final List<Map<String, dynamic>> categories = [
      {'name': 'Tuingereedschap', 'icon': Icons.grass},
      {'name': 'Keuken', 'icon': Icons.kitchen},
      {'name': 'Gereedschap', 'icon': Icons.construction},
      {'name': 'Elektronica', 'icon': Icons.devices},
      {'name': 'Schoonmaak', 'icon': Icons.cleaning_services},
      {'name': 'Sport', 'icon': Icons.sports_soccer},
    ];

    // Verschillende schermen voor de bottom navigation bar
    final List<Widget> _pages = [
      // Home pagina
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welkomstbericht
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Welkom, $_userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Zoekbalk
              Container(
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[300]!,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Zoek naar apparaten...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onTap: () {
                    // When user taps on search bar, navigate to search screen
                    Navigator.pushNamed(context, '/search');
                  },
                  readOnly: true, // Make it non-editable, just for navigation
                ),
              ),

              // Categorieën
              const Text(
                'Categorieën',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Belangrijke fix: voeg physics toe voor android scrolling
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Fix voor Android
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Navigate to search with a specific category
                        Navigator.pushNamed(
                          context,
                          '/search',
                          arguments:
                              categories[index]['name'], // Geef categorie door
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(
                          right: 12,
                          top: 12,
                          bottom: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[300]!,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              categories[index]['icon'],
                              size: 36,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              categories[index]['name'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Uitgelichte apparaten
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'In de buurt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigeer naar alle apparaten
                        Navigator.pushNamed(context, '/search');
                      },
                      child: const Text('Bekijk alles'),
                    ),
                  ],
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featuredItems.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[300]!,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Placeholder voor de afbeelding
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(
                                _getIconForItem(featuredItems[index]['title']),
                                size: 40,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  featuredItems[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  featuredItems[index]['price'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      featuredItems[index]['distance'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: OutlinedButton(
                            onPressed: () {
                              // Navigate to search screen for now
                              Navigator.pushNamed(context, '/search');
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Bekijk'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Zoek pagina - nu gaan we navigeren naar SearchScreen
      const Center(child: Text('Zoeken')),

      // Toevoegen pagina
      Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add_appliance');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Een apparaat toevoegen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // Reserveringen pagina - placeholder
      const Center(child: Text('Mijn Reserveringen')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[300]!,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.handshake_outlined, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            const Text('Boromi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Toon notificaties
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showProfileDialog();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Zoeken'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 30),
            label: 'Toevoegen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Reserveringen',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper functie om een icoon te kiezen op basis van de titel
  IconData _getIconForItem(String title) {
    switch (title.toLowerCase()) {
      case 'boormachine':
        return Icons.build;
      case 'grasmaaier':
        return Icons.grass;
      case 'stofzuiger':
        return Icons.cleaning_services;
      default:
        return Icons.devices_other;
    }
  }
}
