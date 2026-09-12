import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/data_seed_service.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'farmer_payouts_screen.dart';
import 'farmer_notifications_screen.dart';
import 'farmer_orders_screen.dart';
import 'kisan_voice_screen.dart';
import 'quality_scanner_screen.dart';
import 'kisan_pool_screen.dart';
import 'offline_sync_screen.dart';
import 'weather_details_screen.dart';
import 'farmer_analytics_screen.dart';
import '../services/offline_sync_service.dart';
import '../widgets/language_switch_button.dart';
import '../services/language_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF080A09);
  static const Color card = Color(0xFF111411);

  static const Color green = Color(0xFF65D83F);
  static const Color textSecondary = Color(0xFFA8ADA8);

  static const Color orange = Color(0xFFFF8A00);
  static const Color purple = Color(0xFF8067E8);
  static const Color blue = Color(0xFF3B9DE8);

  // ============================================================
  // FARMER
  // ============================================================

  String farmerName = FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
      ? FirebaseAuth.instance.currentUser!.displayName!.trim()
      : 'Farmer';

  String get farmerId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // ============================================================
  // WEATHER
  // ============================================================

  WeatherModel? weather = WeatherModel.defaultCoimbatore();

  String location = 'Coimbatore';

  bool weatherLoading = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);

    debugPrint('========================================');
    debugPrint('FARMER HOME INITIALIZED');
    debugPrint('AUTH UID: $farmerId');
    debugPrint('INITIAL FARMER NAME: $farmerName');
    debugPrint('========================================');

    loadUser();
    loadWeather();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.uid.isEmpty) {
        debugPrint('USER LOAD: Firebase user is null');
        return;
      }

      final uid = user.uid;
      String resolvedName = user.displayName?.trim() ?? '';

      // 1. Try farmers collection first (where registration writes)
      try {
        final farmerSnapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .get();

        if (farmerSnapshot.exists && farmerSnapshot.data() != null) {
          final fData = farmerSnapshot.data()!;
          final fName = (fData['name'] ?? fData['farmerName'] ?? '').toString().trim();
          if (fName.isNotEmpty) {
            resolvedName = fName;
            debugPrint('USER LOAD: Found name in farmers collection -> $resolvedName');
          }
        }
      } catch (e) {
        debugPrint('FARMER COLLECTION LOAD ERROR: $e');
      }

      // 2. Try users collection second
      try {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userSnapshot.exists && userSnapshot.data() != null) {
          final uData = userSnapshot.data()!;
          final uName = (uData['name'] ?? uData['farmerName'] ?? '').toString().trim();
          if (uName.isNotEmpty && (resolvedName.isEmpty || resolvedName == 'Farmer')) {
            resolvedName = uName;
            debugPrint('USER LOAD: Found name in users collection -> $resolvedName');
          }
        }
      } catch (e) {
        debugPrint('USER COLLECTION LOAD ERROR: $e');
      }

      // 3. Fallback to phone / email if name is still empty
      if (resolvedName.isEmpty || resolvedName == 'Farmer') {
        final phone = user.phoneNumber?.trim() ?? '';
        final email = user.email?.trim() ?? '';
        if (phone.isNotEmpty) {
          resolvedName = phone;
        } else if (email.isNotEmpty && email.contains('@kisanai.app')) {
          resolvedName = email.split('@').first;
        } else if (email.isNotEmpty && email.contains('@')) {
          resolvedName = email.split('@').first;
        } else {
          resolvedName = 'Farmer';
        }
      }

      // 4. Ensure starter orders, products, and auctions exist & profile is synced
      try {
        final phone = user.phoneNumber?.trim() ?? '';
        await DataSeedService.ensureFarmerDataSeeded(
          farmerUid: uid,
          farmerName: resolvedName,
          phone: phone,
        );

        if (user.displayName != resolvedName) {
          await user.updateDisplayName(resolvedName);
        }
      } catch (e) {
        debugPrint('SEED / PROFILE SYNC ERROR: $e');
      }

      if (!mounted) return;

      setState(() {
        farmerName = resolvedName;
      });

      debugPrint('USER LOAD COMPLETED: final farmerName = $farmerName');
    } catch (e) {
      debugPrint('USER LOAD ERROR: $e');
    }
  }

  // ============================================================
  // LOAD WEATHER
  // ============================================================

  Future<void> loadWeather() async {
    try {
      if (mounted) {
        setState(() {
          weatherLoading = true;
        });
      }

      double lat = 11.0168;
      double lon = 76.9558;
      String detectedLocation = 'Coimbatore';

      try {
        final position = await LocationService.getCurrentLocation()
            .timeout(const Duration(seconds: 4));
        lat = position.latitude;
        lon = position.longitude;

        final places = await placemarkFromCoordinates(lat, lon)
            .timeout(const Duration(seconds: 3));

        if (places.isNotEmpty) {
          final locality = places.first.locality;
          if (locality != null && locality.trim().isNotEmpty) {
            detectedLocation = locality;
          }
        }
      } catch (e) {
        debugPrint('LOCATION ACQUISITION FALLBACK: $e');
      }

      final data = await WeatherService.getCurrentWeather(lat, lon);

      if (!mounted) return;

      setState(() {
        location = detectedLocation;
        weather = data;
        weatherLoading = false;
      });
    } catch (e) {
      debugPrint('WEATHER ERROR: $e');

      if (!mounted) return;

      setState(() {
        location = 'Coimbatore';
        weather = WeatherModel.defaultCoimbatore();
        weatherLoading = false;
      });
    }
  }

  // ============================================================
  // GREETING
  // ============================================================

  String get greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return tr('good_morning');
    }

    if (hour < 17) {
      return tr('good_afternoon');
    }

    return tr('good_evening');
  }

  // ============================================================
  // ORDERS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      get ordersStream {
    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots();
  }

  // ============================================================
  // NOTIFICATIONS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      get notificationStream {
    if (farmerId.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'recipientId',
          isEqualTo: farmerId,
        )
        .snapshots();
  }

  // ============================================================
  // CHECK WHETHER ORDER BELONGS TO CURRENT FARMER
  // ============================================================

  bool orderBelongsToFarmer(
    Map<String, dynamic> data,
  ) {
    final currentFarmerId =
        farmerId.trim();

    if (currentFarmerId.isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // 1. TOP LEVEL farmerId
    // ----------------------------------------------------------

    final orderFarmerId =
        (data['farmerId'] ?? '')
            .toString()
            .trim();

    if (orderFarmerId == currentFarmerId) {
      return true;
    }

    // ----------------------------------------------------------
    // 2. ITEMS farmerId FALLBACK
    // ----------------------------------------------------------

    final items = data['items'];

    if (items is List) {
      for (final rawItem in items) {
        if (rawItem is! Map) {
          continue;
        }

        final item =
            Map<String, dynamic>.from(
          rawItem,
        );

        final itemFarmerId =
            (item['farmerId'] ?? '')
                .toString()
                .trim();

        if (itemFarmerId ==
            currentFarmerId) {
          return true;
        }
      }
    }

    return false;
  }

  // ============================================================
  // GET FARMER ITEMS
  // ============================================================

  List<Map<String, dynamic>> getFarmerItems(
    Map<String, dynamic> data,
  ) {
    final result =
        <Map<String, dynamic>>[];

    final items = data['items'];

    if (items is! List) {
      return result;
    }

    for (final rawItem in items) {
      if (rawItem is! Map) {
        continue;
      }

      final item =
          Map<String, dynamic>.from(
        rawItem,
      );

      final itemFarmerId =
          (item['farmerId'] ?? '')
              .toString()
              .trim();

      // If item explicitly belongs to farmer
      if (itemFarmerId == farmerId) {
        result.add(item);
      }
    }

    // ----------------------------------------------------------
    // If top-level farmerId matches but items don't have
    // farmerId, use all items.
    // ----------------------------------------------------------

    if (result.isEmpty &&
        (data['farmerId'] ?? '')
                .toString()
                .trim() ==
            farmerId.trim()) {
      for (final rawItem in items) {
        if (rawItem is Map) {
          result.add(
            Map<String, dynamic>.from(
              rawItem,
            ),
          );
        }
      }
    }

    return result;
  }

  // ============================================================
  // GET ORDER TOTAL FOR FARMER
  // ============================================================

  double calculateFarmerOrderTotal(
    Map<String, dynamic> data,
  ) {
    final items =
        getFarmerItems(data);

    double total = 0;

    for (final item in items) {
      final itemTotal =
          double.tryParse(
                item['itemTotal']
                        ?.toString() ??
                    '',
              ) ??
              0;

      if (itemTotal > 0) {
        total += itemTotal;
        continue;
      }

      final price =
          double.tryParse(
                item['price']
                        ?.toString() ??
                    '',
              ) ??
              0;

      final quantity =
          double.tryParse(
                item['quantity']
                        ?.toString() ??
                    '',
              ) ??
              0;

      total += price * quantity;
    }

    return total;
  }

  // ============================================================
  // GET ORDER DATE
  // ============================================================

  DateTime getOrderDate(
    Map<String, dynamic> data,
  ) {
    final value =
        data['createdAt'] ??
        data['updatedAt'] ??
        data['orderDate'] ??
        data['timestamp'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime(2000);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      floatingActionButton:
          buildAiAssistantButton(),

      body: SafeArea(
        child: RefreshIndicator(
          color: green,
          backgroundColor: card,

          onRefresh: () async {
            await loadUser();
            await loadWeather();
          },

          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            slivers: [
              SliverToBoxAdapter(
                child: buildHeader(),
              ),

              SliverToBoxAdapter(
                child: buildWelcomeCard(),
              ),

              SliverToBoxAdapter(
                child: buildOverview(),
              ),

              SliverToBoxAdapter(
                child: buildQuickActions(),
              ),

              SliverToBoxAdapter(
                child: buildRecentOrders(),
              ),

              SliverToBoxAdapter(
                child: buildBusinessCard(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF06150C),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF123B20),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: openFarmerDrawer,
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/kisan_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                color: green,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KisanAI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Direct Farm AI',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Spacer(),

          // ======================================================
          // OFFLINE SYNC STATUS CHIP
          // ======================================================

          ValueListenableBuilder<bool>(
            valueListenable:
                OfflineSyncService.instance.isOnlineNotifier,
            builder: (context, isOnline, _) {
              return ValueListenableBuilder<int>(
                valueListenable:
                    OfflineSyncService.instance.pendingCountNotifier,
                builder: (context, pending, _) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfflineSyncScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF0E2415)
                            : const Color(0xFF2E230B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOnline
                              ? const Color(0xFF1E522E)
                              : const Color(0xFF7A580E),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline
                                  ? const Color(0xFF00E676)
                                  : Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline
                                ? (pending > 0 ? '$pending Sync' : 'Live')
                                : '$pending Off',
                            style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF00E676)
                                  : Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ======================================================
          // ON-SCREEN TRANSLATION LANGUAGE SWITCHER
          // ======================================================
          const LanguageSwitchButton(compact: true),
          const SizedBox(width: 5),

          // ======================================================
          // NOTIFICATION
          // ======================================================

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                notificationStream,

            builder:
                (context, snapshot) {
              int unread = 0;

              if (snapshot.hasData) {
                unread =
                    snapshot.data!.docs.where(
                  (doc) {
                    return doc.data()['isRead'] !=
                        true;
                  },
                ).length;
              }

              return GestureDetector(
                onTap:
                    openNotifications,

                child: Stack(
                  clipBehavior:
                      Clip.none,

                  children: [
                    const Icon(
                      Icons
                          .notifications_none_rounded,
                      color:
                          Colors.white,
                      size: 31,
                    ),

                    if (unread > 0)
                      Positioned(
                        right: -6,
                        top: -7,

                        child:
                            Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),

                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.red,
                            shape:
                                BoxShape.circle,
                          ),

                          child:
                              Center(
                            child:
                                Text(
                              unread >
                                      99
                                  ? '99+'
                                  : '$unread',

                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    8,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(
            width: 6,
          ),

          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(
                context,
                '/farmer-profile',
              );

              await loadUser();
            },

            child:
                buildLiveProfileAvatar(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE PROFILE AVATAR
  // ============================================================

  Widget buildLiveProfileAvatar() {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null ||
        uid.isEmpty) {
      return buildFallbackAvatar();
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),

      builder:
          (context, snapshot) {
        String avatar =
            'farmer_1';

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final data =
              snapshot.data!.data();

          if (data != null) {
            final savedAvatar =
                data['profileAvatar']
                    ?.toString()
                    .trim();

            if (savedAvatar !=
                    null &&
                _isValidAvatar(
                    savedAvatar)) {
              avatar =
                  savedAvatar;
            }
          }
        }

        final number =
            int.tryParse(
                  avatar.replaceAll(
                    'farmer_',
                    '',
                  ),
                ) ??
                1;

        final safeNumber =
            number.clamp(1, 5);

        final asset =
            'assets/avatars/farmer_$safeNumber.png';

        return AnimatedSwitcher(
          duration:
              const Duration(
            milliseconds: 300,
          ),

          transitionBuilder:
              (
            child,
            animation,
          ) {
            return ScaleTransition(
              scale:
                  animation,
              child:
                  child,
            );
          },

          child:
              Container(
            key:
                ValueKey(avatar),

            width: 44,
            height: 44,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFF17291A,
              ),

              shape:
                  BoxShape.circle,

              border:
                  Border.all(
                color:
                    green,
                width: 1.5,
              ),
            ),

            padding:
                const EdgeInsets.all(
              2,
            ),

            child:
                ClipOval(
              child:
                  Image.asset(
                asset,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .person_rounded,
                    color:
                        green,
                    size: 27,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // VALID AVATAR
  // ============================================================

  bool _isValidAvatar(
    String avatar,
  ) {
    return avatar ==
            'farmer_1' ||
        avatar ==
            'farmer_2' ||
        avatar ==
            'farmer_3' ||
        avatar ==
            'farmer_4' ||
        avatar ==
            'farmer_5';
  }

  // ============================================================
  // FALLBACK AVATAR
  // ============================================================

  Widget buildFallbackAvatar() {
    return Container(
      width: 44,
      height: 44,

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF17291A,
        ),

        shape:
            BoxShape.circle,

        border:
            Border.all(
          color:
              green,
          width: 1.5,
        ),
      ),

      child:
          const Icon(
        Icons.person_rounded,
        color:
            green,
        size: 27,
      ),
    );
  }

  // ============================================================
  // FARMER DRAWER
  // ============================================================

  void openFarmerDrawer() {
    showGeneralDialog(
      context: context,

      barrierDismissible:
          true,

      barrierLabel:
          'Farmer Menu',

      barrierColor:
          Colors.black.withOpacity(.55),

      transitionDuration:
          const Duration(
        milliseconds: 280,
      ),

      pageBuilder:
          (
        context,
        animation,
        secondaryAnimation,
      ) {
        return Align(
          alignment:
              Alignment.centerLeft,

          child:
              Material(
            color:
                Colors.transparent,

            child:
                SafeArea(
              child:
                  Container(
                width:
                    MediaQuery.of(
                          context,
                        ).size.width *
                        .78,

                height:
                    MediaQuery.of(
                      context,
                    ).size.height,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFF0C110D),

                  borderRadius:
                      BorderRadius.only(
                    topRight:
                        Radius.circular(
                      26,
                    ),
                    bottomRight:
                        Radius.circular(
                      26,
                    ),
                  ),
                ),

                child:
                    Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        25,
                        20,
                        22,
                      ),

                      decoration:
                          const BoxDecoration(
                        gradient:
                            LinearGradient(
                          begin:
                              Alignment.topLeft,

                          end:
                              Alignment.bottomRight,

                          colors: [
                            Color(
                              0xFF12351D,
                            ),
                            Color(
                              0xFF08150C,
                            ),
                          ],
                        ),

                        borderRadius:
                            BorderRadius.only(
                          topRight:
                              Radius.circular(
                            26,
                          ),
                        ),
                      ),

                      child:
                          buildDrawerProfile(),
                    ),

                    Expanded(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          18,
                          12,
                          10,
                        ),

                        child:
                            Column(
                          children: [
                            drawerItem(
                              icon:
                                  Icons.record_voice_over_rounded,
                              title:
                                  'KisanAI Voice Assistant',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const KisanVoiceScreen(),
                                  ),
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons.camera_enhance_rounded,
                              title:
                                  'AI Quality Scanner',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const QualityScannerScreen(),
                                  ),
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons.local_shipping_rounded,
                              title:
                                  'KisanPool Logistics',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const KisanPoolScreen(),
                                  ),
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons.cloud_sync_rounded,
                              title:
                                  'Offline Sync Center',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OfflineSyncScreen(),
                                  ),
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons
                                      .bar_chart_rounded,
                              title:
                                  'Analytics',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FarmerAnalyticsScreen(),
                                  ),
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons
                                      .settings_rounded,
                              title:
                                  'Settings',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );

                                showComingSoon(
                                  'Settings',
                                );
                              },
                            ),

                            drawerItem(
                              icon:
                                  Icons
                                      .help_outline_rounded,
                              title:
                                  'Help & Support',
                              onTap:
                                  () {
                                Navigator.pop(
                                  context,
                                );

                                showComingSoon(
                                  'Help & Support',
                                );
                              },
                            ),

                            const Spacer(),

                            Container(
                              height: 1,
                              color:
                                  const Color(
                                0xFF252C27,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            drawerItem(
                              icon:
                                  Icons
                                      .logout_rounded,
                              title:
                                  'Logout',
                              isLogout:
                                  true,
                              onTap:
                                  handleLogout,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.only(
                        bottom: 18,
                      ),

                      child:
                          Text(
                        'KisanAI • Farmer App',

                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF59605A,
                          ),
                          fontSize:
                              9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      transitionBuilder:
          (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final slideAnimation =
            Tween<Offset>(
          begin:
              const Offset(
            -1,
            0,
          ),

          end:
              Offset.zero,
        ).animate(
          CurvedAnimation(
            parent:
                animation,
            curve:
                Curves.easeOutCubic,
          ),
        );

        return SlideTransition(
          position:
              slideAnimation,

          child:
              child,
        );
      },
    );
  }

  // ============================================================
  // DRAWER PROFILE
  // ============================================================

  Widget buildDrawerProfile() {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null ||
        uid.isEmpty) {
      return buildDrawerProfileContent(
        farmerName,
        'farmer_1',
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),

      builder:
          (context, snapshot) {
        String name =
            farmerName.isNotEmpty ? farmerName : 'Farmer';

        String avatar =
            'farmer_1';

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final data =
              snapshot.data!.data();

          if (data != null) {
            final docName =
                (data['name'] ?? '').toString().trim();
            if (docName.isNotEmpty) {
              name = docName;
            }

            final savedAvatar =
                data['profileAvatar']
                    ?.toString()
                    .trim();

            if (savedAvatar !=
                    null &&
                _isValidAvatar(
                  savedAvatar,
                )) {
              avatar =
                  savedAvatar;
            }
          }
        }

        return buildDrawerProfileContent(
          name,
          avatar,
        );
      },
    );
  }

  // ============================================================
  // DRAWER PROFILE CONTENT
  // ============================================================

  Widget buildDrawerProfileContent(
    String name,
    String avatar,
  ) {
    final number =
        int.tryParse(
              avatar.replaceAll(
                'farmer_',
                '',
              ),
            ) ??
            1;

    final safeNumber =
        number.clamp(
      1,
      5,
    );

    return Row(
      children: [
        Container(
          width: 62,
          height: 62,

          padding:
              const EdgeInsets.all(
            2,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF17291A,
            ),

            shape:
                BoxShape.circle,

            border:
                Border.all(
              color:
                  green,
              width: 2,
            ),
          ),

          child:
              ClipOval(
            child:
                Image.asset(
              'assets/avatars/farmer_$safeNumber.png',

              fit:
                  BoxFit.cover,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons
                      .person_rounded,
                  color:
                      green,
                  size: 35,
                );
              },
            ),
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'KisanAI',

                style:
                    TextStyle(
                  color:
                      green,
                  fontSize:
                      14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                name,

                maxLines:
                    1,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              const Text(
                'Farmer',

                style:
                    TextStyle(
                  color:
                      textSecondary,
                  fontSize:
                      10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap:
          onTap,

      child:
          Container(
        margin:
            const EdgeInsets.only(
          bottom: 6,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        decoration:
            BoxDecoration(
          color: isLogout
              ? Colors.red.withOpacity(.07)
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        child:
            Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color: isLogout
                    ? Colors.red
                        .withOpacity(.10)
                    : green
                        .withOpacity(.10),

                shape:
                    BoxShape.circle,
              ),

              child:
                  Icon(
                icon,

                color: isLogout
                    ? Colors.redAccent
                    : green,

                size: 20,
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child:
                  Text(
                title,

                style:
                    TextStyle(
                  color: isLogout
                      ? Colors.redAccent
                      : Colors.white,

                  fontSize: 14,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            if (!isLogout)
              const Icon(
                Icons
                    .chevron_right_rounded,

                color:
                    Color(0xFF59605A),

                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void showComingSoon(
    String title,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          '$title coming soon',
        ),

        backgroundColor:
            const Color(
          0xFF18221A,
        ),

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> handleLogout() async {
    Navigator.pop(context);

    try {
      await FirebaseAuth.instance
          .signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role',
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Unable to logout',
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  void openNotifications() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const FarmerNotificationsScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN ORDERS
  // ============================================================

  void openOrders() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const FarmerOrdersScreen(),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget buildWelcomeCard() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        5,
      ),

      height:
          205,

      clipBehavior:
          Clip.antiAlias,

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          21,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF2A302B,
          ),
        ),
      ),

      child:
          Stack(
        children: [
          Positioned.fill(
            child:
                Image.asset(
              'assets/images/farmer_home_bg.png',

              fit:
                  BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child:
                DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.centerLeft,

                  end:
                      Alignment.centerRight,

                  colors: [
                    Colors.black
                        .withOpacity(
                      .62,
                    ),

                    Colors.black
                        .withOpacity(
                      .30,
                    ),

                    Colors.black
                        .withOpacity(
                      .48,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              17,
              15,
              15,
              13,
            ),

            child:
                Column(
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            '$greeting,',

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            '$farmerName! 👋',

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            tr('manage_farm_intro'),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  11,
                              height:
                                  1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    buildWallet(),
                  ],
                ),

                const Spacer(),

                buildWeather(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALLET
  // ============================================================

  Widget buildWallet() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          ordersStream,

      builder:
          (context, snapshot) {
        double walletBalance =
            0;

        if (snapshot.hasData &&
            farmerId.isNotEmpty) {
          for (final doc
              in snapshot.data!.docs) {
            final data =
                doc.data();

            if (!orderBelongsToFarmer(
              data,
            )) {
              continue;
            }

            final status =
                (data['orderStatus'] ??
                        data['status'] ??
                        '')
                    .toString()
                    .trim()
                    .toLowerCase();

            final validStatus =
                status ==
                        'accepted' ||
                    status ==
                        'preparing' ||
                    status ==
                        'ready' ||
                    status ==
                        'out for delivery' ||
                    status ==
                        'out_for_delivery' ||
                    status ==
                        'in progress' ||
                    status ==
                        'in_progress' ||
                    status ==
                        'delivered' ||
                    status ==
                        'completed';

            if (!validStatus) {
              continue;
            }

            walletBalance +=
                calculateFarmerOrderTotal(
              data,
            );
          }
        }

        return Container(
          width: 119,

          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xEE101510,
            ),

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFF3E6843,
              ),
            ),
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Container(
                width: 31,
                height: 31,

                decoration:
                    BoxDecoration(
                  color:
                      green.withOpacity(
                    .14,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .account_balance_wallet_rounded,

                  color:
                      green,

                  size:
                      17,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                tr('wallet_balance'),
                style:
                    const TextStyle(
                  color:
                      textSecondary,
                  fontSize:
                      8,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                '₹${walletBalance.toStringAsFixed(0)}',

                maxLines:
                    1,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    const TextStyle(
                  color:
                      green,
                  fontSize:
                  16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                tr('view_transactions'),
                style:
                    const TextStyle(
                  color:
                      green,
                  fontSize:
                      7,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // WEATHER
  // ============================================================

  Widget buildWeather() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WeatherDetailsScreen(
                weather: weather ?? WeatherModel.defaultCoimbatore(),
                location: location,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xEE101510),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF344638),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weather?.weatherIcon ?? '⛅',
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${(weather ?? WeatherModel.defaultCoimbatore()).temperature.round()}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                tr(weather?.condition ?? 'Partly Cloudy'),
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 1,
                height: 15,
                color: Colors.white24,
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.location_on_rounded,
                color: textSecondary,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                '$location, TN',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: green,
                size: 9,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget buildOverview() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          ordersStream,

      builder:
          (context, snapshot) {
        int newOrders =
            0;

        int inProgress =
            0;

        double todayEarnings =
            0;

        if (snapshot.hasError) {
          debugPrint(
            'OVERVIEW ERROR: ${snapshot.error}',
          );
        }

        if (snapshot.hasData &&
            farmerId.isNotEmpty) {
          final now =
              DateTime.now();

          for (final doc
              in snapshot.data!.docs) {
            final data =
                doc.data();

            if (!orderBelongsToFarmer(
              data,
            )) {
              continue;
            }

            final status =
                (data['orderStatus'] ??
                        data['status'] ??
                        '')
                    .toString()
                    .trim()
                    .toLowerCase();

            // ==================================================
            // NEW ORDER
            // ==================================================

            if (status ==
                    'placed' ||
                status ==
                    'pending' ||
                status ==
                    'new' ||
                status ==
                    'requested') {
              newOrders++;
            }

            // ==================================================
            // IN PROGRESS
            // ==================================================

            if (status ==
                    'accepted' ||
                status ==
                    'preparing' ||
                status ==
                    'ready' ||
                status ==
                    'out for delivery' ||
                status ==
                    'out_for_delivery' ||
                status ==
                    'in progress' ||
                status ==
                    'in_progress') {
              inProgress++;
            }

            // ==================================================
            // TODAY EARNINGS
            // ==================================================

            if (status ==
                    'delivered' ||
                status ==
                    'completed') {
              final orderDate =
                  getOrderDate(
                data,
              );

              if (orderDate.year ==
                      now.year &&
                  orderDate.month ==
                      now.month &&
                  orderDate.day ==
                      now.day) {
                todayEarnings +=
                    calculateFarmerOrderTotal(
                  data,
                );
              }
            }
          }
        }

        return Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),

          padding:
              const EdgeInsets.all(
            15,
          ),

          decoration:
              BoxDecoration(
            color:
                card,

            borderRadius:
                BorderRadius.circular(
              21,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFF242A25,
              ),
            ),
          ),

          child:
              Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        Text(
                      tr('today_overview'),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmerAnalyticsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      tr('view_analytics'),
                      style:
                          const TextStyle(
                        color:
                            green,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 11,
              ),

              GridView.count(
                crossAxisCount:
                    2,

                crossAxisSpacing:
                    9,

                mainAxisSpacing:
                    9,

                shrinkWrap:
                    true,

                physics:
                    const NeverScrollableScrollPhysics(),

                childAspectRatio:
                    1.8,

                children: [
                  statCard(
                    icon:
                        Icons
                            .shopping_bag_rounded,

                    value:
                        '$newOrders',

                    label:
                        tr('new_orders'),

                    color:
                        green,

                    note:
                        newOrders == 0
                            ? tr('no_new_orders')
                            : '$newOrders order(s) waiting',
                  ),

                  statCard(
                    icon:
                        Icons
                            .chat_bubble_rounded,

                    value:
                        '5',

                    label:
                        tr('nav_messages'),

                    color:
                        orange,

                    note:
                        tr('nav_messages'),
                  ),

                  statCard(
                    icon:
                        Icons
                            .local_shipping_rounded,

                    value:
                        '$inProgress',

                    label:
                        tr('in_progress'),

                    color:
                        purple,

                    note:
                        inProgress == 0
                            ? tr('no_orders')
                            : '$inProgress order(s) active',
                  ),

                  statCard(
                    icon:
                        Icons
                            .currency_rupee_rounded,

                    value:
                        '₹${todayEarnings.toStringAsFixed(0)}',

                    label:
                        tr('today_earnings'),

                    color:
                        blue,

                    note:
                        todayEarnings == 0
                            ? 'No earnings yet'
                            : tr('from_completed'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String note,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        9,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF151815,
        ),

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              color.withOpacity(
            .22,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width: 35,
            height: 35,

            decoration:
                BoxDecoration(
              color:
                  color.withOpacity(
                .12,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                Icon(
              icon,
              color:
                  color,
              size:
                  18,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                Text(
                  value,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 1,
                ),

                Text(
                  label,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        textSecondary,
                    fontSize:
                        9,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  note,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        textSecondary,
                    fontSize:
                        8,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget buildQuickActions() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            card,

        borderRadius:
            BorderRadius.circular(
          21,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF242A25,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            tr('quick_actions'),
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          SizedBox(
            height: 96,

            child:
                ListView(
              scrollDirection:
                  Axis.horizontal,

              children: [
                quickAction(
                  Icons.record_voice_over_rounded,
                  tr('voice_assistant'),
                  () => Navigator.pushNamed(context, '/kisan-voice'),
                ),

                quickAction(
                  Icons.camera_enhance_rounded,
                  tr('quality_scanner'),
                  () => Navigator.pushNamed(context, '/quality-scanner'),
                ),

                quickAction(
                  Icons.local_shipping_rounded,
                  tr('kisan_pool'),
                  () => Navigator.pushNamed(context, '/kisan-pool'),
                ),

                quickAction(
                  Icons.cloud_sync_rounded,
                  tr('offline_sync'),
                  () => Navigator.pushNamed(context, '/offline-sync'),
                ),

                quickAction(
                  Icons.add_rounded,
                  tr('add_product'),
                  () {
                    Navigator.pushNamed(
                      context,
                      '/add-crop',
                    );
                  },
                ),

                quickAction(
                  Icons
                      .shopping_basket_outlined,
                  tr('manage_products'),
                  () {},
                ),

                quickAction(
                  Icons
                      .assignment_rounded,
                  tr('nav_orders'),
                  openOrders,
                ),

                quickAction(
                  Icons
                      .chat_bubble_rounded,
                  tr('nav_messages'),
                  () {},
                ),

                quickAction(
                  Icons
                      .bar_chart_rounded,
                  tr('analytics'),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FarmerAnalyticsScreen(),
                      ),
                    );
                  },
                ),

                quickAction(
                  Icons
                      .currency_rupee_rounded,
                  tr('payouts'),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FarmerPayoutsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget quickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap:
          onTap,

      child:
          Container(
        width: 86,

        margin:
            const EdgeInsets.only(
          right: 7,
        ),

        padding:
            const EdgeInsets.all(
          8,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFF111411,
          ),

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFF292F2A,
            ),
          ),
        ),

        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [
            Container(
              width: 36,
              height: 36,

              decoration:
                  const BoxDecoration(
                color:
                    green,

                shape:
                    BoxShape.circle,
              ),

              child:
                  Icon(
                icon,
                color:
                    Colors.black,
                size:
                    19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              label,

              textAlign:
                  TextAlign.center,

              maxLines:
                  2,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize:
                    9,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Widget buildRecentOrders() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            card,

        borderRadius:
            BorderRadius.circular(
          21,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF242A25,
          ),
        ),
      ),

      child:
          Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(
                  tr('recent_orders'),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              GestureDetector(
                onTap:
                    openOrders,

                child:
                    Text(
                  '${tr('view_all')}  ›',
                  style:
                      const TextStyle(
                    color:
                        green,
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                ordersStream,

            builder:
                (context, snapshot) {
              // =================================================
              // ERROR
              // =================================================

              if (snapshot.hasError) {
                debugPrint(
                  'RECENT ORDERS ERROR: ${snapshot.error}',
                );

                return Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child:
                      Column(
                    children: [
                      const Icon(
                        Icons
                            .error_outline_rounded,
                        color:
                            Colors.redAccent,
                        size:
                            30,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Unable to load orders',

                        style:
                            TextStyle(
                          color:
                              Colors.redAccent,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // =================================================
              // LOADING
              // =================================================

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding:
                      EdgeInsets.all(
                    25,
                  ),

                  child:
                      CircularProgressIndicator(
                    color:
                        green,
                  ),
                );
              }

              // =================================================
              // EMPTY FIRESTORE
              // =================================================

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return emptyOrders();
              }

              final farmerOrders =
                  <Map<String, dynamic>>[];

              debugPrint(
                '========================================',
              );

              debugPrint(
                'HOME FARMER UID: $farmerId',
              );

              debugPrint(
                'TOTAL ORDERS: ${snapshot.data!.docs.length}',
              );

              // =================================================
              // PROCESS ORDERS
              // =================================================

              for (final doc
                  in snapshot.data!.docs) {
                final data =
                    doc.data();

                final belongs =
                    orderBelongsToFarmer(
                  data,
                );

                debugPrint(
                  'ORDER ${doc.id} | '
                  'farmerId=${data['farmerId']} | '
                  'status=${data['orderStatus']} | '
                  'belongs=$belongs',
                );

                if (!belongs) {
                  continue;
                }

                final farmerItems =
                    getFarmerItems(
                  data,
                );

                final order =
                    <String, dynamic>{
                  ...data,

                  '_docId':
                      doc.id,

                  '_farmerItems':
                      farmerItems,
                };

                farmerOrders.add(
                  order,
                );
              }

              debugPrint(
                'FARMER ORDERS FOUND: '
                '${farmerOrders.length}',
              );

              debugPrint(
                '========================================',
              );

              // =================================================
              // SORT NEWEST FIRST
              // =================================================

              farmerOrders.sort(
                (a, b) {
                  return getOrderDate(
                    b,
                  ).compareTo(
                    getOrderDate(
                      a,
                    ),
                  );
                },
              );

              if (farmerOrders.isEmpty) {
                return emptyOrders();
              }

              final visibleOrders =
                  farmerOrders
                      .take(3)
                      .toList();

              return Column(
                children:
                    visibleOrders.map(
                  (
                    order,
                  ) {
                    return buildRecentOrderItem(
                      order,
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ORDER ITEM
  // ============================================================

  Widget buildRecentOrderItem(
    Map<String, dynamic> order,
  ) {
    final rawItems =
        order['_farmerItems'];

    final items =
        rawItems is List
            ? rawItems
            : <dynamic>[];

    // ============================================================
    // STATUS
    // ============================================================

    final status =
        (order['orderStatus'] ??
                order['status'] ??
                'Pending')
            .toString();

    final normalizedStatus =
        status
            .trim()
            .toLowerCase();

    // ============================================================
    // TOTAL
    // ============================================================

    double total = 0;

    for (final rawItem in items) {
      if (rawItem is! Map) {
        continue;
      }

      final item =
          Map<String, dynamic>.from(
        rawItem,
      );

      final itemTotal =
          double.tryParse(
                item['itemTotal']
                        ?.toString() ??
                    '',
              ) ??
              0;

      if (itemTotal > 0) {
        total += itemTotal;
      } else {
        final price =
            double.tryParse(
                  item['price']
                          ?.toString() ??
                      '',
                ) ??
                0;

        final quantity =
            double.tryParse(
                  item['quantity']
                          ?.toString() ??
                      '',
                ) ??
                0;

        total +=
            price * quantity;
      }
    }

    // ============================================================
    // PRODUCT DETAILS
    // ============================================================

    String productName =
        'Farm Product';

    String quantity =
        '1';

    String unit =
        '';

    if (items.isNotEmpty &&
        items.first is Map) {
      final item =
          Map<String, dynamic>.from(
        items.first,
      );

      productName =
          (item['name'] ??
                  item['productName'] ??
                  item['cropName'] ??
                  'Farm Product')
              .toString();

      quantity =
          (item['quantity'] ??
                  1)
              .toString();

      unit =
          (item['unit'] ??
                  '')
              .toString();
    }

    // ============================================================
    // BUYER
    // ============================================================

    final buyerName =
        (order['buyerName'] ??
                order['customerName'] ??
                'Buyer')
            .toString();

    // ============================================================
    // STATUS COLOR
    // ============================================================

    Color statusColor =
        orange;

    if (normalizedStatus ==
            'placed' ||
        normalizedStatus ==
            'pending' ||
        normalizedStatus ==
            'new' ||
        normalizedStatus ==
            'requested') {
      statusColor =
          orange;
    } else if (normalizedStatus ==
            'accepted' ||
        normalizedStatus ==
            'preparing' ||
        normalizedStatus ==
            'ready') {
      statusColor =
          green;
    } else if (normalizedStatus ==
            'out for delivery' ||
        normalizedStatus ==
            'out_for_delivery' ||
        normalizedStatus ==
            'in progress' ||
        normalizedStatus ==
            'in_progress') {
      statusColor =
          purple;
    } else if (normalizedStatus ==
            'delivered' ||
        normalizedStatus ==
            'completed') {
      statusColor =
          blue;
    } else if (normalizedStatus ==
            'cancelled' ||
        normalizedStatus ==
            'canceled') {
      statusColor =
          Colors.redAccent;
    }

    // ============================================================
    // UI
    // ============================================================

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),

      padding:
          const EdgeInsets.all(
        11,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF151815,
        ),

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF292F2A,
          ),
        ),
      ),

      child:
          Row(
        children: [
          // ======================================================
          // PRODUCT ICON
          // ======================================================

          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  green.withOpacity(
                .10,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                const Icon(
              Icons
                  .shopping_bag_rounded,

              color:
                  green,

              size:
                  23,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ======================================================
          // DETAILS
          // ======================================================

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  productName,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '$quantity $unit • $buyerName',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        textSecondary,
                    fontSize:
                        9,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '₹${total.toStringAsFixed(0)}',

                  style:
                      const TextStyle(
                    color:
                        green,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          // ======================================================
          // STATUS
          // ======================================================

          Container(
            constraints:
                const BoxConstraints(
              maxWidth:
                  72,
            ),

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  8,

              vertical:
                  5,
            ),

            decoration:
                BoxDecoration(
              color:
                  statusColor
                      .withOpacity(
                .10,
              ),

              borderRadius:
                  BorderRadius.circular(
                8,
              ),

              border:
                  Border.all(
                color:
                    statusColor
                        .withOpacity(
                  .25,
                ),
              ),
            ),

            child:
                Text(
              status,

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  TextStyle(
                color:
                    statusColor,

                fontSize:
                    8,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY ORDERS
  // ============================================================

  Widget emptyOrders() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
      ),

      child:
          Column(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration:
                const BoxDecoration(
              color:
                  Color(
                0xFF152419,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .shopping_bag_outlined,

              color:
                  green,

              size:
                  26,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          const Text(
            'No Orders Yet',

            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize:
                  15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'New buyer orders will appear here.',

            style:
                TextStyle(
              color:
                  textSecondary,
              fontSize:
                  10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSINESS CARD
  // ============================================================

  Widget buildBusinessCard() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        5,
        14,
        8,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(
              0xFF0E2515,
            ),
            Color(
              0xFF07120A,
            ),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          21,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF1C4727,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color:
                          green,
                      size:
                          20,
                    ),

                    SizedBox(
                      width:
                          6,
                    ),

                    Flexible(
                      child:
                          Text(
                        'Grow Your Business',

                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'Reach more buyers and increase your farm income.',

                  style:
                      TextStyle(
                    color:
                        textSecondary,
                    fontSize:
                        10,
                    height:
                        1.35,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ElevatedButton(
                  onPressed: () => _showShareStoreSheet(context),

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        green,

                    foregroundColor:
                        Colors.black,

                    elevation:
                        0,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          13,

                      vertical:
                          8,
                    ),

                    minimumSize:
                        Size.zero,

                    tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        9,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Share Your Store',

                    style:
                        TextStyle(
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          const Icon(
            Icons
                .agriculture_rounded,

            color:
                green,

            size:
                60,
          ),
        ],
      ),
    );
  }

  void _showShareStoreSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final farmerName = user?.displayName ?? 'KisanAI Farm';
    final storeUrl = 'https://kisanai.app/farm/${user?.uid ?? "farmer_kovai"}';
    final shareMessage = 'Buy fresh farm produce directly from $farmerName on KisanAI! 🌾 Check out my farm listings here: $storeUrl';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1611),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: Color(0xFF243426), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: green.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.storefront_rounded, color: green, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share Your Farm Store',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect directly with buyers and eliminate middlemen fees.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161F18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF243426)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      storeUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: storeUrl));
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF142718),
                          behavior: SnackBarBehavior.floating,
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: green, size: 18),
                              SizedBox(width: 8),
                              Text('Store link copied to clipboard! Share with buyers.'),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Copy',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareMessage)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Share on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareMessage));
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF142718),
                      behavior: SnackBarBehavior.floating,
                      content: Text('Share message copied! Ready to post on social media.'),
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white70),
                label: const Text('Copy Full Message', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AI ASSISTANT BUTTON
  // ============================================================

  Widget buildAiAssistantButton() {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
        right: 4,
      ),

      child:
          GestureDetector(
        onTap:
            openAiAssistant,

        child:
            Container(
          width: 62,
          height: 62,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF102016,
            ),

            shape:
                BoxShape.circle,

            border:
                Border.all(
              color:
                  const Color(
                0xFF4E9B45,
              ),

              width:
                  1.5,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  .55,
                ),

                blurRadius:
                    14,

                spreadRadius:
                    1,

                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),

              BoxShadow(
                color:
                    const Color(
                  0xFF65D83F,
                ).withOpacity(
                  .08,
                ),

                blurRadius:
                    12,

                spreadRadius:
                    1,
              ),
            ],
          ),

          child:
              Center(
            child:
                Container(
              width: 43,
              height: 43,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF1A3020,
                ),

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      const Color(
                    0xFF65D83F,
                  ).withOpacity(
                    .35,
                  ),

                  width:
                      1,
                ),
              ),

              child:
                  const Icon(
                Icons.mic_rounded,

                color:
                    Color(
                  0xFF79C96A,
                ),

                size:
                    26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPEN AI ASSISTANT
  // ============================================================

  void openAiAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KisanVoiceScreen(),
      ),
    );
  }
}