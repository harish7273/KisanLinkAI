import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_partner_model.dart';
import '../models/order_model.dart';
import 'tracking_service.dart';

class DeliveryService {
  DeliveryService._();
  static final DeliveryService instance = DeliveryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // DUTY TOGGLE (ONLINE / OFFLINE)
  // ============================================================

  Future<void> setOnlineStatus({
    required String partnerId,
    required bool isOnline,
  }) async {
    try {
      await _firestore.collection('users').doc(partnerId).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (isOnline) {
        await TrackingService.instance.startTracking(
          deliveryPartnerId: partnerId,
        );
      } else {
        await TrackingService.instance.stopTracking(
          deliveryPartnerId: partnerId,
        );
      }
    } catch (e) {
      debugPrint('TOGGLE DUTY ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // STREAMS FOR PARTNER
  // ============================================================

  /// Stream of available orders ready for delivery (not claimed yet)
  Stream<List<OrderModel>> streamAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('orderStatus', whereIn: ['Ready', 'Ready for Pickup'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map<OrderModel>((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .where((order) => order.deliveryPartnerId == null || order.deliveryPartnerId!.isEmpty)
          .toList();
    });
  }

  /// Stream of in-progress orders for a given partner
  Stream<List<OrderModel>> streamPartnerActiveOrders(String partnerId) {
    return _firestore
        .collection('orders')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .where('orderStatus', whereIn: [
          'Partner Accepted',
          'Going to Farmer',
          'Arrived at Farm',
          'Picked Up',
          'Out for Delivery',
          'Arrived at Buyer',
        ])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map<OrderModel>((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of completed orders for a given partner
  Stream<List<OrderModel>> streamPartnerCompletedOrders(String partnerId) {
    return _firestore
        .collection('orders')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .where('orderStatus', isEqualTo: 'Delivered')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map<OrderModel>((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream single order
  Stream<OrderModel?> streamOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ============================================================
  // ATOMIC CLAIM: ACCEPT DELIVERY
  // ============================================================

  Future<bool> acceptDelivery({
    required String orderId,
    required DeliveryPartnerModel partner,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final userRef = _firestore.collection('users').doc(partner.uid);

    try {
      final success = await _firestore.runTransaction<bool>((transaction) async {
        final orderDoc = await transaction.get(orderRef);
        if (!orderDoc.exists) {
          throw Exception('Order does not exist');
        }

        final data = orderDoc.data()!;
        final existingPartner = data['deliveryPartnerId']?.toString();

        // Ensure not already claimed
        if (existingPartner != null && existingPartner.isNotEmpty && existingPartner != partner.uid) {
          return false;
        }

        transaction.update(orderRef, {
          'orderStatus': 'Partner Accepted',
          'deliveryStatus': 'Partner Accepted',
          'deliveryPartnerId': partner.uid,
          'deliveryPartnerName': partner.name,
          'deliveryPartnerPhone': partner.phone,
          'deliveryPartnerVehicle': partner.vehicleNumber,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'activeOrderId': orderId,
          'inProgressDeliveries': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (success) {
        // Send push notifications
        await _sendNotification(
          recipientId: partner.uid,
          title: 'Delivery Claimed',
          message: 'You have accepted delivery for order #$orderId',
          type: 'delivery_assigned',
          orderId: orderId,
        );

        // Update tracking to link active order
        await TrackingService.instance.startTracking(
          deliveryPartnerId: partner.uid,
          activeOrderId: orderId,
        );
      }

      return success;
    } catch (e) {
      debugPrint('ACCEPT DELIVERY ERROR: $e');
      return false;
    }
  }

  // ============================================================
  // STEP 3: START PICKUP (GOING TO FARMER)
  // ============================================================

  Future<void> startPickup(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'orderStatus': 'Going to Farmer',
      'deliveryStatus': 'Going to Farmer',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // STEP 4: ARRIVED AT FARM
  // ============================================================

  Future<void> markArrivedAtFarm(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'orderStatus': 'Arrived at Farm',
      'deliveryStatus': 'Arrived at Farm',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // STEP 5: CONFIRM PICKUP
  // ============================================================

  Future<void> confirmPickup(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'orderStatus': 'Picked Up',
      'deliveryStatus': 'Picked Up',
      'pickedUpAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // STEP 6: START DELIVERY (OUT FOR DELIVERY)
  // ============================================================

  Future<void> startDelivery(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'orderStatus': 'Out for Delivery',
      'deliveryStatus': 'Out for Delivery',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // STEP 7 & 8: CONFIRM DELIVERY (DELIVERED)
  // ============================================================

  Future<void> completeDelivery({
    required String orderId,
    required String partnerId,
  }) async {
    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(orderId);
    final userRef = _firestore.collection('users').doc(partnerId);

    batch.update(orderRef, {
      'orderStatus': 'Delivered',
      'deliveryStatus': 'Delivered',
      'paymentStatus': 'Paid',
      'deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'activeOrderId': null,
      'totalDeliveries': FieldValue.increment(1),
      'todayDeliveries': FieldValue.increment(1),
      'inProgressDeliveries': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Notify completion
    await _sendNotification(
      recipientId: partnerId,
      title: 'Order Delivered!',
      message: 'Order #$orderId has been delivered successfully.',
      type: 'order_delivered',
      orderId: orderId,
    );
  }

  Future<void> _sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    required String orderId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'message': message,
        'type': type,
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
