import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '/models/appliance.dart';
import '/services/appliance_service.dart';

class AddApplianceScreen extends StatefulWidget {
  const AddApplianceScreen({super.key});

  @override
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
  
  String _selectedCategory = 'Gereedschap';
  File? _imageFile;
  String? _base64Image; 
  bool _isLoading = false;
  String? _userName;
  
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
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data() != null && userData.data()!.containsKey('name')) {
          setState(() {
            _userName = userData.data()!['name'];
          });
        } else {
          // If no name is found, use email or a default name
          setState(() {
            _userName = user.email?.split('@')[0] ?? 'Gebruiker';
          });
        }
      } catch (e) {
        debugPrint('Error loading user name: $e');
        // Fall back to email or default name
        setState(() {
          _userName = user.email?.split('@')[0] ?? 'Gebruiker';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // Limit width to reduce file size
      maxHeight: 1024, // Limit height to reduce file size
      imageQuality: 85, // Adjust image quality (0-100)
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      
      // Convert to base64 if needed
      await _convertImageToBase64();
    }
  }

  Future<void> _convertImageToBase64() async {
    if (_imageFile == null) return;
    
    try {
      // Read file as bytes
      List<int> imageBytes = await _imageFile!.readAsBytes();
      
      // Convert to base64
      String base64Image = base64Encode(imageBytes);
      
      setState(() {
        _base64Image = base64Image;
      });
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Create a unique filename
      final filename = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('appliance_images')
          .child(filename);

      // Option 1: Direct file upload
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
      
      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);
      
      // Get download URL
      return await snapshot.ref.getDownloadURL();
      
      // Option 2: If you need to use base64 (uncommonly needed but included for completeness)
      /*
      if (_base64Image != null) {
        // Convert base64 back to bytes
        List<int> imageBytes = base64Decode(_base64Image!);
        
        // Upload bytes
        final uploadTask = storageRef.putData(
          Uint8List.fromList(imageBytes),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
        
        // Wait for upload to complete
        final snapshot = await uploadTask.whenComplete(() => null);
        
        // Get download URL
        return await snapshot.ref.getDownloadURL();
      }
      
      return null;
      */
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
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
            const SnackBar(content: Text('Je moet ingelogd zijn om een apparaat toe te voegen')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Upload image if selected
        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            throw Exception('Fout bij het uploaden van de afbeelding');
          }
        }

        // Create appliance object
        final appliance = Appliance(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          pricePerDay: double.parse(_priceController.text.trim()),
          userId: user.uid,
          userName: _userName ?? 'Onbekend',
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          isAvailable: true,
        );

        // Add to Firestore
        final docId = await _applianceService.addAppliance(appliance);
        debugPrint('Appliance added with ID: $docId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apparaat succesvol toegevoegd')),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _imageFile = null;
          _base64Image = null;
          _selectedCategory = 'Gereedschap';
        });

        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij het toevoegen van apparaat: $e')),
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
      appBar: AppBar(
        title: const Text('Apparaat Toevoegen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
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
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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

                    // Title field
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vul een titel in';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecteer een categorie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price field
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

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Beschrijving',
                        hintText: 'Geef een gedetailleerde beschrijving van je apparaat',
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

                    // Submit button
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
    super.dispose();
  }
}