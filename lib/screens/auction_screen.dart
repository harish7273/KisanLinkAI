import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_auction_screen.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  int _selectedTab = 0;

  String _searchQuery = '';

  Timer? _countdownTimer;

  // ============================================================
  // FIREBASE
  // ============================================================

  final CollectionReference<Map<String, dynamic>>
      _auctionCollection =
      FirebaseFirestore.instance.collection('auctions');

  // ============================================================
  // COLORS
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF080A09);

  static const Color surfaceColor =
      Color(0xFF101512);

  static const Color cardColor =
      Color(0xFF151D17);

  static const Color primaryGreen =
      Color(0xFF22A447);

  static const Color darkGreen =
      Color(0xFF08752C);

  static const Color softGreen =
      Color(0xFF163821);

  static const Color primaryText =
      Color(0xFFF2F5F2);

  static const Color secondaryText =
      Color(0xFFA2AAA4);

  static const Color mutedText =
      Color(0xFF737B75);

  static const Color borderColor =
      Color(0xFF263129);

  static const Color redColor =
      Color(0xFFFF5252);

  // ============================================================
  // TABS
  // ============================================================

  final List<String> _tabs = [
    'My Auctions',
    'Active',
    'Upcoming',
    'Completed',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            _buildSearchBar(),
            Expanded(
              child: _buildAuctionStream(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF075A25),
            Color(0xFF08752C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // STATUS BAR

          Row(
            children: [
              Text(
                '9:41',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.signal_cellular_alt,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.wifi,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.battery_full,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),

          const SizedBox(height: 15),

          // TITLE

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auction',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage your product auctions',
                      style: GoogleFonts.inter(
                        color: Colors.white
                            .withAlpha(200),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              // NOTIFICATION

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .notifications_none_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),

                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration:
                          const BoxDecoration(
                        color: redColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '5',
                          style:
                              GoogleFonts.inter(
                            color:
                                Colors.white,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        0,
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: List.generate(
            _tabs.length,
            (index) {
              final bool selected =
                  _selectedTab == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? darkGreen
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[index],
                        style:
                            GoogleFonts.inter(
                          color: selected
                              ? Colors.white
                              : secondaryText,
                          fontSize: 8.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration:
                  BoxDecoration(
                color: surfaceColor,
                borderRadius:
                    BorderRadius.circular(9),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: TextField(
                controller:
                    _searchController,
                style:
                    GoogleFonts.inter(
                  color: primaryText,
                  fontSize: 10,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      'Search auctions...',
                  hintStyle:
                      GoogleFonts.inter(
                    color: mutedText,
                    fontSize: 9.5,
                  ),
                  prefixIcon:
                      const Icon(
                    Icons.search_rounded,
                    color: mutedText,
                    size: 18,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController
                                    .clear();
                              },
                              icon:
                                  const Icon(
                                Icons.close,
                                color:
                                    mutedText,
                                size: 15,
                              ),
                            )
                          : null,
                  border:
                      InputBorder.none,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(
                color: surfaceColor,
                borderRadius:
                    BorderRadius.circular(9),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: secondaryText,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIREBASE STREAM
  // ============================================================

  Widget _buildAuctionStream() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _auctionCollection
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            snapshot.error.toString(),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        final List<Map<String, dynamic>>
            auctions = [];

        for (final doc in docs) {
          final data = doc.data();

          final Map<String, dynamic>
              auction = {
            'id': doc.id,
            ...data,
          };

          if (_matchesSearch(auction) &&
              _matchesTab(auction)) {
            auctions.add(auction);
          }
        }

        if (auctions.isEmpty) {
          return _buildEmptyState();
        }

        return ListView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.only(
            bottom: 18,
          ),
          children: [
            _buildSectionTitle(
              _getSectionTitle(),
              auctions.length,
            ),

            const SizedBox(height: 8),

            ...auctions.map(
              (auction) {
                final status =
                    (auction['status'] ??
                            '')
                        .toString()
                        .toLowerCase();

                if (status == 'active') {
                  return _buildActiveCard(
                    auction,
                  );
                }

                if (status == 'upcoming') {
                  return _buildUpcomingCard(
                    auction,
                  );
                }

                return _buildCompletedCard(
                  auction,
                );
              },
            ),

            const SizedBox(height: 8),

            _buildCreateAuctionButton(),
          ],
        );
      },
    );
  }

  // ============================================================
  // SEARCH MATCH
  // ============================================================

  bool _matchesSearch(
    Map<String, dynamic> auction,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final productName =
        (auction['productName'] ?? '')
            .toString()
            .toLowerCase();

    final quality =
        (auction['quality'] ?? '')
            .toString()
            .toLowerCase();

    final category =
        (auction['category'] ?? '')
            .toString()
            .toLowerCase();

    return productName.contains(
          _searchQuery,
        ) ||
        quality.contains(
          _searchQuery,
        ) ||
        category.contains(
          _searchQuery,
        );
  }

  // ============================================================
  // TAB MATCH
  // ============================================================

  bool _matchesTab(
    Map<String, dynamic> auction,
  ) {
    final String status =
        (auction['status'] ?? '')
            .toString()
            .toLowerCase();

    switch (_selectedTab) {
      case 0:
        return auction['farmerId'] ==
            _currentUserId;

      case 1:
        return status == 'active';

      case 2:
        return status == 'upcoming';

      case 3:
        return status == 'completed';

      default:
        return true;
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    int count,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          Text(
            title,
            style:
                GoogleFonts.inter(
              color: primaryText,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 18,
            height: 18,
            decoration:
                const BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style:
                    GoogleFonts.inter(
                  color: primaryGreen,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE CARD
  // ============================================================

  Widget _buildActiveCard(
    Map<String, dynamic> auction,
  ) {
    final String productName =
        _stringValue(
      auction['productName'],
      'Unknown Product',
    );

    final String imageAsset =
        _stringValue(
      auction['imageAsset'],
      '',
    );

    final String imageUrl =
        _stringValue(
      auction['imageUrl'],
      '',
    );

    final String quantity =
        _stringValue(
      auction['quantity'],
      '0',
    );

    final String unit =
        _stringValue(
      auction['unit'],
      'kg',
    );

    final String quality =
        _stringValue(
      auction['quality'],
      'Good Quality',
    );

    final String startPrice =
        _formatPrice(
      auction['startPrice'],
    );

    final String highestBid =
        _formatPrice(
      auction['highestBid'] ??
          auction['startPrice'],
    );

    final String bidCount =
        _stringValue(
      auction['bidCount'],
      '0',
    );

    final DateTime? endTime =
        _timestampToDate(
      auction['endTime'],
    );

    final String remaining =
        endTime == null
            ? '--'
            : _formatRemaining(
                endTime,
              );

    return GestureDetector(
      onTap: () {
        _showAuctionDetails(
          auction,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          8,
        ),
        padding:
            const EdgeInsets.all(6),
        height: 94,
        decoration:
            BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            _buildProductImage(
              imageAsset: imageAsset,
              imageUrl: imageUrl,
              isLive: true,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        GoogleFonts.inter(
                      color: primaryText,
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '$quantity $unit • $quality',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        GoogleFonts.inter(
                      color:
                          secondaryText,
                      fontSize: 7.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Start Price',
                    style:
                        GoogleFonts.inter(
                      color: mutedText,
                      fontSize: 6.8,
                    ),
                  ),

                  Text(
                    '$startPrice / $unit',
                    style:
                        GoogleFonts.inter(
                      color: primaryText,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Highest Bid',
                    style:
                        GoogleFonts.inter(
                      color: mutedText,
                      fontSize: 6.8,
                    ),
                  ),

                  Text(
                    '$highestBid / $unit',
                    style:
                        GoogleFonts.inter(
                      color: primaryGreen,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: 67,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color: softGreen,
                      borderRadius:
                          BorderRadius.circular(
                        5,
                      ),
                    ),
                    child: Text(
                      remaining,
                      style:
                          GoogleFonts.inter(
                        color:
                            primaryGreen,
                        fontSize: 6.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: mutedText,
                        size: 10,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        '$bidCount Bids',
                        style:
                            GoogleFonts.inter(
                          color:
                              secondaryText,
                          fontSize: 6.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: mutedText,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPCOMING CARD
  // ============================================================

  Widget _buildUpcomingCard(
    Map<String, dynamic> auction,
  ) {
    final String productName =
        _stringValue(
      auction['productName'],
      'Unknown Product',
    );

    final String imageAsset =
        _stringValue(
      auction['imageAsset'],
      '',
    );

    final String imageUrl =
        _stringValue(
      auction['imageUrl'],
      '',
    );

    final String quantity =
        _stringValue(
      auction['quantity'],
      '0',
    );

    final String unit =
        _stringValue(
      auction['unit'],
      'kg',
    );

    final String quality =
        _stringValue(
      auction['quality'],
      'Good Quality',
    );

    final String startPrice =
        _formatPrice(
      auction['startPrice'],
    );

    final DateTime? startTime =
        _timestampToDate(
      auction['startTime'],
    );

    return GestureDetector(
      onTap: () {
        _showAuctionDetails(
          auction,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          8,
        ),
        padding:
            const EdgeInsets.all(6),
        height: 82,
        decoration:
            BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            _buildProductImage(
              imageAsset: imageAsset,
              imageUrl: imageUrl,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        GoogleFonts.inter(
                      color: primaryText,
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        color: mutedText,
                        size: 8,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Expanded(
                        child: Text(
                          startTime == null
                              ? 'Scheduled'
                              : _formatDateTime(
                                  startTime,
                                ),
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts.inter(
                            color:
                                secondaryText,
                            fontSize: 7,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$quantity $unit • $quality',
                    style:
                        GoogleFonts.inter(
                      color:
                          secondaryText,
                      fontSize: 7,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Start Price  '
                    '$startPrice / $unit',
                    style:
                        GoogleFonts.inter(
                      color: primaryText,
                      fontSize: 7.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF172B3E),
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: Text(
                'Scheduled',
                style:
                    GoogleFonts.inter(
                  color:
                      const Color(0xFF65A8E6),
                  fontSize: 6.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETED CARD
  // ============================================================

  Widget _buildCompletedCard(
    Map<String, dynamic> auction,
  ) {
    final String productName =
        _stringValue(
      auction['productName'],
      'Unknown Product',
    );

    final String imageAsset =
        _stringValue(
      auction['imageAsset'],
      '',
    );

    final String imageUrl =
        _stringValue(
      auction['imageUrl'],
      '',
    );

    final String quantity =
        _stringValue(
      auction['quantity'],
      '0',
    );

    final String unit =
        _stringValue(
      auction['unit'],
      'kg',
    );

    final String highestBid =
        _formatPrice(
      auction['highestBid'],
    );

    return GestureDetector(
      onTap: () {
        _showAuctionDetails(
          auction,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          8,
        ),
        padding:
            const EdgeInsets.all(6),
        height: 75,
        decoration:
            BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            _buildProductImage(
              imageAsset: imageAsset,
              imageUrl: imageUrl,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style:
                        GoogleFonts.inter(
                      color: primaryText,
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$quantity $unit',
                    style:
                        GoogleFonts.inter(
                      color:
                          secondaryText,
                      fontSize: 7.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Final Bid  '
                    '$highestBid / $unit',
                    style:
                        GoogleFonts.inter(
                      color: primaryGreen,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF252A26),
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: Text(
                'Completed',
                style:
                    GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 6.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage({
    required String imageAsset,
    required String imageUrl,
    bool isLive = false,
  }) {
    Widget image;

    // New auction documents use imageAsset.
    if (imageAsset.isNotEmpty) {
      image = Image.asset(
        imageAsset,
        width: 68,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _imagePlaceholder();
        },
      );
    }

    // Old auction documents can still use imageUrl.
    else if (imageUrl.isNotEmpty) {
      image = Image.network(
        imageUrl,
        width: 68,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _imagePlaceholder();
        },
        loadingBuilder:
            (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return _imagePlaceholder(
            loading: true,
          );
        },
      );
    } else {
      image = _imagePlaceholder();
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(7),
          child: image,
        ),

        if (isLive)
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration:
                  BoxDecoration(
                color: darkGreen,
                borderRadius:
                    BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 4,
                  ),
                  const SizedBox(
                    width: 2,
                  ),
                  Text(
                    'Live',
                    style:
                        GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 6.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder({
    bool loading = false,
  }) {
    return Container(
      width: 68,
      height: 78,
      color:
          const Color(0xFF203126),
      child: Icon(
        loading
            ? Icons.hourglass_empty
            : Icons.eco_outlined,
        color: primaryGreen,
        size: 27,
      ),
    );
  }

  // ============================================================
  // CREATE AUCTION BUTTON
  // ============================================================

  Widget _buildCreateAuctionButton() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CreateAuctionScreen(),
              ),
            );
          },
          style:
              ElevatedButton.styleFrom(
            backgroundColor: darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'Create New Auction',
                style:
                    GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    String message;

    switch (_selectedTab) {
      case 0:
        message =
            'You have no auctions yet';
        break;

      case 1:
        message =
            'No active auctions';
        break;

      case 2:
        message =
            'No upcoming auctions';
        break;

      case 3:
        message =
            'No completed auctions';
        break;

      default:
        message =
            'No auctions found';
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
                  const BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: primaryGreen,
                size: 32,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.inter(
                color:
                    secondaryText,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 18),

            _buildCreateAuctionButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: redColor,
              size: 35,
            ),

            const SizedBox(height: 10),

            Text(
              'Unable to load auctions',
              style:
                  GoogleFonts.inter(
                color: primaryText,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  GoogleFonts.inter(
                color: mutedText,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          surfaceColor,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Auctions',
                style:
                    GoogleFonts.inter(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              _buildFilterOption(
                'My Auctions',
                0,
              ),

              _buildFilterOption(
                'Active',
                1,
              ),

              _buildFilterOption(
                'Upcoming',
                2,
              ),

              _buildFilterOption(
                'Completed',
                3,
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTER OPTION
  // ============================================================

  Widget _buildFilterOption(
    String title,
    int index,
  ) {
    final bool selected =
        _selectedTab == index;

    return ListTile(
      contentPadding:
          EdgeInsets.zero,

      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: selected
            ? primaryGreen
            : mutedText,
      ),

      title: Text(
        title,
        style:
            GoogleFonts.inter(
          color: selected
              ? primaryText
              : secondaryText,
          fontSize: 11,
          fontWeight: selected
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),

      onTap: () {
        setState(() {
          _selectedTab = index;
        });

        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // AUCTION DETAILS
  // ============================================================

  void _showAuctionDetails(
    Map<String, dynamic> auction,
  ) {
    final String productName =
        _stringValue(
      auction['productName'],
      'Auction',
    );

    final String imageAsset =
        _stringValue(
      auction['imageAsset'],
      '',
    );

    final String imageUrl =
        _stringValue(
      auction['imageUrl'],
      '',
    );

    final String highestBid =
        _formatPrice(
      auction['highestBid'] ??
          auction['startPrice'],
    );

    final String quantity =
        _stringValue(
      auction['quantity'],
      '0',
    );

    final String unit =
        _stringValue(
      auction['unit'],
      'kg',
    );

    final String quality =
        _stringValue(
      auction['quality'],
      'Good Quality',
    );

    final String bidCount =
        _stringValue(
      auction['bidCount'],
      '0',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor:
          surfaceColor,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProductImage(
                    imageAsset: imageAsset,
                    imageUrl: imageUrl,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      productName,
                      style:
                          GoogleFonts.inter(
                        color: primaryText,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon:
                        const Icon(
                      Icons.close,
                      color:
                          secondaryText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                '$quantity $unit • $quality',
                style:
                    GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Current Highest Bid',
                style:
                    GoogleFonts.inter(
                  color: mutedText,
                  fontSize: 9,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '$highestBid / $unit',
                style:
                    GoogleFonts.inter(
                  color: primaryGreen,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: mutedText,
                    size: 15,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    '$bidCount bids',
                    style:
                        GoogleFonts.inter(
                      color:
                          secondaryText,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 45,
                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        darkGreen,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        9,
                      ),
                    ),
                  ),
                  child: Text(
                    'View Auction',
                    style:
                        GoogleFonts.inter(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  DateTime? _timestampToDate(
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

    return null;
  }

  // ============================================================
  // REMAINING TIME
  // ============================================================

  String _formatRemaining(
    DateTime endTime,
  ) {
    final Duration difference =
        endTime.difference(
      DateTime.now(),
    );

    if (difference.isNegative) {
      return 'Ended';
    }

    final int totalHours =
        difference.inHours;

    final int minutes =
        difference.inMinutes.remainder(
      60,
    );

    if (totalHours >= 24) {
      final int days =
          totalHours ~/ 24;

      final int hours =
          totalHours % 24;

      return '${days}d ${hours}h';
    }

    return '${totalHours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final DateTime now =
        DateTime.now();

    final bool today =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final DateTime tomorrow =
        now.add(
      const Duration(days: 1),
    );

    final bool isTomorrow =
        date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final int hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final String period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    if (today) {
      return 'Today, $hour:$minute $period';
    }

    if (isTomorrow) {
      return 'Tomorrow, $hour:$minute $period';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // PRICE FORMAT
  // ============================================================

  String _formatPrice(
    dynamic value,
  ) {
    if (value == null) {
      return '₹0';
    }

    if (value is num) {
      return '₹${value.toStringAsFixed(0)}';
    }

    final double? parsed =
        double.tryParse(
      value.toString(),
    );

    if (parsed != null) {
      return '₹${parsed.toStringAsFixed(0)}';
    }

    return '₹$value';
  }

  // ============================================================
  // STRING VALUE
  // ============================================================

  String _stringValue(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  String _getSectionTitle() {
    switch (_selectedTab) {
      case 0:
        return 'My Auctions';

      case 1:
        return 'Active Auctions';

      case 2:
        return 'Upcoming Auctions';

      case 3:
        return 'Completed Auctions';

      default:
        return 'Auctions';
    }
  }
}