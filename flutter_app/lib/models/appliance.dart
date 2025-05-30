class Appliance {
  final String? id;
  final String title;
  final String description;
  final String category;
  final double pricePerDay;
  final String userId;
  final String userName;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String? address;

  Appliance({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pricePerDay,
    required this.userId,
    required this.userName,
    this.imageUrl,
    required this.createdAt,
    this.isAvailable = true,
    this.latitude,
    this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'pricePerDay': pricePerDay,
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory Appliance.fromMap(Map<String, dynamic> map, String id) {
    return Appliance(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isAvailable: map['isAvailable'] ?? true,
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
    );
  }
}