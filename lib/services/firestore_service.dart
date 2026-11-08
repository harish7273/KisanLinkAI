import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // USER OPERATIONS
  // ============================================================

  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserKyc({
    required String uid,
    required String kycStatus,
    Map<String, dynamic>? kycDocs,
    String? rejectionReason,
    bool? isVerified,
  }) async {
    final Map<String, dynamic> data = {
      'kycStatus': kycStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (kycDocs != null) data['kycDocs'] = kycDocs;
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    if (isVerified != null) data['isVerified'] = isVerified;

    await _firestore.collection('users').doc(uid).update(data);

    // Write to audit log
    await recordAuditLog(
      action: 'UPDATE_KYC',
      performedBy: uid,
      targetEntity: 'users/$uid',
      details: 'Status changed to $kycStatus. Verified: $isVerified',
    );
  }

  // ============================================================
  // WALLET & PAYOUT OPERATIONS
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamWallet(String uid) {
    return _firestore.collection('wallets').doc(uid).snapshots();
  }

  Future<void> createPayoutRequest({
    required String userId,
    required String userName,
    required String userRole,
    required double amount,
    required String payoutMethod, // 'UPI' or 'BANK'
    String? upiId,
    String? bankAccount,
    String? bankIfsc,
  }) async {
    final batch = _firestore.batch();
    final payoutRef = _firestore.collection('payout_requests').doc();
    final walletRef = _firestore.collection('wallets').doc(userId);

    final payoutData = {
      'payoutId': payoutRef.id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'amount': amount,
      'payoutMethod': payoutMethod,
      'upiId': upiId,
      'bankAccount': bankAccount,
      'bankIfsc': bankIfsc,
      'status': 'PENDING', // 'PENDING', 'APPROVED', 'PROCESSED', 'REJECTED'
      'requestedAt': FieldValue.serverTimestamp(),
    };

    batch.set(payoutRef, payoutData);

    // Atomically decrement wallet balance or record pending withdrawal
    batch.set(
      walletRef,
      {
        'pendingWithdrawal': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    await recordAuditLog(
      action: 'PAYOUT_REQUEST_CREATED',
      performedBy: userId,
      targetEntity: 'payout_requests/${payoutRef.id}',
      details: 'Requested ₹$amount via $payoutMethod ($upiId / $bankAccount)',
    );
  }

  // ============================================================
  // CROP DISEASE SCANS
  // ============================================================

  Future<String> saveDiseaseScan({
    required String userId,
    required String crop,
    required String diseaseName,
    required String diseaseNameLocal,
    required String pathogenType,
    required String severity,
    required double affectedAreaPercentage,
    required List<String> symptoms,
    required String organicTreatment,
    required String chemicalTreatment,
    required String preventiveMeasures,
    String? imagePath,
  }) async {
    final docRef = _firestore.collection('disease_scans').doc();
    await docRef.set({
      'scanId': docRef.id,
      'userId': userId,
      'crop': crop,
      'diseaseName': diseaseName,
      'diseaseNameLocal': diseaseNameLocal,
      'pathogenType': pathogenType,
      'severity': severity,
      'affectedAreaPercentage': affectedAreaPercentage,
      'symptoms': symptoms,
      'organicTreatment': organicTreatment,
      'chemicalTreatment': chemicalTreatment,
      'preventiveMeasures': preventiveMeasures,
      'imagePath': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserDiseaseScans(String userId) {
    return _firestore
        .collection('disease_scans')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ============================================================
  // AUDIT LOGS (Immutable History)
  // ============================================================

  Future<void> recordAuditLog({
    required String action,
    required String performedBy,
    required String targetEntity,
    required String details,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': action,
        'performedBy': performedBy,
        'targetEntity': targetEntity,
        'details': details,
        'beforeData': beforeData,
        'afterData': afterData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit log write failure should not crash user-facing flow
    }
  }

  // ============================================================
  // PROOF OF DELIVERY (POD)
  // ============================================================

  Future<void> recordProofOfDelivery({
    required String orderId,
    required String deliveryPartnerId,
    required String deliveryPartnerName,
    required String deliveryOtp,
    String? photoUrl,
    String? signatureBase64,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    await orderRef.update({
      'orderStatus': 'delivered',
      'deliveryStatus': 'delivered',
      'podRecord': {
        'verifiedOtp': deliveryOtp,
        'deliveredAt': FieldValue.serverTimestamp(),
        'partnerId': deliveryPartnerId,
        'partnerName': deliveryPartnerName,
        'photoUrl': photoUrl,
        'signature': signatureBase64,
      },
    });

    await recordAuditLog(
      action: 'ORDER_DELIVERED_POD',
      performedBy: deliveryPartnerId,
      targetEntity: 'orders/$orderId',
      details: 'Order $orderId marked delivered with verified OTP and signature.',
    );
  }
}
