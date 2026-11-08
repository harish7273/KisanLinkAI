import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String name;
  final String phone;
  final String email;

  final String gender;
  final String dob;

  final String state;
  final String district;
  final String village;

  final String? farmName;
  final String primaryCrop;
  final String farmSize;

  final Timestamp createdAt;

  // Verification & Trust
  final bool isVerified;
  final String kycStatus; // 'not_submitted', 'pending', 'approved', 'rejected'
  final Map<String, dynamic>? kycDocs;
  final String? rejectionReason;
  final double trustScore;
  final double rating;

  // Wallet & Payments
  final double walletBalance;
  final String? upiId;
  final String? bankAccount;
  final String? bankIfsc;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.email,

    required this.gender,
    required this.dob,

    required this.state,
    required this.district,
    required this.village,

    this.farmName,

    required this.primaryCrop,
    required this.farmSize,

    required this.createdAt,

    this.isVerified = false,
    this.kycStatus = 'not_submitted',
    this.kycDocs,
    this.rejectionReason,
    this.trustScore = 5.0,
    this.rating = 5.0,

    this.walletBalance = 0.0,
    this.upiId,
    this.bankAccount,
    this.bankIfsc,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,

      'gender': gender,
      'dob': dob,

      'state': state,
      'district': district,
      'village': village,

      'farmName': farmName,

      'primaryCrop': primaryCrop,
      'farmSize': farmSize,

      'createdAt': createdAt,

      'isVerified': isVerified,
      'kycStatus': kycStatus,
      'kycDocs': kycDocs,
      'rejectionReason': rejectionReason,
      'trustScore': trustScore,
      'rating': rating,

      'walletBalance': walletBalance,
      'upiId': upiId,
      'bankAccount': bankAccount,
      'bankIfsc': bankIfsc,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      role: map['role'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',

      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',

      state: map['state'] ?? '',
      district: map['district'] ?? '',
      village: map['village'] ?? '',

      farmName: map['farmName'],

      primaryCrop: map['primaryCrop'] ?? '',
      farmSize: map['farmSize'] ?? '',

      createdAt: map['createdAt'] ?? Timestamp.now(),

      isVerified: map['isVerified'] ?? false,
      kycStatus: map['kycStatus'] ?? 'not_submitted',
      kycDocs: map['kycDocs'] as Map<String, dynamic>?,
      rejectionReason: map['rejectionReason'],
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 5.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,

      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      upiId: map['upiId'],
      bankAccount: map['bankAccount'],
      bankIfsc: map['bankIfsc'],
    );
  }
}
