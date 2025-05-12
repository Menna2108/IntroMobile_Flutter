import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String? id;
  final String applianceId;
  final String applianceTitle;
  final String renterId;
  final String renterName;
  final String ownerId;
  final String ownerName;
  final DateTime startDate;
  final int days;
  final double totalPrice;
  final DateTime createdAt;
  final String status;

  Reservation({
    this.id,
    required this.applianceId,
    required this.applianceTitle,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    required this.ownerName,
    required this.startDate,
    required this.days,
    required this.totalPrice,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'applianceId': applianceId,
      'applianceTitle': applianceTitle,
      'renterId': renterId,
      'renterName': renterName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'startDate': Timestamp.fromDate(startDate),
      'days': days,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map, String id) {
    return Reservation(
      id: id,
      applianceId: map['applianceId'] ?? '',
      applianceTitle: map['applianceTitle'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      days: map['days'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}
