import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  _ReservationsScreenState createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showRenterReservations = true;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Je moet ingelogd zijn.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mijn Reserveringen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Mijn Huur'),
                  selected: _showRenterReservations,
                  onSelected: (selected) {
                    setState(() {
                      _showRenterReservations = true;
                    });
                  },
                  selectedColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color:
                        _showRenterReservations ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Mijn Verhuur'),
                  selected: !_showRenterReservations,
                  onSelected: (selected) {
                    setState(() {
                      _showRenterReservations = false;
                    });
                  },
                  selectedColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color:
                        !_showRenterReservations ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Reservation>>(
              stream:
                  _showRenterReservations
                      ? _reservationService.getRenterReservations(user.uid)
                      : _reservationService.getOwnerReservations(user.uid),
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
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showRenterReservations
                              ? 'Geen huurreserveringen'
                              : 'Geen verhuurreserveringen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final reservations = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return _buildReservationCard(context, reservation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation reservation) {
    final isOwner = !_showRenterReservations;
    final endDate = reservation.startDate.add(Duration(days: reservation.days));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reservation.applianceTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  isOwner ? reservation.renterName : reservation.ownerName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(reservation.startDate)} - '
                  '${DateFormat('dd MMM yyyy').format(endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '€${reservation.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Status: ${reservation.status}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (isOwner && reservation.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _reservationService.updateReservationStatus(
                          reservation.id!,
                          'confirmed',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reservering bevestigd'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Bevestigen'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _reservationService.updateReservationStatus(
                          reservation.id!,
                          'cancelled',
                        );
                        // Zet het apparaat weer beschikbaar
                        await FirebaseFirestore.instance
                            .collection('appliances')
                            .doc(reservation.applianceId)
                            .update({'isAvailable': true});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reservering geannuleerd'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuleren'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
