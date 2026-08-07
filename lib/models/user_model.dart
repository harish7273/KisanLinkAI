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
    );
  }
}