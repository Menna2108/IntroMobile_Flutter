import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance.dart';
import '../services/appliance_service.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  final String? categoryFilter;

  const MapScreen({super.key, this.categoryFilter});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApplianceService _applianceService = ApplianceService();

  LatLng _currentPosition = const LatLng(51.221340, 4.405150);
  double _currentZoom = 13.0;
  bool _isLoading = true;
  List<Appliance> _appliances = [];
  double _maxDistance = 10.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userData.exists &&
            userData.data() != null &&
            userData.data()!['latitude'] != null &&
            userData.data()!['longitude'] != null) {
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(
                userData.data()!['latitude'] as double,
                userData.data()!['longitude'] as double,
              );
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(_currentPosition, _currentZoom);
              }
            });
          }
          await _loadAppliances();
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Locatieservices zijn uitgeschakeld. Standaardlocatie wordt gebruikt.',
              ),
            ),
          );
          setState(() {
            _currentPosition = const LatLng(51.221340, 4.405150);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_currentPosition, _currentZoom);
            }
          });
        }
        await _loadAppliances();
        return;
      }

      PermissionStatus permissionStatus = await Permission.location.request();
      if (permissionStatus.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_currentPosition, _currentZoom);
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Locatietoestemming geweigerd. Standaardlocatie wordt gebruikt.',
              ),
            ),
          );
          setState(() {
            _currentPosition = const LatLng(51.221340, 4.405150);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(_currentPosition, _currentZoom);
            }
          });
        }
      }

      await _loadAppliances();
    } catch (e) {
      debugPrint('Fout bij initialiseren kaart: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout bij laden van kaart: $e')));
        setState(() {
          _currentPosition = const LatLng(51.221340, 4.405150);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_currentPosition, _currentZoom);
          }
        });
      }
      await _loadAppliances();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppliances() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Stream<List<Appliance>> applianceStream =
          widget.categoryFilter != null && widget.categoryFilter != 'Alle'
              ? _applianceService.getAppliancesByCategory(
                widget.categoryFilter!,
              )
              : _applianceService.getAppliances();

      applianceStream.listen(
        (appliances) {
          if (mounted) {
            final filteredAppliances =
                appliances
                    .where((appliance) => appliance.userId != user.uid)
                    .where(
                      (appliance) =>
                          appliance.latitude != null &&
                          appliance.longitude != null,
                    )
                    .where((appliance) => appliance.isAvailable)
                    .where((appliance) {
                      double distanceInMeters = Geolocator.distanceBetween(
                        _currentPosition.latitude,
                        _currentPosition.longitude,
                        appliance.latitude!,
                        appliance.longitude!,
                      );
                      double distanceInKm = distanceInMeters / 1000;
                      bool withinDistance = distanceInKm <= _maxDistance;
                      debugPrint(
                        'Appliance: ${appliance.title}, Distance: $distanceInKm km, Within Range: $withinDistance',
                      );
                      return withinDistance;
                    })
                    .toList();

            setState(() {
              _appliances = filteredAppliances;
            });

            debugPrint('Loaded ${_appliances.length} appliances on map');
            for (var appliance in _appliances) {
              debugPrint(
                'Appliance on map: ${appliance.title}, Lat: ${appliance.latitude}, Lng: ${appliance.longitude}, Available: ${appliance.isAvailable}',
              );
            }
          }
        },
        onError: (e) {
          debugPrint('Fout bij laden apparaten: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fout bij laden apparaten: $e')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Fout bij laden apparaten: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout bij laden apparaten: $e')));
      }
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentPosition, 15.0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryFilter != null && widget.categoryFilter != 'Alle'
              ? widget.categoryFilter!
              : 'Apparaten',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: _currentZoom,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture && mounted) {
                          setState(() {
                            _currentZoom = position.zoom;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.boromi',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _currentPosition,
                            radius: _maxDistance * 1000,
                            useRadiusInMeter: true,
                            color: const Color.fromRGBO(255, 0, 0, 0.1),
                            borderColor: Colors.red,
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: _currentPosition,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(0, 0, 255, 0.298),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                          ..._buildApplianceMarkers(),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_appliances.length} ${_appliances.length == 1 ? 'apparaat' : 'apparaten'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                    arguments: widget.categoryFilter,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Lijst weergave'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'Max. afstand: ',
                                style: TextStyle(fontSize: 14),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _maxDistance,
                                  min: 1.0,
                                  max: 50.0,
                                  divisions: 49,
                                  label:
                                      '${_maxDistance.toStringAsFixed(1)} km',
                                  onChanged: (value) {
                                    setState(() {
                                      _maxDistance = value;
                                      _currentZoom =
                                          15.0 - (_maxDistance / 5.0);
                                      _currentZoom = _currentZoom.clamp(
                                        3.0,
                                        18.0,
                                      );
                                      _mapController.move(
                                        _currentPosition,
                                        _currentZoom,
                                      );
                                    });
                                    _loadAppliances();
                                  },
                                  activeColor: Colors.blue[700],
                                  inactiveColor: Colors.blue[200],
                                ),
                              ),
                              Text(
                                '${_maxDistance.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 140,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'zoomInButton',
                          backgroundColor: Colors.white,
                          mini: true,
                          onPressed: () {
                            setState(() {
                              _currentZoom = (_currentZoom + 1).clamp(
                                3.0,
                                18.0,
                              );
                              _mapController.move(
                                _currentPosition,
                                _currentZoom,
                              );
                            });
                          },
                          child: Icon(Icons.zoom_in, color: Colors.blue[700]),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'zoomOutButton',
                          backgroundColor: Colors.white,
                          mini: true,
                          onPressed: () {
                            setState(() {
                              _currentZoom = (_currentZoom - 1).clamp(
                                3.0,
                                18.0,
                              );
                              _mapController.move(
                                _currentPosition,
                                _currentZoom,
                              );
                            });
                          },
                          child: Icon(Icons.zoom_out, color: Colors.blue[700]),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'locationButton',
                          backgroundColor: Colors.white,
                          mini: true,
                          onPressed: _centerOnCurrentLocation,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  List<Marker> _buildApplianceMarkers() {
    
    Map<String, List<Appliance>> groupedAppliances = {};
    for (var appliance in _appliances) {
      final key = '${appliance.latitude},${appliance.longitude}';
      if (!groupedAppliances.containsKey(key)) {
        groupedAppliances[key] = [];
      }
      groupedAppliances[key]!.add(appliance);
    }
    List<Marker> markers = [];
    groupedAppliances.forEach((key, appliances) {
      if (appliances.length == 1) {
        
        final appliance = appliances.first;
        final markerPosition = LatLng(
          appliance.latitude!,
          appliance.longitude!,
        );
        markers.add(_createMarker(appliance, markerPosition));
      } else {
        
        final originalPosition = LatLng(
          appliances.first.latitude!,
          appliances.first.longitude!,
        );
        for (int i = 0; i < appliances.length; i++) {
          final appliance = appliances[i];
          
          const double offsetDistance =
              0.0003; 
          final double angle = (2 * math.pi / appliances.length) * i;
          final double offsetLat = offsetDistance * math.cos(angle);
          final double offsetLng = offsetDistance * math.sin(angle);
          final adjustedPosition = LatLng(
            originalPosition.latitude + offsetLat,
            originalPosition.longitude + offsetLng,
          );
          markers.add(_createMarker(appliance, adjustedPosition));
        }
      }
    });

    return markers;
  }

  Marker _createMarker(Appliance appliance, LatLng position) {
    return Marker(
      width: 150.0,
      height: 60.0,
      point: position,
      child: GestureDetector(
        onTap: () => _showApplianceDetails(appliance),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getCategoryIcon(appliance.category), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '€${appliance.pricePerDay.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 2, height: 6, color: Colors.grey),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                shape: BoxShape.circle,
              ),
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

  void _showApplianceDetails(Appliance appliance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            maxChildSize: 0.6,
            minChildSize: 0.3,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          appliance.imageUrl != null &&
                                  appliance.imageUrl!.isNotEmpty
                              ? Image.network(
                                appliance.imageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage(
                                    appliance.category,
                                  );
                                },
                              )
                              : _buildPlaceholderImage(appliance.category),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appliance.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/appliance_detail',
                            arguments: appliance,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Bekijk details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
      case 'Sport':
        icon = Icons.sports_soccer;
        break;
      default:
        icon = Icons.devices_other;
    }
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(child: Icon(icon, size: 60, color: Colors.grey[400])),
    );
  }
}
