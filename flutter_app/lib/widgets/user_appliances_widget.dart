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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                const SizedBox(height: 8),
                Text(
                  appliance.description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appliance.category,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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
                if (appliance.address != null && appliance.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appliance.address!,
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Beschikbaar',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      const Spacer(),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
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
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
          ),
        ],
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
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Je moet ingelogd zijn.'));
    }

    return StreamBuilder<List<Appliance>>(
      stream: _applianceService.getUserAppliances(user.uid),
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
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
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
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final appliance = snapshot.data![index];
            return _buildApplianceCard(context, appliance);
          },
        );
      },
    );
  }
}
