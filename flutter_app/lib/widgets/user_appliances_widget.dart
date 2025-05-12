import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appliance.dart';
import '../services/appliance_service.dart';

class UserAppliancesWidget extends StatelessWidget {
  final ApplianceService _applianceService = ApplianceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserAppliancesWidget({super.key});

  Widget _buildApplianceCard(BuildContext context, Appliance appliance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child:
                      appliance.imageUrl != null &&
                              appliance.imageUrl!.isNotEmpty
                          ? Hero(
                            tag: "appliance-image-${appliance.id}",
                            child: Image.network(
                              appliance.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage(
                                  appliance.category,
                                );
                              },
                            ),
                          )
                          : _buildPlaceholderImage(appliance.category),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '€${appliance.pricePerDay.toStringAsFixed(2)}/dag',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  appliance.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(150, 0, 0, 0),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildInfoChip(
                        Icons.category_outlined,
                        appliance.category,
                        Colors.blue[50]!,
                        Colors.blue[700]!,
                      ),
                      const SizedBox(width: 8),
                      if (appliance.address != null &&
                          appliance.address!.isNotEmpty)
                        _buildInfoChip(
                          Icons.location_on_outlined,
                          _getCityFromAddress(appliance.address!),
                          Colors.blue[50]!,
                          Colors.blue[700]!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                appliance.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appliance.isAvailable
                              ? 'Beschikbaar'
                              : 'Niet beschikbaar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                appliance.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: appliance.isAvailable,
                          onChanged: (value) async {
                            try {
                              await _applianceService.updateAppliance(
                                appliance.id!,
                                {'isAvailable': value},
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Fout bij updaten beschikbaarheid: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          activeColor: Colors.blue[700],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue[700]),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/edit_appliance',
                              arguments: appliance,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Apparaat Verwijderen'),
                                    content: const Text(
                                      'Weet je zeker dat je dit apparaat wilt verwijderen?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Annuleren'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Verwijderen',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              try {
                                await _applianceService.deleteAppliance(
                                  appliance.id!,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Apparaat verwijderd'),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fout bij verwijderen: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color bgColor,
    Color fgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: fgColor)),
        ],
      ),
    );
  }

  String _getCityFromAddress(String address) {
    if (address.isEmpty) {
      return 'Onbekend';
    }

    final parts = address.split(',');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return address.trim();
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Je moet ingelogd zijn.'));
    }

    return StreamBuilder<List<Appliance>>(
      stream: _applianceService.getUserAppliances(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Er is iets fout gegaan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.blue[200],
                ),
                const SizedBox(height: 16),
                Text(
                  'Geen apparaten gevonden',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Je hebt nog geen apparaten toegevoegd om te verhuren',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_appliance');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Apparaat Toevoegen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mijn Apparaten (${snapshot.data!.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_appliance');
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Toevoegen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final appliance = snapshot.data![index];
                    return _buildApplianceCard(context, appliance);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
