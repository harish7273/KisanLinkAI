import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    try {
      // ----------------------------------------------------------
      // REQUEST NOTIFICATION PERMISSION
      // ----------------------------------------------------------

      final settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint(
        'FCM PERMISSION: '
        '${settings.authorizationStatus}',
      );

      // ----------------------------------------------------------
      // GET FCM TOKEN
      // ----------------------------------------------------------

      final token =
          await _messaging.getToken();

      debugPrint(
        '========================================',
      );

      debugPrint(
        'FCM TOKEN:',
      );

      debugPrint(token);

      debugPrint(
        '========================================',
      );

      if (token != null) {
        await saveToken(token);
      }

      // ----------------------------------------------------------
      // TOKEN REFRESH
      // ----------------------------------------------------------

      _messaging.onTokenRefresh.listen(
        (newToken) async {
          debugPrint(
            'FCM TOKEN REFRESHED',
          );

          debugPrint(newToken);

          await saveToken(newToken);
        },
      );

      // ----------------------------------------------------------
      // FOREGROUND MESSAGE
      // ----------------------------------------------------------

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint(
            '========================================',
          );

          debugPrint(
            'FCM MESSAGE RECEIVED',
          );

          debugPrint(
            'Title: ${message.notification?.title}',
          );

          debugPrint(
            'Body: ${message.notification?.body}',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          debugPrint(
            '========================================',
          );
        },
      );

      // ----------------------------------------------------------
      // NOTIFICATION OPENED FROM BACKGROUND
      // ----------------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          debugPrint(
            'FCM NOTIFICATION OPENED',
          );

          debugPrint(
            'Order ID: ${message.data['orderId']}',
          );

          debugPrint(
            'Type: ${message.data['type']}',
          );
        },
      );

      // ----------------------------------------------------------
      // APP OPENED FROM TERMINATED STATE
      // ----------------------------------------------------------

      final initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'APP OPENED FROM FCM NOTIFICATION',
        );

        debugPrint(
          'Order ID: '
          '${initialMessage.data['orderId']}',
        );
      }
    } catch (e) {
      debugPrint(
        'FCM INITIALIZATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE TOKEN
  // ============================================================

  static Future<void> saveToken(
    String token,
  ) async {
    try {
      final user =
          _auth.currentUser;

      if (user == null) {
        debugPrint(
          'FCM: User not logged in',
        );

        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'FCM TOKEN SAVED FOR USER: ${user.uid}',
      );
    } catch (e) {
      debugPrint(
        'FCM TOKEN SAVE ERROR: $e',
      );
    }
  }
}