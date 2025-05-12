import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/screens/reservation/reservations_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../models/appliance.dart';
import '../services/appliance_service.dart';
import '../widgets/user_appliances_widget.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCategory;

  const HomeScreen({super.key, this.initialCategory});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ApplianceService _applianceService = ApplianceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _userName = 'Gebruiker';
  String _searchQuery = '';
  late String _activeCategory;
  LatLng? _userPosition;
  double _maxDistance = 10.0;
  String _sortOrder = 'asc';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Alle', 'icon': Icons.apps},
    {'name': 'Tuingereedschap', 'icon': Icons.grass},
    {'name': 'Keuken', 'icon': Icons.kitchen},
    {'name': 'Gereedschap', 'icon': Icons.construction},
    {'name': 'Elektronica', 'icon': Icons.devices},
    {'name': 'Schoonmaak', 'icon': Icons.cleaning_services},
    {'name': 'Sport', 'icon': Icons.sports_soccer},
    {'name': 'Overig', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory ?? 'Alle';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _authService.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data() != null) {
          if (mounted) {
            setState(() {
              _userName = userData.data()!['name'] ?? 'Gebruiker';
              if (userData.data()!['latitude'] != null &&
                  userData.data()!['longitude'] != null) {
                _userPosition = LatLng(
                  userData.data()!['latitude'] as double,
                  userData.data()!['longitude'] as double,
                );
              } else {
                _userPosition = const LatLng(51.221340, 4.405150);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/add_appliance');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _activeCategory = category;
      if (category == 'Alle') {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempMaxDistance = _maxDistance;
        String tempSortOrder = _sortOrder;

        return AlertDialog(
          title: const Text('Filter Opties'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Max. afstand: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: Slider(
                          value: tempMaxDistance,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          label: '${tempMaxDistance.toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() {
                              tempMaxDistance = value;
                            });
                          },
                          activeColor: Colors.blue[700],
                          inactiveColor: Colors.blue[200],
                        ),
                      ),
                      Text(
                        '${tempMaxDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Sorteren op prijs: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: tempSortOrder,
                        items: const [
                          DropdownMenuItem(
                            value: 'asc',
                            child: Text('Oplopend'),
                          ),
                          DropdownMenuItem(
                            value: 'desc',
                            child: Text('Aflopend'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              tempSortOrder = value;
                            });
                          }
                        },
                        iconEnabledColor: Colors.blue[700],
                        style: TextStyle(color: Colors.blue[700]),
                        dropdownColor: Colors.blue[50],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _maxDistance = tempMaxDistance;
                  _sortOrder = tempSortOrder;
                });
                Navigator.pop(context);
              },
              child: const Text('Toepassen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProfileDialog() async {
    final User? user = _authService.currentUser;
    String email = user?.email ?? 'Geen e-mail beschikbaar';
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    TextEditingController addressController = TextEditingController();
    String? errorMessage;

    final userData = await _firestore.collection('users').doc(user!.uid).get();
    if (userData.exists && userData.data() != null) {
      addressController.text = userData.data()!['address'] ?? '';
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                              nameController.text.isNotEmpty
                                  ? nameController.text[0].toUpperCase()
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
                            nameController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Naam',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Adres',
                        hintText: 'Bijv. Hoofdstraat 123, Antwepen',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          bool serviceEnabled =
                              await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Locatieservices zijn uitgeschakeld.',
                                ),
                              ),
                            );
                            setState(() {
                              addressController.text = 'Antwerpen, België';
                              errorMessage = null;
                            });
                            return;
                          }

                          PermissionStatus permissionStatus =
                              await Permission.location.request();
                          if (permissionStatus.isGranted) {
                            Position position =
                                await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high,
                                  ),
                                );
                            List<Placemark> placemarks =
                                await placemarkFromCoordinates(
                                  position.latitude,
                                  position.longitude,
                                );
                            Placemark placemark = placemarks.first;
                            String address =
                                '${placemark.street}, ${placemark.locality}';

                            setState(() {
                              addressController.text = address;
                              errorMessage = null;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Locatietoestemming geweigerd.'),
                              ),
                            );
                            setState(() {
                              addressController.text = 'Antwerpen, België';
                              errorMessage = null;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fout bij ophalen locatie: $e'),
                            ),
                          );
                          setState(() {
                            addressController.text = 'Antwerpen, België';
                            errorMessage = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Huidige locatie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildProfileMenuItem(Icons.logout, 'Uitloggen', () {
                      Navigator.of(context).pop();
                      _showLogoutConfirmation();
                    }, color: Colors.red),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Annuleren'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Opslaan'),
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      setState(() {
                        errorMessage = 'Naam is verplicht';
                      });
                      return;
                    }

                    try {
                      double? latitude;
                      double? longitude;
                      String address = addressController.text.trim();

                      if (address.isNotEmpty) {
                        List<Location> locations = await locationFromAddress(
                          address,
                        );
                        if (locations.isNotEmpty) {
                          latitude = locations.first.latitude;
                          longitude = locations.first.longitude;
                        } else {
                          setState(() {
                            errorMessage =
                                'Geen locatie gevonden voor dit adres';
                          });
                          return;
                        }
                      }

                      await _firestore.collection('users').doc(user.uid).set({
                        'name': nameController.text.trim(),
                        'address': address,
                        'latitude': latitude,
                        'longitude': longitude,
                      }, SetOptions(merge: true));

                      await _applianceService.updateUserAppliancesUserName(
                        user.uid,
                        nameController.text.trim(),
                      );

                      setState(() {
                        _userName = nameController.text.trim();
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profiel bijgewerkt')),
                      );
                    } catch (e) {
                      setState(() {
                        errorMessage = 'Fout bij opslaan: $e';
                      });
                    }
                  },
                ),
              ],
            );
          },
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

  Widget _buildApplianceCard(Appliance appliance) {
    String city = 'Onbekend';
    if (appliance.address != null && appliance.address!.isNotEmpty) {
      final addressParts = appliance.address!.split(',');
      if (addressParts.length > 1) {
        city = addressParts[1].trim();
      } else {
        city = appliance.address!.trim();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/appliance_detail',
            arguments: appliance,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child:
                  appliance.imageUrl != null && appliance.imageUrl!.isNotEmpty
                      ? Image.network(
                        appliance.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(appliance.category);
                        },
                      )
                      : _buildPlaceholderImage(appliance.category),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appliance.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '€${appliance.pricePerDay.toStringAsFixed(2)}/dag',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(city, style: TextStyle(color: Colors.grey[600])),
                      const Spacer(),
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appliance.userName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String category) {
    IconData icon;
    switch (category) {
      case 'Tuingereedschap':
        icon = Icons.grass;
        break;
      case 'Keuken':
        icon = Icons.kitchen;
        break;
      case 'Gereedschap':
        icon = Icons.construction;
        break;
      case 'Elektronica':
        icon = Icons.devices;
        break;
      case 'Schoonmaak':
        icon = Icons.cleaning_services;
        break;
      case 'Sport':
        icon = Icons.sports_soccer;
        break;
      default:
        icon = Icons.devices_other;
    }

    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(child: Icon(icon, size: 60, color: Colors.grey[400])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Zoek naar apparaten...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ),
                ],
              ),
              const Text(
                'Categorieën',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isActive = category['name'] == _activeCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => _selectCategory(category['name']),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? Colors.blue[700]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category['icon'],
                                color:
                                    isActive ? Colors.white : Colors.grey[700],
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['name'],
                              style: TextStyle(
                                color:
                                    isActive
                                        ? Colors.blue[700]
                                        : Colors.grey[700],
                                fontWeight:
                                    isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  'Apparaten',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<Appliance>>(
                stream:
                    _searchQuery.isNotEmpty
                        ? _applianceService.searchAppliances(_searchQuery)
                        : _activeCategory != 'Alle'
                        ? _applianceService.getAppliancesByCategory(
                          _activeCategory,
                        )
                        : _applianceService.getAppliances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Geen apparaten gevonden',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Er zijn geen apparaten in deze categorie',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final user = _authService.currentUser;
                  List<Appliance> filteredAppliances =
                      snapshot.data!
                          .where((appliance) => appliance.userId != user!.uid)
                          .where((appliance) => appliance.isAvailable)
                          .where((appliance) {
                            if (_userPosition == null ||
                                appliance.latitude == null ||
                                appliance.longitude == null) {
                              return true;
                            }
                            double distanceInMeters =
                                Geolocator.distanceBetween(
                                  _userPosition!.latitude,
                                  _userPosition!.longitude,
                                  appliance.latitude!,
                                  appliance.longitude!,
                                );
                            double distanceInKm = distanceInMeters / 1000;
                            return distanceInKm <= _maxDistance;
                          })
                          .toList();

                  filteredAppliances.sort((a, b) {
                    if (_sortOrder == 'asc') {
                      return a.pricePerDay.compareTo(b.pricePerDay);
                    } else {
                      return b.pricePerDay.compareTo(a.pricePerDay);
                    }
                  });

                  if (filteredAppliances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Geen apparaten gevonden',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Er zijn geen apparaten in deze categorie',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAppliances.length,
                    itemBuilder: (context, index) {
                      final appliance = filteredAppliances[index];
                      return _buildApplianceCard(appliance);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      UserAppliancesWidget(),
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
      const ReservationsScreen(),
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
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.pushNamed(context, '/map', arguments: _activeCategory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showProfileDialog();
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Mijn Apparaten',
          ),
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
}
