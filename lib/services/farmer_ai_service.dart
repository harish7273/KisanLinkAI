import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FarmerAiService {
  // ============================================================
  // GEMINI MODEL
  // ============================================================

  static final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',

    systemInstruction: Content.system(
      '''
You are KisanAI Assistant, an AI farming assistant
inside the KisanAI farmer application.

Your users are farmers in India, especially Tamil Nadu.

You help farmers with:

- Farming
- Crop cultivation
- Crop problems
- Weather-related farming decisions
- Market guidance
- Selling crops
- Orders
- Wallet and earnings
- General KisanAI app guidance

IMPORTANT RULES:

1. Be friendly and simple.

2. Understand:
   - English
   - Tamil
   - Tanglish
   - Mixed Tamil-English

3. If the farmer asks in Tamil, answer in Tamil.

4. If the farmer asks in Tanglish, answer in Tanglish.

5. Keep answers short and practical.

6. When farmer-specific KisanAI data is provided,
   always use that data instead of guessing.

7. Never invent:
   - Orders
   - Earnings
   - Wallet balance
   - Market prices
   - Weather
   - Products

8. If farmer-specific information is unavailable,
   clearly say that the information is not available.

9. For crop disease questions, do not claim a definite
   diagnosis from text alone.

10. For current market prices, only use prices provided
    by the KisanAI application.

11. If current market prices are unavailable,
    tell the farmer to check the KisanAI Market section.

12. For farming advice, provide practical steps.

13. Never expose Firestore, Firebase, database fields,
    internal code or technical implementation details.

14. Do not mention that you are receiving a "context"
    or "database information".

15. You are KisanAI Assistant, not a generic chatbot.

'''
    ),
  );

  // ============================================================
  // ASK GEMINI
  // ============================================================

  static Future<String> ask(
    String question, {
    String? farmerName,
    String? weatherLocation,
    double? temperature,
    String? weatherCondition,
  }) async {
    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'KISANAI AI REQUEST',
      );

      debugPrint(
        'Question: $question',
      );

      // --------------------------------------------------------
      // BUILD FARMER CONTEXT
      // --------------------------------------------------------

      final farmerContext =
          await _buildFarmerContext(
        farmerName: farmerName,
        weatherLocation: weatherLocation,
        temperature: temperature,
        weatherCondition: weatherCondition,
      );

      debugPrint(
        'Farmer context loaded successfully.',
      );

      // --------------------------------------------------------
      // BUILD PROMPT
      // --------------------------------------------------------

      final prompt = '''
Here is information available from the farmer's KisanAI account.

$farmerContext

==================================================

FARMER QUESTION:

$question

==================================================

Answer the farmer naturally.

Use the farmer's KisanAI information when the question
is related to their personal information.

If the question is a general farming question,
answer using your farming knowledge.

Do not invent information.

Do not mention internal technical details.

Keep the answer simple and useful for a farmer.
''';

      // --------------------------------------------------------
      // GEMINI REQUEST
      // --------------------------------------------------------

      final response =
          await _model.generateContent(
        [
          Content.text(prompt),
        ],
      );

      final text =
          response.text;

      debugPrint(
        'Gemini response received.',
      );

      debugPrint(
        '========================================',
      );

      if (text == null ||
          text.trim().isEmpty) {
        return 'Sorry, I could not generate an answer. '
            'Please try again.';
      }

      return text.trim();
    } catch (e, stackTrace) {
      // --------------------------------------------------------
      // PRINT REAL ERROR
      // --------------------------------------------------------

      debugPrint(
        '========================================',
      );

      debugPrint(
        'KISANAI AI ERROR',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        'STACK TRACE',
      );

      debugPrint(
        stackTrace.toString(),
      );

      debugPrint(
        '========================================',
      );

      // --------------------------------------------------------
      // TEMPORARY DEBUG RESPONSE
      // --------------------------------------------------------
      //
      // We intentionally show the real error for now.
      // Once Gemini works, we can replace this with a
      // friendly production message.
      //

      return _handleError(e);
    }
  }

  // ============================================================
  // BUILD FARMER CONTEXT
  // ============================================================

  static Future<String> _buildFarmerContext({
    String? farmerName,
    String? weatherLocation,
    double? temperature,
    String? weatherCondition,
  }) async {
    // ==========================================================
    // CURRENT USER
    // ==========================================================

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'No authenticated Firebase user found.',
      );

      return '''
FARMER PROFILE

Name:
${farmerName ?? 'Farmer'}

The farmer is currently not authenticated.
Do not provide account-specific information.
''';
    }

    final uid =
        user.uid;

    debugPrint(
      'Authenticated farmer UID available.',
    );

    // ==========================================================
    // DEFAULT VALUES
    // ==========================================================

    String actualName =
        farmerName ?? 'Farmer';

    int totalOrders = 0;

    int newOrders = 0;

    int inProgressOrders = 0;

    int deliveredOrders = 0;

    double walletBalance = 0;

    double todayEarnings = 0;

    final List<String> recentOrders = [];

    // ==========================================================
    // USER PROFILE
    // ==========================================================

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      if (userDoc.exists) {
        final data =
            userDoc.data();

        if (data != null) {
          final name =
              data['name']
                  ?.toString()
                  .trim();

          if (name != null &&
              name.isNotEmpty) {
            actualName =
                name;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'PROFILE READ ERROR: $e',
      );
    }

    // ==========================================================
    // ORDERS
    // ==========================================================

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .get();

      debugPrint(
        'Total Firestore orders found: '
        '${snapshot.docs.length}',
      );

      final farmerOrders =
          <Map<String, dynamic>>[];

      // --------------------------------------------------------
      // LOOP THROUGH ORDERS
      // --------------------------------------------------------

      for (final doc
          in snapshot.docs) {
        final data =
            doc.data();

        final rawItems =
            data['items'];

        if (rawItems is! List) {
          continue;
        }

        bool belongsToFarmer =
            false;

        final farmerItems =
            <Map<String, dynamic>>[];

        // ------------------------------------------------------
        // FIND FARMER'S ITEMS
        // ------------------------------------------------------

        for (final rawItem
            in rawItems) {
          if (rawItem is! Map) {
            continue;
          }

          final item =
              Map<String, dynamic>.from(
            rawItem,
          );

          final itemFarmerId =
              item['farmerId']
                  ?.toString();

          if (itemFarmerId ==
              uid) {
            belongsToFarmer =
                true;

            farmerItems.add(
              item,
            );
          }
        }

        if (!belongsToFarmer) {
          continue;
        }

        // ------------------------------------------------------
        // ORDER STATUS
        // ------------------------------------------------------

        final status =
            (data['orderStatus'] ??
                    data['status'] ??
                    '')
                .toString()
                .trim()
                .toLowerCase();

        totalOrders++;

        // ------------------------------------------------------
        // NEW ORDERS
        // ------------------------------------------------------

        if (status == 'placed' ||
            status == 'pending' ||
            status == 'new') {
          newOrders++;
        }

        // ------------------------------------------------------
        // IN PROGRESS
        // ------------------------------------------------------

        if (status == 'accepted' ||
            status == 'preparing' ||
            status == 'ready' ||
            status == 'out for delivery' ||
            status == 'out_for_delivery' ||
            status == 'in progress' ||
            status == 'in_progress') {
          inProgressOrders++;
        }

        // ------------------------------------------------------
        // DELIVERED
        // ------------------------------------------------------

        if (status == 'delivered' ||
            status == 'completed') {
          deliveredOrders++;
        }

        // ------------------------------------------------------
        // CALCULATE FARMER ORDER TOTAL
        // ------------------------------------------------------

        double orderFarmerTotal =
            0;

        for (final item
            in farmerItems) {
          final itemTotal =
              _toDouble(
            item['itemTotal'],
          );

          final price =
              _toDouble(
            item['price'],
          );

          final quantity =
              _toDouble(
            item['quantity'],
          );

          double calculatedTotal;

          if (itemTotal > 0) {
            calculatedTotal =
                itemTotal;
          } else {
            calculatedTotal =
                price * quantity;
          }

          orderFarmerTotal +=
              calculatedTotal;
        }

        // ------------------------------------------------------
        // WALLET
        // ------------------------------------------------------

        final walletEligible =
            status == 'accepted' ||
                status == 'preparing' ||
                status == 'ready' ||
                status == 'out for delivery' ||
                status == 'out_for_delivery' ||
                status == 'in progress' ||
                status == 'in_progress' ||
                status == 'delivered' ||
                status == 'completed';

        if (walletEligible) {
          walletBalance +=
              orderFarmerTotal;
        }

        // ------------------------------------------------------
        // TODAY'S EARNINGS
        // ------------------------------------------------------

        final createdAt =
            _parseDate(
          data['createdAt'],
        );

        if (createdAt != null &&
            walletEligible) {
          final now =
              DateTime.now();

          final isToday =
              createdAt.year ==
                      now.year &&
                  createdAt.month ==
                      now.month &&
                  createdAt.day ==
                      now.day;

          if (isToday) {
            todayEarnings +=
                orderFarmerTotal;
          }
        }

        // ------------------------------------------------------
        // PRODUCT NAMES
        // ------------------------------------------------------

        String productNames =
            '';

        for (final item
            in farmerItems) {
          final productName =
              (item['name'] ??
                      item['productName'] ??
                      item['cropName'])
                  ?.toString()
                  .trim();

          if (productName != null &&
              productName.isNotEmpty) {
            if (productNames.isNotEmpty) {
              productNames +=
                  ', ';
            }

            productNames +=
                productName;
          }
        }

        if (productNames.isEmpty) {
          productNames =
              'Crop';
        }

        // ------------------------------------------------------
        // BUYER
        // ------------------------------------------------------

        final buyerName =
            (data['buyerName'] ??
                    data['buyer'] ??
                    'Buyer')
                .toString()
                .trim();

        // ------------------------------------------------------
        // SAVE RECENT ORDER
        // ------------------------------------------------------

        farmerOrders.add({
          'createdAt':
              createdAt ??
                  DateTime(2000),

          'status':
              status.isEmpty
                  ? 'unknown'
                  : status,

          'buyer':
              buyerName.isEmpty
                  ? 'Buyer'
                  : buyerName,

          'products':
              productNames,

          'amount':
              orderFarmerTotal,
        });
      }

      // ========================================================
      // SORT ORDERS
      // ========================================================

      farmerOrders.sort(
        (a, b) {
          final aDate =
              a['createdAt']
                  as DateTime;

          final bDate =
              b['createdAt']
                  as DateTime;

          return bDate.compareTo(
            aDate,
          );
        },
      );

      // ========================================================
      // TAKE FIVE RECENT ORDERS
      // ========================================================

      for (final order
          in farmerOrders.take(5)) {
        final amount =
            order['amount']
                as double;

        recentOrders.add(
          '''
Buyer: ${order['buyer']}
Products: ${order['products']}
Status: ${order['status']}
Amount: ₹${amount.toStringAsFixed(0)}
''',
        );
      }

      debugPrint(
        'Farmer orders: $totalOrders',
      );

      debugPrint(
        'New orders: $newOrders',
      );

      debugPrint(
        'In progress: $inProgressOrders',
      );

      debugPrint(
        'Wallet: ₹$walletBalance',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'ORDER READ ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }

    // ==========================================================
    // WEATHER
    // ==========================================================

    String weatherText;

    if (temperature != null ||
        weatherCondition != null ||
        weatherLocation != null) {
      weatherText = '''
Location:
${weatherLocation ?? 'Not available'}

Temperature:
${temperature != null ? '${temperature!.toStringAsFixed(0)}°C' : 'Not available'}

Condition:
${weatherCondition ?? 'Not available'}
''';
    } else {
      weatherText =
          'Current weather information is not available.';
    }

    // ==========================================================
    // FINAL FARMER CONTEXT
    // ==========================================================

    return '''
==================================================
FARMER PROFILE
==================================================

Name:
$actualName

==================================================
ORDER SUMMARY
==================================================

Total orders:
$totalOrders

New orders:
$newOrders

Orders in progress:
$inProgressOrders

Delivered orders:
$deliveredOrders

==================================================
WALLET
==================================================

Current wallet balance:
₹${walletBalance.toStringAsFixed(0)}

Today's earnings:
₹${todayEarnings.toStringAsFixed(0)}

==================================================
RECENT ORDERS
==================================================

${recentOrders.isEmpty ? 'No recent orders found.' : recentOrders.join('\n--------------------\n')}

==================================================
WEATHER
==================================================

$weatherText

==================================================
END OF KISANAI FARMER INFORMATION
==================================================
''';
  }

  // ============================================================
  // DOUBLE CONVERTER
  // ============================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  static String _handleError(
    Object error,
  ) {
    final message =
        error.toString();

    final lower =
        message.toLowerCase();

    // ----------------------------------------------------------
    // PRINT FULL ERROR
    // ----------------------------------------------------------

    debugPrint(
      'FULL FIREBASE AI ERROR:',
    );

    debugPrint(
      message,
    );

    // ----------------------------------------------------------
    // QUOTA
    // ----------------------------------------------------------

    if (lower.contains('quota') ||
        lower.contains('429') ||
        lower.contains('resource_exhausted')) {
      return '''
⚠️ KisanAI quota is currently unavailable.

Please try again in a little while.
''';
    }

    // ----------------------------------------------------------
    // PERMISSION
    // ----------------------------------------------------------

    if (lower.contains('permission') ||
        lower.contains('403') ||
        lower.contains('permission_denied')) {
      return '''
⚠️ KisanAI permission is not configured correctly.

Please check the Firebase AI setup.
''';
    }

    // ----------------------------------------------------------
    // NETWORK
    // ----------------------------------------------------------

    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return '''
📡 Internet connection seems unavailable.

Please check your connection and try again.
''';
    }

    // ----------------------------------------------------------
    // MODEL NOT FOUND
    // ----------------------------------------------------------

    if (lower.contains('404') ||
        lower.contains('not found') ||
        lower.contains('not_found')) {
      return '''
⚠️ The KisanAI model could not be found.

Please check the Firebase AI configuration.
''';
    }

    // ----------------------------------------------------------
    // API NOT ENABLED
    // ----------------------------------------------------------

    if (lower.contains('api') &&
        (lower.contains('disabled') ||
            lower.contains('enable'))) {
      return '''
⚠️ Firebase AI is not enabled for this project.

Please enable the required Firebase AI services.
''';
    }

    // ----------------------------------------------------------
    // TEMPORARY DEBUG OUTPUT
    // ----------------------------------------------------------

    return '''
⚠️ I could not connect to KisanAI.

DEBUG ERROR:
$message
''';
  }
}