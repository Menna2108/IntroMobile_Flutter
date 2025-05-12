import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/reservation.dart';
import 'package:flutter_app/services/reservation_service.dart';
import '../../models/appliance.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ApplianceDetailScreen extends StatefulWidget {
  const ApplianceDetailScreen({super.key});

  @override
  State<ApplianceDetailScreen> createState() => _ApplianceDetailScreenState();
}

class _ApplianceDetailScreenState extends State<ApplianceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAppBarExpanded = false;
  int _selectedDays = 1;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = true;
      });
    } else if (_scrollController.offset <= 200 && _isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Appliance appliance =
        ModalRoute.of(context)!.settings.arguments as Appliance;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[700],
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.2), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title:
                  _isAppBarExpanded
                      ? Text(
                        appliance.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (appliance.imageUrl != null &&
                        appliance.imageUrl!.isNotEmpty)
                      Hero(
                        tag: "appliance-image-${appliance.id}",
                        child: Image.network(
                          appliance.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(appliance.category);
                          },
                        ),
                      )
                    else
                      _buildPlaceholderImage(appliance.category),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(
                              0,
                              0,
                              0,
                              0.7,
                            ),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '€${appliance.pricePerDay.toStringAsFixed(2)}/dag',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appliance.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(appliance),
              const SizedBox(height: 24),
              _buildOwnerInfo(appliance),
              const SizedBox(height: 24),
              const Text(
                'Beschrijving',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(
                        128,
                        128,
                        128,
                        0.1,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  appliance.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRentalSelector(appliance),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: ElevatedButton(
          onPressed: () async {
            final user = _auth.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Je moet ingelogd zijn om te reserveren'),
                ),
              );
              return;
            }

            try {             
              final userData =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();
              final renterName =
                  userData.exists && userData.data() != null
                      ? userData.data()!['name'] ??
                          user.email?.split('@')[0] ??
                          'Huurder'
                      : user.email?.split('@')[0] ?? 'Huurder';

              final reservation = Reservation(
                applianceId: appliance.id!,
                applianceTitle: appliance.title,
                renterId: user.uid,
                renterName: renterName,
                ownerId: appliance.userId,
                ownerName: appliance.userName,
                startDate: _startDate,
                days: _selectedDays,
                totalPrice: appliance.pricePerDay * _selectedDays,
                createdAt: DateTime.now(),
                status: 'pending',
              );

              await _reservationService.addReservation(reservation);

              await FirebaseFirestore.instance
                  .collection('appliances')
                  .doc(appliance.id)
                  .update({'isAvailable': false});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservering succesvol aangemaakt!'),
                ),
              );

              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fout bij reserveren: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Reserveren - €${(appliance.pricePerDay * _selectedDays).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoRow(Appliance appliance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.1), 
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            _getCategoryIcon(appliance.category),
            appliance.category,
            'Categorie',
          ),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildInfoItem(
            Icons.check_circle_outline,
            appliance.isAvailable ? 'Beschikbaar' : 'Niet beschikbaar',
            'Status',
            color: appliance.isAvailable ? Colors.green : Colors.red,
          ),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildInfoItem(
            Icons.location_on_outlined,
            _getCityFromAddress(appliance.address),
            'Locatie',
          ),
        ],
      ),
    );
  }

  String _getCityFromAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Onbekend';
    }

    final parts = address.split(',');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return address.trim();
  }

  Widget _buildInfoItem(
    IconData icon,
    String text,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue[700], size: 22),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildOwnerInfo(Appliance appliance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.1), 
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Text(
              appliance.userName.isNotEmpty
                  ? appliance.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eigenaar',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  appliance.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (appliance.address != null && appliance.address!.isNotEmpty)
                  Text(
                    appliance.address!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalSelector(Appliance appliance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.1), 
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Huurperiode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  'Start datum: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_calendar, size: 20),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aantal dagen',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int days in [1, 2, 3, 7, 14, 30])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDays = days;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            _selectedDays == days
                                ? Colors.blue[700]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _selectedDays == days
                                  ? Colors.white
                                  : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prijs per dag:', style: TextStyle(fontSize: 16)),
              Text(
                '€${appliance.pricePerDay.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Totaal voor $_selectedDays dagen:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '€${(appliance.pricePerDay * _selectedDays).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
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
    IconData icon = _getCategoryIcon(category);
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(child: Icon(icon, size: 80, color: Colors.grey[400])),
    );
  }
}
