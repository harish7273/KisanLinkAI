import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FarmerNotificationsScreen extends StatefulWidget {
  const FarmerNotificationsScreen({super.key});

  @override
  State<FarmerNotificationsScreen> createState() =>
      _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState
    extends State<FarmerNotificationsScreen> {
  String selectedFilter = 'All';

  final Color green = const Color(0xFF22C55E);
  final Color darkGreen = const Color(0xFF0B3D2E);
  final Color background = const Color(0xFFF7FAF8);

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get farmerId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ============================================================
  // NOTIFICATIONS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      get notificationStream {
    final uid = farmerId;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots();
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint(
        'MARK NOTIFICATION READ ERROR: $e',
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    try {
      final batch =
          FirebaseFirestore.instance.batch();

      for (final doc in docs) {
        final data = doc.data();

        if (data['isRead'] != true) {
          batch.update(
            doc.reference,
            {
              'isRead': true,
            },
          );
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All notifications marked as read',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'MARK ALL READ ERROR: $e',
      );
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  bool matchesFilter(
    Map<String, dynamic> data,
  ) {
    if (selectedFilter == 'All') {
      return true;
    }

    final type =
        (data['type'] ?? '').toString();

    switch (selectedFilter) {
      case 'Orders':
        return type == 'new_order' ||
            type == 'order_confirmed' ||
            type == 'order_cancelled' ||
            type == 'order_delivered';

      case 'Messages':
        return type == 'message' ||
            type == 'new_message';

      case 'Payments':
        return type == 'payment' ||
            type == 'payment_received' ||
            type == 'payment_success';

      case 'Updates':
        return type == 'update' ||
            type == 'system';

      default:
        return true;
    }
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData notificationIcon(
    String type,
  ) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart_rounded;

      case 'message':
      case 'new_message':
        return Icons.chat_bubble_rounded;

      case 'order_confirmed':
        return Icons.local_shipping_rounded;

      case 'payment':
      case 'payment_received':
      case 'payment_success':
        return Icons.account_balance_wallet_rounded;

      case 'update':
      case 'system':
        return Icons.campaign_rounded;

      case 'order_cancelled':
        return Icons.cancel_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  // ============================================================
  // ICON COLOR
  // ============================================================

  Color notificationColor(
    String type,
  ) {
    switch (type) {
      case 'new_order':
        return const Color(0xFF16A34A);

      case 'message':
      case 'new_message':
        return const Color(0xFFF59E0B);

      case 'order_confirmed':
        return const Color(0xFF6366F1);

      case 'payment':
      case 'payment_received':
      case 'payment_success':
        return const Color(0xFF2196F3);

      case 'update':
      case 'system':
        return const Color(0xFFEC4899);

      case 'order_cancelled':
        return const Color(0xFFEF4444);

      default:
        return green;
    }
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  String timeAgo(dynamic timestamp) {
    if (timestamp == null) {
      return '';
    }

    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final difference =
        DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: notificationStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final docs =
                  snapshot.data!.docs;

              final unread =
                  docs.where(
                (doc) =>
                    doc.data()['isRead'] != true,
              ).toList();

              if (unread.isEmpty) {
                return const SizedBox();
              }

              return TextButton(
                onPressed: () {
                  markAllAsRead(docs);
                },
                child: const Text(
                  'Mark all as read',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ====================================================
          // FILTERS
          // ====================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              14,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton('All'),
                  _filterButton('Orders'),
                  _filterButton('Messages'),
                  _filterButton('Payments'),
                  _filterButton('Updates'),
                ],
              ),
            ),
          ),

          // ====================================================
          // NOTIFICATIONS
          // ====================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: notificationStream,

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: green,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load notifications',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return _emptyState();
                }

                final allDocs =
                    snapshot.data!.docs.toList();

                // Sort newest first.
                allDocs.sort((a, b) {
                  final aTime =
                      a.data()['createdAt'];

                  final bTime =
                      b.data()['createdAt'];

                  if (aTime is Timestamp &&
                      bTime is Timestamp) {
                    return bTime
                        .compareTo(aTime);
                  }

                  return 0;
                });

                final docs =
                    allDocs.where((doc) {
                  return matchesFilter(
                    doc.data(),
                  );
                }).toList();

                if (docs.isEmpty) {
                  return _emptyState();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    30,
                  ),
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...docs.map(
                      (doc) => _notificationCard(
                        doc,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _filterButton(
    String label,
  ) {
    final selected =
        selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },

      child: Container(
        margin: const EdgeInsets.only(
          right: 10,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? green
              : Colors.white,

          borderRadius:
              BorderRadius.circular(24),

          border: Border.all(
            color: selected
                ? green
                : const Color(0xFFD8E5DC),
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected
                ? Colors.white
                : darkGreen,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final type =
        (data['type'] ?? '').toString();

    final title =
        (data['title'] ?? 'Notification')
            .toString();

    final message =
        (data['message'] ?? '')
            .toString();

    final isRead =
        data['isRead'] == true;

    final color =
        notificationColor(type);

    final icon =
        notificationIcon(type);

    return GestureDetector(
      onTap: () async {
        await markAsRead(doc.id);

        // For now, new orders can open
        // the farmer orders screen later.
        if (type == 'new_order') {
          // We will connect this to
          // FarmerOrdersScreen next.
        }
      },

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : color.withOpacity(0.06),

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: isRead
                ? const Color(0xFFE4EAE6)
                : color.withOpacity(0.18),
          ),
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 52,
              height: 52,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),

                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          title,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                            color:
                                const Color(0xFF171717),
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,

                          margin:
                              const EdgeInsets.only(
                            top: 6,
                          ),

                          decoration:
                              BoxDecoration(
                            color: green,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,

                    style: const TextStyle(
                      color: Color(0xFF454545),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    timeAgo(
                      data['createdAt'],
                    ),

                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color:
                    green.withOpacity(0.10),
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.notifications_none_rounded,
                color: green,
                size: 46,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'New orders and updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}