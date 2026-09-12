import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final double itemTotal;
  final String farmerId;
  final String farmerName;
  final String image;
  final String location;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.quantity,
    this.unit = 'Kg',
    required this.price,
    required this.itemTotal,
    this.farmerId = '',
    this.farmerName = '',
    this.image = '',
    this.location = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'itemTotal': itemTotal,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'image': image,
      'location': location,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Product',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit']?.toString() ?? 'Kg',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (map['itemTotal'] as num?)?.toDouble() ?? 0.0,
      farmerId: map['farmerId']?.toString() ?? '',
      farmerName: map['farmerName']?.toString() ?? 'Farmer',
      image: map['image']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
    );
  }
}

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String deliveryAddress;

  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String farmerLocation;

  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;

  final String paymentMethod;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  final String orderStatus;
  final String deliveryStatus;

  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String? deliveryPartnerVehicle;

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final double? distanceKm;

  final String? pickupOtp;
  final String? deliveryOtp;

  final String? cancellationReason;
  final String? cancelledBy;

  final Timestamp? createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? preparingAt;
  final Timestamp? readyAt;
  final Timestamp? assignedAt;
  final Timestamp? pickedUpAt;
  final Timestamp? deliveredAt;
  final Timestamp? cancelledAt;
  final Timestamp? updatedAt;

  const OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.deliveryAddress,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    this.farmerLocation = '',
    required this.items,
    required this.subtotal,
    this.deliveryFee = 40.0,
    required this.totalAmount,
    this.paymentMethod = 'UPI',
    this.paymentStatus = 'Pending',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.orderStatus = 'Placed',
    this.deliveryStatus = 'Pending',
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    this.deliveryPartnerVehicle,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.distanceKm,
    this.pickupOtp,
    this.deliveryOtp,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.updatedAt,
  });

  // Convenience getters
  String get firstProductName => items.isNotEmpty ? items.first.name : 'Crop Item';
  String get firstProductImage => items.isNotEmpty ? items.first.image : '';
  double get firstProductQuantity => items.isNotEmpty ? items.first.quantity : 1.0;
  String get firstProductUnit => items.isNotEmpty ? items.first.unit : 'Kg';

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'deliveryAddress': deliveryAddress,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'farmerLocation': farmerLocation,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'orderStatus': orderStatus,
      'deliveryStatus': deliveryStatus,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'deliveryPartnerPhone': deliveryPartnerPhone,
      'deliveryPartnerVehicle': deliveryPartnerVehicle,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropLatitude': dropLatitude,
      'dropLongitude': dropLongitude,
      'distanceKm': distanceKm,
      'pickupOtp': pickupOtp,
      'deliveryOtp': deliveryOtp,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'acceptedAt': acceptedAt,
      'preparingAt': preparingAt,
      'readyAt': readyAt,
      'assignedAt': assignedAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
      'cancelledAt': cancelledAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    // Parse items list gracefully
    final rawItems = map['items'];
    final List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          parsedItems.add(OrderItemModel.fromMap(it));
        } else if (it is Map) {
          parsedItems.add(OrderItemModel.fromMap(Map<String, dynamic>.from(it)));
        }
      }
    }

    // If items empty (older order record compatibility)
    if (parsedItems.isEmpty && map['productName'] != null) {
      parsedItems.add(
        OrderItemModel(
          productId: map['productId']?.toString() ?? '',
          name: map['productName']?.toString() ?? 'Product',
          quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
          price: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
          itemTotal: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
          farmerId: map['farmerId']?.toString() ?? '',
          farmerName: map['farmerName']?.toString() ?? 'Farmer',
        ),
      );
    }

    return OrderModel(
      orderId: documentId ?? (map['orderId']?.toString() ?? ''),
      buyerId: map['buyerId']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? 'Buyer',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      farmerId: map['farmerId']?.toString() ?? '',
      farmerName: map['farmerName']?.toString() ?? 'Farmer',
      farmerPhone: map['farmerPhone']?.toString() ?? '',
      farmerLocation: map['farmerLocation']?.toString() ?? '',
      items: parsedItems,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? ((map['totalAmount'] as num?)?.toDouble() ?? 0.0),
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 40.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'UPI',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Pending',
      razorpayOrderId: map['razorpayOrderId']?.toString(),
      razorpayPaymentId: map['razorpayPaymentId']?.toString(),
      razorpaySignature: map['razorpaySignature']?.toString(),
      orderStatus: map['orderStatus']?.toString() ?? 'Placed',
      deliveryStatus: map['deliveryStatus']?.toString() ?? 'Pending',
      deliveryPartnerId: map['deliveryPartnerId']?.toString(),
      deliveryPartnerName: map['deliveryPartnerName']?.toString(),
      deliveryPartnerPhone: map['deliveryPartnerPhone']?.toString(),
      deliveryPartnerVehicle: map['deliveryPartnerVehicle']?.toString(),
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble(),
      dropLatitude: (map['dropLatitude'] as num?)?.toDouble(),
      dropLongitude: (map['dropLongitude'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      pickupOtp: map['pickupOtp']?.toString(),
      deliveryOtp: map['deliveryOtp']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
      cancelledBy: map['cancelledBy']?.toString(),
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      acceptedAt: map['acceptedAt'] is Timestamp ? map['acceptedAt'] : null,
      preparingAt: map['preparingAt'] is Timestamp ? map['preparingAt'] : null,
      readyAt: map['readyAt'] is Timestamp ? map['readyAt'] : null,
      assignedAt: map['assignedAt'] is Timestamp ? map['assignedAt'] : null,
      pickedUpAt: map['pickedUpAt'] is Timestamp ? map['pickedUpAt'] : null,
      deliveredAt: map['deliveredAt'] is Timestamp ? map['deliveredAt'] : null,
      cancelledAt: map['cancelledAt'] is Timestamp ? map['cancelledAt'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
    );
  }
}