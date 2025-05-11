import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '/models/appliance.dart';
import '/services/appliance_service.dart';

class AddApplianceScreen extends StatefulWidget {
  const AddApplianceScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddApplianceScreenState createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApplianceService _applianceService = ApplianceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedCategory = 'Gereedschap';
  File? _imageFile;
  bool _isLoading = false;
  String? _userName;
  double? _latitude;
  double? _longitude;
  bool _useCurrentLocation = false;
  bool _isAvailable = true;
  LatLng? _profilePosition;

  final List<String> _categories = [
    'Tuingereedschap',
    'Keuken',
    'Gereedschap',
    'Elektronica',
    'Schoonmaak',
    'Sport',
    'Overig',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userName =
              userData.exists && userData.data() != null
                  ? userData.data()!['name'] ??
                      user.email?.split('@')[0] ??
                      'Gebruiker'
                  : user.email?.split('@')[0] ?? 'Gebruiker';
          if (userData.exists &&
              userData.data() != null &&
              userData.data()!['latitude'] != null &&
              userData.data()!['longitude'] != null) {
            _profilePosition = LatLng(
              userData.data()!['latitude'] as double,
              userData.data()!['longitude'] as double,
            );
          } else {
            _profilePosition = const LatLng(51.221340, 4.405150);
          }
          _addressController.text =
              userData.exists && userData.data() != null
                  ? userData.data()!['address'] ?? 'Antwerpen, België'
                  : 'Antwerpen, België';
          _latitude = _profilePosition!.latitude;
          _longitude = _profilePosition!.longitude;
        });
      } catch (e) {
        debugPrint('Fout bij laden gebruikersnaam: $e');
        setState(() {
          _userName = user.email?.split('@')[0] ?? 'Gebruiker';
          _profilePosition = const LatLng(51.221340, 4.405150);
          _addressController.text = 'Antwerpen, België';
          _latitude = 51.221340;
          _longitude = 4.405150;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final filename =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('appliance_images')
          .child(filename);

      final uploadTask = storageRef.putFile(
        _imageFile!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Fout bij uploaden afbeelding: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Locatieservices zijn uitgeschakeld. Gebruik een standaardlocatie.',
            ),
          ),
        );
        setState(() {
          _latitude = 51.221340;
          _longitude = 4.405150;
          _addressController.text = 'Antwerpen, België';
          _useCurrentLocation = true;
        });
        return;
      }

      PermissionStatus permissionStatus = await Permission.location.request();
      if (permissionStatus.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark placemark = placemarks.first;
        String address = '${placemark.street}, ${placemark.locality}';

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressController.text = address;
          _useCurrentLocation = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Locatietoestemming geweigerd. Gebruik een standaardlocatie.',
            ),
          ),
        );
        setState(() {
          _latitude = 51.221340;
          _longitude = 4.405150;
          _addressController.text = 'Antwerpen, België';
          _useCurrentLocation = true;
        });
      }
    } catch (e) {
      debugPrint('Fout bij ophalen locatie: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fout bij ophalen locatie: $e')));
      setState(() {
        _latitude = 51.221340;
        _longitude = 4.405150;
        _addressController.text = 'Antwerpen, België';
        _useCurrentLocation = true;
      });
    }
  }

  Future<void> _geocodeAddress() async {
    try {
      String address = _addressController.text.trim();
      if (address.isEmpty) return;

      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geen locatie gevonden voor dit adres.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Fout bij geocoderen adres: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fout bij verwerken adres: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Je moet ingelogd zijn om een apparaat toe te voegen',
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            throw Exception('Fout bij uploaden afbeelding');
          }
        }

        if (!_useCurrentLocation && _addressController.text.isNotEmpty) {
          await _geocodeAddress();
        }

        final appliance = Appliance(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          pricePerDay: double.parse(_priceController.text.trim()),
          userId: user.uid,
          userName: _userName ?? 'Onbekend',
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          isAvailable: _isAvailable,
          latitude: _latitude,
          longitude: _longitude,
          address: _addressController.text.trim(),
        );

        final docId = await _applianceService.addAppliance(appliance);
        debugPrint('Apparaat toegevoegd met ID: $docId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apparaat succesvol toegevoegd')),
        );

        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _addressController.clear();
        setState(() {
          _imageFile = null;
          _selectedCategory = 'Gereedschap';
          _latitude = null;
          _longitude = null;
          _useCurrentLocation = false;
          _isAvailable = true;
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij toevoegen apparaat: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apparaat Toevoegen')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                _imageFile != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 50,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Klik om een foto toe te voegen',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titel',
                          hintText: 'Bijv. Boormachine, Stofzuiger',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Vul een titel in'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Categorie',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Selecteer een categorie'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prijs per dag (€)',
                          hintText: 'Bijv. 5.50',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.euro),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vul een prijs in';
                          }
                          try {
                            final price = double.parse(value);
                            if (price <= 0) {
                              return 'De prijs moet groter zijn dan 0';
                            }
                          } catch (e) {
                            return 'Vul een geldig getal in';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Beschikbaar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                              activeColor: Colors.blue[700],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Adres',
                          hintText: 'Bijv. Hoofdstraat 123, Amsterdam',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Vul een adres in'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Gebruik huidige locatie'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Beschrijving',
                          hintText:
                              'Geef een gedetailleerde beschrijving van je apparaat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.description),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vul een beschrijving in';
                          }
                          if (value.length < 20) {
                            return 'De beschrijving moet minstens 20 tekens lang zijn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Toevoegen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
