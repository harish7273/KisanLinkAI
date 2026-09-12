import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataSeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Set<String> _seededUids = <String>{};

  /// Ensures that the current farmer has a synced profile name, starter products,
  /// starter orders, and active market auctions in Firestore.
  static Future<void> ensureFarmerDataSeeded({
    required String farmerUid,
    required String farmerName,
    String? phone,
    bool force = false,
  }) async {
    if (farmerUid.isEmpty) return;

    if (!force && _seededUids.contains(farmerUid)) {
      debugPrint(
          '🌱 [DataSeedService] Farmer $farmerUid already seeded/verified in this session. Skipping redundant queries.');
      return;
    }

    final cleanName = farmerName.trim().isNotEmpty ? farmerName.trim() : 'Farmer';

    debugPrint('🌱 [DataSeedService] Checking seed data for farmer $farmerUid ($cleanName)...');

    try {
      // 1. Sync Profile Data across both collections
      await _syncProfile(
        farmerUid: farmerUid,
        farmerName: cleanName,
        phone: phone,
      );

      // 2. Ensure Farmer Products exist
      await _ensureProducts(
        farmerUid: farmerUid,
        farmerName: cleanName,
        phone: phone,
      );

      // 3. Ensure Farmer Orders exist
      await _ensureOrders(
        farmerUid: farmerUid,
        farmerName: cleanName,
      );

      // 4. Ensure Auctions exist
      await _ensureAuctions(
        farmerUid: farmerUid,
        farmerName: cleanName,
      );

      _seededUids.add(farmerUid);
      debugPrint('✅ [DataSeedService] Data seeding verified successfully.');
    } catch (e) {
      debugPrint('⚠️ [DataSeedService] Error during seeding: $e');
    }
  }

  // ========================================================================
  // 1. PROFILE SYNC
  // ========================================================================
  static Future<void> _syncProfile({
    required String farmerUid,
    required String farmerName,
    String? phone,
  }) async {
    final profileUpdate = <String, dynamic>{
      'uid': farmerUid,
      'name': farmerName,
      'role': 'farmer',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (phone != null && phone.trim().isNotEmpty) {
      profileUpdate['phone'] = phone.trim();
    }

    await Future.wait([
      _firestore.collection('farmers').doc(farmerUid).set(
            profileUpdate,
            SetOptions(merge: true),
          ),
      _firestore.collection('users').doc(farmerUid).set(
            profileUpdate,
            SetOptions(merge: true),
          ),
    ]);
  }

  // ========================================================================
  // 2. ENSURE PRODUCTS
  // ========================================================================
  static Future<void> _ensureProducts({
    required String farmerUid,
    required String farmerName,
    String? phone,
  }) async {
    final existing = await _firestore
        .collection('products')
        .where('farmerId', isEqualTo: farmerUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return; // Already has products
    }

    debugPrint('🌱 [DataSeedService] Seeding initial products for $farmerName...');

    final starterProducts = [
      {
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'farmerPhone': phone?.isNotEmpty == true ? phone : '+91 9842231567',
        'name': 'Organic Tomato (Fresh Harvest)',
        'category': 'Vegetable',
        'price': 28.0,
        'quantity': 80.0,
        'unit': 'kg',
        'location': 'Coimbatore',
        'image': 'assets/products/tomato.png',
        'description': 'Farm-fresh, chemical-free organic red tomatoes.',
        'qualityGrade': 'AGMARK Grade A',
        'certificateId': 'AGMARK-TN-2026-8819',
        'ripenessPercentage': 94.5,
        'defectPercentage': 1.6,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'farmerPhone': phone?.isNotEmpty == true ? phone : '+91 9842231567',
        'name': 'Sweet Golden Corn',
        'category': 'Grain',
        'price': 42.0,
        'quantity': 60.0,
        'unit': 'kg',
        'location': 'Pollachi',
        'image': 'assets/products/corn.png',
        'description': 'Tender sweet corn harvested directly from local fields.',
        'qualityGrade': 'AGMARK Grade A',
        'certificateId': 'AGMARK-TN-2026-9042',
        'ripenessPercentage': 96.0,
        'defectPercentage': 1.2,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'farmerPhone': phone?.isNotEmpty == true ? phone : '+91 9842231567',
        'name': 'Organic Mango (Alphonso)',
        'category': 'Fruit',
        'price': 120.0,
        'quantity': 100.0,
        'unit': 'kg',
        'location': 'Salem',
        'image': 'assets/products/mango.png',
        'description': 'Sweet and aromatic naturally ripened Alphonso mangoes.',
        'qualityGrade': 'AGMARK Grade A Premium',
        'certificateId': 'AGMARK-TN-2026-5518',
        'ripenessPercentage': 92.0,
        'defectPercentage': 2.0,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'farmerPhone': phone?.isNotEmpty == true ? phone : '+91 9842231567',
        'name': 'Green Spinach (Palak)',
        'category': 'Vegetable',
        'price': 25.0,
        'quantity': 150.0,
        'unit': 'bunch',
        'location': 'Erode',
        'image': 'assets/products/spinach.png',
        'description': 'Crisp, iron-rich green leaves picked fresh today morning.',
        'qualityGrade': 'AGMARK Grade A',
        'certificateId': 'AGMARK-TN-2026-3190',
        'ripenessPercentage': 98.0,
        'defectPercentage': 0.8,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _firestore.batch();
    for (final prod in starterProducts) {
      final docRef = _firestore.collection('products').doc();
      prod['id'] = docRef.id;
      batch.set(docRef, prod);
    }
    await batch.commit();
  }

  // ========================================================================
  // 3. ENSURE ORDERS
  // ========================================================================
  static Future<void> _ensureOrders({
    required String farmerUid,
    required String farmerName,
  }) async {
    final existing = await _firestore
        .collection('orders')
        .where('farmerId', isEqualTo: farmerUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return; // Already has orders
    }

    debugPrint('🌱 [DataSeedService] Seeding initial orders for $farmerName...');

    final starterOrders = [
      // Order 1: New / Placed Order (Transport unassigned - allows optional assignment by Farmer or Buyer)
      {
        'orderId': 'ORD-7821',
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'buyerId': 'buyer_kovai_001',
        'buyerName': 'Kovai Fresh Hypermarket',
        'buyerPhone': '+91 98421 88210',
        'deliveryAddress': '142, Cross Cut Road, RS Puram, Coimbatore, TN - 641002',
        'orderStatus': 'Placed',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI (Google Pay)',
        'totalAmount': 1400.0,
        'notes': 'Please pack in sturdy crates. Need early morning delivery.',
        'items': [
          {
            'productId': 'seed_prod_tomato',
            'name': 'Organic Tomato (Fresh Harvest)',
            'category': 'Vegetable',
            'price': 28.0,
            'quantity': 50.0,
            'unit': 'kg',
            'farmerId': farmerUid,
            'farmerName': farmerName,
            'imageUrl': 'assets/products/tomato.png',
            'itemTotal': 1400.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 15))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 15))),
      },

      // Order 2: In Progress / Preparing Order (with P. Selvam Reefer Express)
      {
        'orderId': 'ORD-6490',
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'buyerId': 'buyer_annamalai_002',
        'buyerName': 'Annamalai Organic Superstore',
        'buyerPhone': '+91 97890 33412',
        'deliveryAddress': '45, 7th Street, Gandhipuram, Coimbatore, TN - 641012',
        'orderStatus': 'Preparing',
        'paymentStatus': 'Pending (COD)',
        'paymentMethod': 'Cash on Delivery',
        'totalAmount': 3600.0,
        'notes': 'Confirmed order. Quality checked and verified.',
        'deliveryPartnerId': 'drv_selvam_4412',
        'deliveryPartnerName': 'P. Selvam',
        'deliveryPartnerPhone': '+91 94432 17890',
        'deliveryPartnerVehicle': 'Tata Ace Cold-Chain Reefer (2.2T)',
        'deliveryPartnerPlate': 'TN-38-BZ-4412',
        'driverRating': '4.9',
        'deliveryEstimate': '25 - 40 Mins Express',
        'safetyScore': '99.8% Zero-Damage • Correct Location Pin Guarantee',
        'assignedBy': 'mutual',
        'pickupOtp': '4821',
        'deliveryOtp': '7935',
        'reeferTemperature': '4°C',
        'estimatedPickupTime': 'Today, 2:30 PM',
        'pickupLatitude': 10.9984,
        'pickupLongitude': 76.9612,
        'dropLatitude': 11.0183,
        'dropLongitude': 76.9725,
        'items': [
          {
            'productId': 'seed_prod_banana',
            'name': 'Fresh Farm Bananas (Nendran)',
            'category': 'Fruit',
            'price': 45.0,
            'quantity': 80.0,
            'unit': 'kg',
            'farmerId': farmerUid,
            'farmerName': farmerName,
            'imageUrl': 'assets/products/banana.png',
            'itemTotal': 3600.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      },

      // Order 3: Completed / Delivered Order (M. Manikandan Bolero Heavy Delivery)
      {
        'orderId': 'ORD-5120',
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'buyerId': 'buyer_nilgiri_003',
        'buyerName': 'Nilgiri Green Mart',
        'buyerPhone': '+91 98433 77190',
        'deliveryAddress': '88, Thadagam Road, Saibaba Colony, Coimbatore, TN - 641011',
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI (PhonePe)',
        'totalAmount': 2100.0,
        'notes': 'Delivered safely without any produce damage.',
        'deliveryPartnerId': 'drv_manikandan_8921',
        'deliveryPartnerName': 'M. Manikandan',
        'deliveryPartnerPhone': '+91 98433 45210',
        'deliveryPartnerVehicle': 'Mahindra Bolero Maxi Truck Plus (2.5T)',
        'deliveryPartnerPlate': 'TN-37-CE-8921',
        'driverRating': '4.8',
        'deliveryEstimate': '35 - 50 Mins Direct',
        'safetyScore': '99.5% Safe Delivery • Direct Farm Route',
        'assignedBy': 'farmer',
        'pickupOtp': '3152',
        'deliveryOtp': '8841',
        'items': [
          {
            'productId': 'seed_prod_corn',
            'name': 'Sweet Golden Corn',
            'category': 'Grain',
            'price': 35.0,
            'quantity': 60.0,
            'unit': 'kg',
            'farmerId': farmerUid,
            'farmerName': farmerName,
            'imageUrl': 'assets/products/corn.png',
            'itemTotal': 2100.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
        'deliveredAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      },
    ];

    final batch = _firestore.batch();
    for (final ord in starterOrders) {
      final docRef = _firestore.collection('orders').doc(ord['orderId'] as String);
      batch.set(docRef, ord);
    }
    await batch.commit();
  }

  // ========================================================================
  // 4. ENSURE AUCTIONS
  // ========================================================================
  static Future<void> _ensureAuctions({
    required String farmerUid,
    required String farmerName,
  }) async {
    final existingMy = await _firestore
        .collection('auctions')
        .where('farmerId', isEqualTo: farmerUid)
        .limit(1)
        .get();

    final batch = _firestore.batch();
    bool hasUpdates = false;

    // Seed My Auction if none exists for this farmer
    if (existingMy.docs.isEmpty) {
      debugPrint('🌱 [DataSeedService] Seeding farmer auction for $farmerName...');
      final myAuctionRef = _firestore.collection('auctions').doc();
      final myAuction = {
        'id': myAuctionRef.id,
        'farmerId': farmerUid,
        'farmerName': farmerName,
        'productName': 'Sona Masoori Paddy (Grade A)',
        'category': 'Grains',
        'quantity': '500',
        'unit': 'kg',
        'quality': 'Grade A Premium',
        'startPrice': 38.0,
        'highestBid': 44.5,
        'highestBidder': 'Sri Murugan Modern Rice Mill',
        'bidCount': '7',
        'status': 'active',
        'startTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 28))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'location': 'Coimbatore',
        'imageAsset': '',
        'imageUrl': '',
      };
      batch.set(myAuctionRef, myAuction);
      hasUpdates = true;
    }

    // Also ensure general market active and upcoming auctions exist
    final generalActive = await _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .limit(2)
        .get();

    if (generalActive.docs.length < 2) {
      debugPrint('🌱 [DataSeedService] Seeding active market auctions...');
      final activeRef = _firestore.collection('auctions').doc();
      batch.set(activeRef, {
        'id': activeRef.id,
        'farmerId': 'farmer_market_002',
        'farmerName': 'K. Chinnasamy (Kongu Farms)',
        'productName': 'Organic Red Tomatoes',
        'category': 'Vegetables',
        'quantity': '300',
        'unit': 'kg',
        'quality': 'Field Fresh',
        'startPrice': 24.0,
        'highestBid': 31.0,
        'highestBidder': 'Kovai Fresh Hypermarket',
        'bidCount': '12',
        'status': 'active',
        'startTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 15))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'location': 'Tiruppur',
        'imageAsset': 'assets/products/tomato.png',
        'imageUrl': '',
      });
      hasUpdates = true;
    }

    final generalUpcoming = await _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'upcoming')
        .limit(1)
        .get();

    if (generalUpcoming.docs.isEmpty) {
      final upcomingRef = _firestore.collection('auctions').doc();
      batch.set(upcomingRef, {
        'id': upcomingRef.id,
        'farmerId': 'farmer_market_003',
        'farmerName': 'M. Palanisamy (Salem Orchards)',
        'productName': 'Salem Malgoa Mangoes',
        'category': 'Fruits',
        'quantity': '250',
        'unit': 'kg',
        'quality': 'Export Grade',
        'startPrice': 110.0,
        'highestBid': 110.0,
        'bidCount': '0',
        'status': 'upcoming',
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 12))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'location': 'Salem',
        'imageAsset': '',
        'imageUrl': '',
      });
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  // ========================================================================
  // 5. ENSURE DELIVERY ORDERS (Ready, In Progress, Delivered)
  // ========================================================================
  static Future<void> ensureDeliveryOrdersSeeded({
    bool force = false,
    String? partnerId,
  }) async {
    final existing = await _firestore
        .collection('orders')
        .where('orderStatus', whereIn: ['Ready', 'Ready for Pickup'])
        .limit(1)
        .get();

    final effectivePartner = (partnerId != null && partnerId.isNotEmpty)
        ? partnerId
        : 'partner_demo';

    if (existing.docs.isNotEmpty && !force) {
      // If starter orders already exist, ensure the logged-in partner's user doc has stats
      if (partnerId != null && partnerId.isNotEmpty) {
        try {
          final userDoc = await _firestore.collection('users').doc(partnerId).get();
          if (userDoc.exists) {
            final data = userDoc.data() ?? {};
            if ((data['todayDeliveries'] ?? 0) == 0 && (data['totalDeliveries'] ?? 0) == 0) {
              await _firestore.collection('users').doc(partnerId).update({
                'todayDeliveries': 4,
                'inProgressDeliveries': 2,
                'totalDeliveries': 48,
                'rating': 4.9,
                'verificationStatus': 'verified',
              });
            }
          }
        } catch (_) {}
      }
      return;
    }

    debugPrint('🌱 [DataSeedService] Seeding comprehensive delivery orders...');

    final batch = _firestore.batch();
    final starterDeliveryOrders = [
      // 1. Udumalpet to Ukkadam Real Road Route (~71.5 km)
      {
        'orderId': 'ORD-DEL-UDU-UKK',
        'farmerId': 'farmer_muthusamy_01',
        'farmerName': 'K. Muthusamy',
        'farmerPhone': '+91 98422 11980',
        'farmerLocation': 'Udumalpet Organic Farm, Tiruppur',
        'pickupAddress': 'Udumalpet Organic Farm, Tiruppur Dist, TN - 642126',
        'pickupLatitude': 10.5855,
        'pickupLongitude': 77.2492,
        'buyerId': 'buyer_kovai_004',
        'buyerName': 'Ukkadam Agro Wholesale Market',
        'buyerPhone': '+91 98421 55670',
        'deliveryAddress': 'Ukkadam Central Agro Market, Coimbatore, TN - 641001',
        'dropLatitude': 10.9930,
        'dropLongitude': 76.9600,
        'orderStatus': 'Ready for Pickup',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 15000.0,
        'deliveryFee': 550.0,
        'distanceKm': 71.5,
        'deliveryOtp': '4821',
        'pickupOtp': '1934',
        'notes': '500 kg Fresh Farm Tomatoes in crates. Cold-chain Reefer transport from Udumalpet to Ukkadam.',
        'items': [
          {
            'productId': 'seed_prod_tomato',
            'name': 'Organic Tomato (Fresh Harvest)',
            'category': 'Vegetable',
            'price': 30.0,
            'quantity': 500.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/tomato.png',
            'itemTotal': 15000.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 25))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
      },
      // 2. Pollachi to Gandhipuram Real Road Route (~44.0 km)
      {
        'orderId': 'ORD-DEL-POL-GAN',
        'farmerId': 'farmer_velusamy_02',
        'farmerName': 'R. Velusamy',
        'farmerPhone': '+91 97890 22340',
        'farmerLocation': 'Pollachi Agro Plantation, Coimbatore',
        'pickupAddress': 'Pollachi Agro Plantation, Pollachi, TN - 642001',
        'pickupLatitude': 10.6609,
        'pickupLongitude': 77.0048,
        'buyerId': 'buyer_annamalai_005',
        'buyerName': 'Gandhipuram Fresh Hub',
        'buyerPhone': '+91 98433 11220',
        'deliveryAddress': '78, 100 Feet Road, Gandhipuram, Coimbatore, TN - 641012',
        'dropLatitude': 11.0168,
        'dropLongitude': 76.9558,
        'orderStatus': 'Ready for Pickup',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 2400.0,
        'deliveryFee': 380.0,
        'distanceKm': 44.0,
        'deliveryOtp': '6719',
        'pickupOtp': '3502',
        'notes': 'Fragile nendran bananas, transport carefully along Pollachi-Coimbatore highway.',
        'items': [
          {
            'productId': 'seed_prod_banana',
            'name': 'Fresh Farm Bananas (Nendran)',
            'category': 'Fruit',
            'price': 40.0,
            'quantity': 60.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/banana.png',
            'itemTotal': 2400.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 40))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 10))),
      },
      {
        'orderId': 'ORD-DEL-7120',
        'farmerId': 'farmer_selvam_03',
        'farmerName': 'P. Selvaraj',
        'farmerPhone': '+91 94432 99810',
        'farmerLocation': 'Kinathukadavu Green Fields, Coimbatore',
        'pickupAddress': 'Kinathukadavu Green Fields, Coimbatore, TN - 642109',
        'pickupLatitude': 10.9750,
        'pickupLongitude': 76.9400,
        'buyerId': 'buyer_nilgiri_006',
        'buyerName': 'Nilgiri Daily Superstore',
        'buyerPhone': '+91 98433 77190',
        'deliveryAddress': '88, Thadagam Road, Saibaba Colony, Coimbatore, TN - 641011',
        'dropLatitude': 11.0250,
        'dropLongitude': 76.9450,
        'orderStatus': 'Ready for Pickup',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 1600.0,
        'deliveryFee': 190.0,
        'distanceKm': 6.5,
        'notes': 'Fresh sweet corn packed in jute bags.',
        'items': [
          {
            'productId': 'seed_prod_corn',
            'name': 'Sweet Golden Corn',
            'category': 'Grain',
            'price': 32.0,
            'quantity': 50.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/corn.png',
            'itemTotal': 1600.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 55))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 12))),
      },

      // 2. In Progress Deliveries (Active)
      {
        'orderId': 'ORD-DEL-5521',
        'farmerId': 'farmer_shanmugam_04',
        'farmerName': 'S. Shanmugam',
        'farmerPhone': '+91 94421 88990',
        'farmerLocation': 'Ooty Organic Hill Farms, Nilgiris',
        'pickupAddress': 'Ooty Organic Hill Farms, Ooty, Nilgiris, TN - 643001',
        'pickupLatitude': 11.4102,
        'pickupLongitude': 76.6950,
        'buyerId': 'buyer_kovai_004',
        'buyerName': 'Coimbatore Wholesale Mandi',
        'buyerPhone': '+91 98421 55670',
        'deliveryAddress': '22, Mettupalayam Road, Coimbatore, TN - 641043',
        'dropLatitude': 11.0315,
        'dropLongitude': 76.9580,
        'orderStatus': 'Picked Up',
        'paymentStatus': 'Paid',
        'paymentMethod': 'Bank Transfer',
        'totalAmount': 3150.0,
        'deliveryFee': 340.0,
        'distanceKm': 14.2,
        'deliveryPartnerId': effectivePartner,
        'deliveryPartnerName': 'Manikandan S.',
        'deliveryPartnerPhone': '+91 98422 77123',
        'deliveryPartnerVehicle': 'Tata Ace Reefer 2.2T',
        'notes': 'Root vegetables safely loaded in refrigerated bay.',
        'items': [
          {
            'productId': 'seed_prod_carrot',
            'name': 'Organic Tomato (Fresh Harvest)',
            'category': 'Vegetable',
            'price': 45.0,
            'quantity': 70.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/tomato.png',
            'itemTotal': 3150.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1, minutes: 15))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 18))),
      },
      {
        'orderId': 'ORD-DEL-4390',
        'farmerId': 'farmer_ranga_05',
        'farmerName': 'K. Ranganathan',
        'farmerPhone': '+91 98433 44550',
        'farmerLocation': 'Bhavani River Delta Mills, Erode',
        'pickupAddress': 'Bhavani River Delta Mills, Erode, TN - 638001',
        'pickupLatitude': 11.3410,
        'pickupLongitude': 77.7172,
        'buyerId': 'buyer_superbazar_007',
        'buyerName': 'Erode Super Bazar, Perundurai Road',
        'buyerPhone': '+91 94433 66120',
        'deliveryAddress': '55, Perundurai Road, Erode, TN - 638011',
        'dropLatitude': 11.3320,
        'dropLongitude': 77.7280,
        'orderStatus': 'Going to Farmer',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 5400.0,
        'deliveryFee': 420.0,
        'distanceKm': 18.5,
        'deliveryPartnerId': effectivePartner,
        'deliveryPartnerName': 'Manikandan S.',
        'deliveryPartnerPhone': '+91 98422 77123',
        'deliveryPartnerVehicle': 'Tata Ace Reefer 2.2T',
        'notes': 'Heavy paddy sacks; heavy transport vehicle required.',
        'items': [
          {
            'productId': 'seed_prod_rice',
            'name': 'Sona Masoori Paddy (Grade A)',
            'category': 'Grain',
            'price': 36.0,
            'quantity': 150.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/corn.png',
            'itemTotal': 5400.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1, minutes: 45))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 22))),
      },

      // 3. Completed Deliveries
      {
        'orderId': 'ORD-DEL-3108',
        'farmerId': 'farmer_velusamy_02',
        'farmerName': 'R. Velusamy',
        'farmerPhone': '+91 97890 22340',
        'farmerLocation': 'Pollachi Agro Plantation, Coimbatore',
        'pickupAddress': 'Pollachi Agro Plantation, Coimbatore, TN - 642001',
        'pickupLatitude': 10.9850,
        'pickupLongitude': 76.9520,
        'buyerId': 'buyer_kovai_greens',
        'buyerName': 'Kovai Fresh Greens Hub',
        'buyerPhone': '+91 98422 33110',
        'deliveryAddress': '33, Avinashi Road, Peelamedu, Coimbatore, TN - 641004',
        'dropLatitude': 11.0280,
        'dropLongitude': 77.0010,
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 4800.0,
        'deliveryFee': 380.0,
        'distanceKm': 9.8,
        'deliveryPartnerId': effectivePartner,
        'deliveryPartnerName': 'Manikandan S.',
        'deliveryPartnerPhone': '+91 98422 77123',
        'deliveryPartnerVehicle': 'Tata Ace Reefer 2.2T',
        'notes': 'Successfully handed over with digital delivery sign-off.',
        'items': [
          {
            'productId': 'seed_prod_banana',
            'name': 'Fresh Farm Bananas (Nendran)',
            'category': 'Fruit',
            'price': 40.0,
            'quantity': 120.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/banana.png',
            'itemTotal': 4800.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2, minutes: 40))),
      },
      {
        'orderId': 'ORD-DEL-2845',
        'farmerId': 'farmer_selvam_03',
        'farmerName': 'P. Selvaraj',
        'farmerPhone': '+91 94432 99810',
        'farmerLocation': 'Kinathukadavu Green Fields, Coimbatore',
        'pickupAddress': 'Kinathukadavu Green Fields, Coimbatore, TN - 642109',
        'pickupLatitude': 10.9750,
        'pickupLongitude': 76.9400,
        'buyerId': 'buyer_nilgiri_006',
        'buyerName': 'Nilgiri Daily Superstore',
        'buyerPhone': '+91 98433 77190',
        'deliveryAddress': '88, Thadagam Road, Saibaba Colony, Coimbatore, TN - 641011',
        'dropLatitude': 11.0250,
        'dropLongitude': 76.9450,
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'paymentMethod': 'UPI',
        'totalAmount': 2560.0,
        'deliveryFee': 210.0,
        'distanceKm': 6.2,
        'deliveryPartnerId': effectivePartner,
        'deliveryPartnerName': 'Manikandan S.',
        'deliveryPartnerPhone': '+91 98422 77123',
        'deliveryPartnerVehicle': 'Tata Ace Reefer 2.2T',
        'notes': 'Fresh sweet corn handed over in crisp condition.',
        'items': [
          {
            'productId': 'seed_prod_corn',
            'name': 'Sweet Golden Corn',
            'category': 'Grain',
            'price': 32.0,
            'quantity': 80.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/corn.png',
            'itemTotal': 2560.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 7))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5, minutes: 30))),
      },
      {
        'orderId': 'ORD-DEL-1972',
        'farmerId': 'farmer_muthusamy_01',
        'farmerName': 'K. Muthusamy',
        'farmerPhone': '+91 98422 11980',
        'farmerLocation': 'Thondamuthur Organic Farm, Coimbatore',
        'pickupAddress': 'Thondamuthur Organic Farm, Coimbatore, TN - 641109',
        'pickupLatitude': 10.9984,
        'pickupLongitude': 76.9612,
        'buyerId': 'buyer_annapoorna',
        'buyerName': 'Annapoorna Kitchens, Gandhipuram',
        'buyerPhone': '+91 98421 99011',
        'deliveryAddress': '12, Cross Cut Extension, Gandhipuram, Coimbatore, TN - 641012',
        'dropLatitude': 11.0190,
        'dropLongitude': 76.9680,
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'paymentMethod': 'Cash on Delivery',
        'totalAmount': 2700.0,
        'deliveryFee': 240.0,
        'distanceKm': 7.5,
        'deliveryPartnerId': effectivePartner,
        'deliveryPartnerName': 'Manikandan S.',
        'deliveryPartnerPhone': '+91 98422 77123',
        'deliveryPartnerVehicle': 'Tata Ace Reefer 2.2T',
        'notes': 'Delivered on time directly to restaurant kitchen receiving dock.',
        'items': [
          {
            'productId': 'seed_prod_tomato',
            'name': 'Organic Tomato (Fresh Harvest)',
            'category': 'Vegetable',
            'price': 30.0,
            'quantity': 90.0,
            'unit': 'kg',
            'imageUrl': 'assets/products/tomato.png',
            'itemTotal': 2700.0,
          }
        ],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 22))),
      },
    ];

    for (final ord in starterDeliveryOrders) {
      final docRef = _firestore.collection('orders').doc(ord['orderId'] as String);
      batch.set(docRef, ord);
    }
    await batch.commit();

    if (partnerId != null && partnerId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(partnerId).update({
          'todayDeliveries': 4,
          'inProgressDeliveries': 2,
          'totalDeliveries': 48,
          'rating': 4.9,
          'verificationStatus': 'verified',
        });
      } catch (_) {}
    }

    debugPrint('✅ [DataSeedService] Comprehensive delivery orders seeded successfully.');
  }
}
