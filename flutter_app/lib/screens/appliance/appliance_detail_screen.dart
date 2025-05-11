import 'package:flutter/material.dart';
import '../../models/appliance.dart';

class ApplianceDetailScreen extends StatelessWidget {
  const ApplianceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Appliance appliance = ModalRoute.of(context)!.settings.arguments as Appliance;

    return Scaffold(
      appBar: AppBar(
        title: Text(appliance.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appliance.imageUrl != null && appliance.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  appliance.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage(appliance.category);
                  },
                ),
              )
            else
              _buildPlaceholderImage(appliance.category),
            const SizedBox(height: 16),
            Text(
              appliance.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '€${appliance.pricePerDay.toStringAsFixed(2)}/dag',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(appliance.category),
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  appliance.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
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
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
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
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Beschrijving',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appliance.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tuingereedschap':
        return Icons.grass;
      case 'Keuken':
        return Icons.kitchen;
      case 'Gereedschap':
        return Icons.construction;
      case 'Elektronica':
        return Icons.devices;
      case 'Schoonmaak':
        return Icons.cleaning_services;
      case 'Sport':
        return Icons.sports_soccer;
      default:
        return Icons.devices_other;
    }
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
      case 'Sport':
        icon = Icons.sports_soccer;
        break;
      default:
        icon = Icons.devices_other;
    }
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          icon,
          size: 60,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}