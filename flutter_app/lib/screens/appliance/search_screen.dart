import 'package:flutter/material.dart';
import '/models/appliance.dart';
import '/services/appliance_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApplianceService _applianceService = ApplianceService();
  final TextEditingController _searchController = TextEditingController();
  
  String _activeCategory = '';
  String _searchQuery = '';
  bool _isSearching = false;

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
    _activeCategory = _categories[0]['name'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Zoek apparaten...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Zoeken'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
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
                            color: isActive ? Colors.blue[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category['icon'],
                            color: isActive ? Colors.white : Colors.grey[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: isActive ? Colors.blue[700] : Colors.grey[700],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Search results
          Expanded(
            child: _buildApplianceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceList() {
    if (_searchQuery.isNotEmpty) {
      return StreamBuilder<List<Appliance>>(
        stream: _applianceService.searchAppliances(_searchQuery),
        builder: (context, snapshot) {
          return _buildListView(snapshot);
        },
      );
    } else if (_activeCategory != 'Alle') {
      return StreamBuilder<List<Appliance>>(
        stream: _applianceService.getAppliancesByCategory(_activeCategory),
        builder: (context, snapshot) {
          return _buildListView(snapshot);
        },
      );
    } else {
      return StreamBuilder<List<Appliance>>(
        stream: _applianceService.getAppliances(),
        builder: (context, snapshot) {
          return _buildListView(snapshot);
        },
      );
    }
  }

  Widget _buildListView(AsyncSnapshot<List<Appliance>> snapshot) {
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
              _searchQuery.isNotEmpty
                  ? 'Probeer een andere zoekopdracht'
                  : 'Er zijn geen apparaten in deze categorie',
              style: TextStyle(
                color: Colors.grey[600],
              ),
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
        return _buildApplianceCard(appliance);
      },
    );
  }

  Widget _buildApplianceCard(Appliance appliance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to detail page
          // We'll implement this next
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: appliance.imageUrl != null && appliance.imageUrl!.isNotEmpty
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
            
            // Content
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
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
      child: Center(
        child: Icon(
          icon,
          size: 60,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}