import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPartnerModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String profileImage;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final bool isOnline;
  final double currentLat;
  final double currentLng;
  final String? activeOrderId;
  final int totalDeliveries;
  final int todayDeliveries;
  final int inProgressDeliveries;
  final double rating;
  final String verificationStatus;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const DeliveryPartnerModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.profileImage = '',
    required this.vehicleType,
    required this.vehicleNumber,
    this.licenseNumber = '',
    this.isOnline = false,
    this.currentLat = 0.0,
    this.currentLng = 0.0,
    this.activeOrderId,
    this.totalDeliveries = 0,
    this.todayDeliveries = 0,
    this.inProgressDeliveries = 0,
    this.rating = 5.0,
    this.verificationStatus = 'verified',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'isOnline': isOnline,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'activeOrderId': activeOrderId,
      'totalDeliveries': totalDeliveries,
      'todayDeliveries': todayDeliveries,
      'inProgressDeliveries': inProgressDeliveries,
      'rating': rating,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory DeliveryPartnerModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return DeliveryPartnerModel(
      uid: documentId ?? (map['uid']?.toString() ?? ''),
      name: map['name']?.toString() ?? 'Delivery Partner',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      profileImage: map['profileImage']?.toString() ?? '',
      vehicleType: map['vehicleType']?.toString() ?? 'Bike',
      vehicleNumber: map['vehicleNumber']?.toString() ?? '',
      licenseNumber: map['licenseNumber']?.toString() ?? '',
      isOnline: map['isOnline'] == true,
      currentLat: (map['currentLat'] as num?)?.toDouble() ?? 0.0,
      currentLng: (map['currentLng'] as num?)?.toDouble() ?? 0.0,
      activeOrderId: map['activeOrderId']?.toString(),
      totalDeliveries: (map['totalDeliveries'] as num?)?.toInt() ?? 0,
      todayDeliveries: (map['todayDeliveries'] as num?)?.toInt() ?? 0,
      inProgressDeliveries: (map['inProgressDeliveries'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      verificationStatus: map['verificationStatus']?.toString() ?? 'verified',
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : Timestamp.now(),
    );
  }

  DeliveryPartnerModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? activeOrderId,
    int? totalDeliveries,
    int? todayDeliveries,
    int? inProgressDeliveries,
    double? rating,
    String? verificationStatus,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return DeliveryPartnerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      inProgressDeliveries: inProgressDeliveries ?? this.inProgressDeliveries,
      rating: rating ?? this.rating,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
