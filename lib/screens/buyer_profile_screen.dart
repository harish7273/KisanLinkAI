import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'orders_screen.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);
  static const Color cardLight = Color(0xFF1E1E1E);

  // ============================================================
  // FIREBASE
  // ============================================================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // PROFILE STATE
  // ============================================================
  String buyerName = 'Buyer';
  String username = '';
  String email = '';
  String shopName = 'My Store';
  String phone = '';
  String deliveryAddress = '';
  String district = '';
  String state = '';
  String selectedAvatar = 'buyer_1';

  int totalOrders = 0;
  int activeOrders = 0;
  int deliveredOrders = 0;

  bool loading = true;

  // Notification Preferences
  bool _notifyOrderUpdates = true;
  bool _notifyDeliveryTracking = true;
  bool _notifyFarmerAuctions = false;

  // ============================================================
  // ANIMATION
  // ============================================================
  late AnimationController _avatarController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _avatarAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(
        parent: _avatarController,
        curve: Curves.easeInOut,
      ),
    );

    _avatarController.repeat(reverse: true);

    _loadProfile();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE & ORDERS STATS
  // ============================================================
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      final data = doc.data() ?? {};

      final name = data['name']?.toString() ?? '';
      final uName = data['username']?.toString() ?? '';
      final store = data['shopName']?.toString() ?? '';
      final ph = (data['phone'] ?? data['phoneNumber'] ?? data['mobile'])?.toString() ?? '';
      final addr = (data['deliveryAddress'] ?? data['address'] ?? data['location'])?.toString() ?? '';
      final dist = data['district']?.toString() ?? '';
      final st = data['state']?.toString() ?? '';
      final avatar = data['profileAvatar']?.toString() ?? '';

      // Count Orders
      int tot = 0;
      int act = 0;
      int del = 0;

      try {
        final ordersSnap = await _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: user.uid)
            .get();

        tot = ordersSnap.docs.length;
        for (final oDoc in ordersSnap.docs) {
          final s = oDoc.data()['orderStatus']?.toString().toLowerCase() ?? '';
          if (s == 'delivered' || s == 'completed') {
            del++;
          } else if (s != 'cancelled') {
            act++;
          }
        }
      } catch (e) {
        debugPrint('Orders count query error: $e');
      }

      if (!mounted) return;

      setState(() {
        buyerName = name.trim().isNotEmpty
            ? name.trim()
            : (uName.trim().isNotEmpty ? uName.trim() : 'Buyer');
        username = uName.trim();
        email = user.email ?? data['email']?.toString() ?? '';
        shopName = store.trim().isNotEmpty ? store.trim() : '$buyerName Store';
        phone = ph.trim();
        deliveryAddress = addr.trim();
        district = dist.trim();
        state = st.trim();

        if (avatar.startsWith('buyer_')) {
          selectedAvatar = avatar;
        }

        totalOrders = tot;
        activeOrders = act;
        deliveredOrders = del;

        loading = false;
      });
    } catch (e) {
      debugPrint('Profile loading error: $e');
      if (!mounted) return;
      setState(() {
        email = user.email ?? '';
        loading = false;
      });
    }
  }

  // ============================================================
  // SAVE AVATAR
  // ============================================================
  Future<void> _saveAvatar(String avatar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'profileAvatar': avatar,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => selectedAvatar = avatar);

      _showSuccess('Avatar updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to update avatar: $e');
    }
  }

  // ============================================================
  // EDIT PROFILE SHEET
  // ============================================================
  void _openEditProfileSheet() {
    final nameCtrl = TextEditingController(text: buyerName);
    final storeCtrl = TextEditingController(text: shopName);
    final phoneCtrl = TextEditingController(text: phone);
    final addressCtrl = TextEditingController(text: deliveryAddress);
    final districtCtrl = TextEditingController(text: district);

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Buyer Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      hint: 'e.g. Ramesh Kumar',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Store / Business Name
                    _buildTextField(
                      controller: storeCtrl,
                      label: 'Store / Business Name',
                      hint: 'e.g. Fresh Supermart',
                      icon: Icons.storefront_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    _buildTextField(
                      controller: phoneCtrl,
                      label: 'Contact Phone Number',
                      hint: 'e.g. +91 9876543210',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // Delivery Address
                    _buildTextField(
                      controller: addressCtrl,
                      label: 'Default Delivery Address',
                      hint: 'Street, building, area',
                      icon: Icons.location_on_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // District
                    _buildTextField(
                      controller: districtCtrl,
                      label: 'District / City',
                      hint: 'e.g. Coimbatore',
                      icon: Icons.location_city_rounded,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = nameCtrl.text.trim();
                                final newStore = storeCtrl.text.trim();
                                final newPhone = phoneCtrl.text.trim();
                                final newAddress = addressCtrl.text.trim();
                                final newDistrict = districtCtrl.text.trim();

                                if (newName.isEmpty) {
                                  _showError('Full name cannot be empty');
                                  return;
                                }

                                setSheetState(() => isSaving = true);

                                final user = _auth.currentUser;
                                if (user != null) {
                                  try {
                                    await _firestore
                                        .collection('users')
                                        .doc(user.uid)
                                        .set({
                                      'name': newName,
                                      'shopName': newStore.isNotEmpty
                                          ? newStore
                                          : '$newName Store',
                                      'phone': newPhone,
                                      'deliveryAddress': newAddress,
                                      'address': newAddress,
                                      'district': newDistrict,
                                      'updatedAt':
                                          FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));

                                    if (!mounted) return;

                                    setState(() {
                                      buyerName = newName;
                                      shopName = newStore.isNotEmpty
                                          ? newStore
                                          : '$newName Store';
                                      phone = newPhone;
                                      deliveryAddress = newAddress;
                                      district = newDistrict;
                                    });

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    _showSuccess('Profile updated successfully!');
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    _showError('Failed to save profile: $e');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // AVATAR PICKER
  // ============================================================
  void _openAvatarPicker() {
    String temporaryAvatar = selectedAvatar;

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Pick an avatar for your buyer profile',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preview
                    AnimatedBuilder(
                      animation: _avatarAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _avatarAnimation.value),
                          child: child,
                        );
                      },
                      child: _avatarImage(temporaryAvatar, 100),
                    ),
                    const SizedBox(height: 24),

                    // Avatars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final avatar = 'buyer_${index + 1}';
                        final selected = temporaryAvatar == avatar;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() => temporaryAvatar = avatar);
                          },
                          child: AnimatedScale(
                            scale: selected ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected ? orange : Colors.white12,
                                      width: selected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/avatars/$avatar.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF222222),
                                        child: const Icon(Icons.person, color: orange),
                                      ),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 25),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveAvatar(temporaryAvatar);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Avatar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SECURITY SHEET
  // ============================================================
  void _openSecuritySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage password and login credentials for $email',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Reset Password option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: orange),
                  ),
                  title: const Text(
                    'Reset Password via Email',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Send a secure password reset link to your email',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (email.isEmpty) {
                      _showError('No email associated with this account.');
                      return;
                    }

                    try {
                      await _auth.sendPasswordResetEmail(email: email);
                      _showSuccess('Password reset link sent to $email');
                    } catch (e) {
                      _showError('Failed to send reset link: $e');
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NOTIFICATION SETTINGS SHEET
  // ============================================================
  void _openNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preferences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Customize what alerts you receive',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 18),

                    SwitchListTile(
                      activeThumbColor: orange,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Order Status Updates',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Get notified when orders are accepted or dispatched',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      value: _notifyOrderUpdates,
                      onChanged: (val) {
                        setSheetState(() => _notifyOrderUpdates = val);
                        setState(() => _notifyOrderUpdates = val);
                      },
                    ),

                    SwitchListTile(
                      activeThumbColor: orange,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Live Delivery Tracking Alerts',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Real-time driver updates and arrival notifications',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      value: _notifyDeliveryTracking,
                      onChanged: (val) {
                        setSheetState(() => _notifyDeliveryTracking = val);
                        setState(() => _notifyDeliveryTracking = val);
                      },
                    ),

                    SwitchListTile(
                      activeThumbColor: orange,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Farmer Auctions & Best Prices',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Daily updates on high-yield harvest prices',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      value: _notifyFarmerAuctions,
                      onChanged: (val) {
                        setSheetState(() => _notifyFarmerAuctions = val);
                        setState(() => _notifyFarmerAuctions = val);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out from KisanAI?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/role', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showError('Logout failed: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: orange, strokeWidth: 2),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: orange,
                backgroundColor: card,
                onRefresh: _loadProfile,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Buyer Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openEditProfileSheet,
                          icon: const Icon(Icons.edit_note_rounded, color: orange, size: 26),
                          tooltip: 'Edit Profile',
                        ),
                        IconButton(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    // Quick Stats Row
                    _buildStatsRow(),
                    const SizedBox(height: 24),

                    // Account Section
                    const Text(
                      'Account & Store',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _option(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Details',
                      subtitle: '$buyerName • ${phone.isNotEmpty ? phone : "Tap to add phone"}',
                      onTap: () {
                        _showDetails('Personal Details', [
                          ['Name', buyerName],
                          ['Username', username.isNotEmpty ? username : 'Not set'],
                          ['Email', email.isNotEmpty ? email : 'Not available'],
                          ['Phone', phone.isNotEmpty ? phone : 'Not added'],
                        ]);
                      },
                    ),

                    _option(
                      icon: Icons.storefront_outlined,
                      title: 'Store Information',
                      subtitle: shopName,
                      onTap: () {
                        _showDetails('Store Information', [
                          ['Store Name', shopName],
                          ['Role', 'Direct Farm Buyer'],
                          ['District', district.isNotEmpty ? district : 'Not specified'],
                        ]);
                      },
                    ),

                    _option(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery Address',
                      subtitle: deliveryAddress.isNotEmpty
                          ? deliveryAddress
                          : 'Tap to configure shipping address',
                      onTap: _openEditProfileSheet,
                    ),

                    _option(
                      icon: Icons.local_shipping_outlined,
                      title: 'My Orders & Tracking',
                      subtitle: '$totalOrders Total • $activeOrders In Progress',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersScreen()),
                        );
                      },
                    ),

                    _option(
                      icon: Icons.lock_outline_rounded,
                      title: 'Security & Password',
                      subtitle: 'Reset password and secure account',
                      onTap: _openSecuritySheet,
                    ),

                    const SizedBox(height: 18),

                    // App Preferences
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _option(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage order tracking and auction alerts',
                      onTap: _openNotificationSheet,
                    ),

                    _option(
                      icon: Icons.headset_mic_outlined,
                      title: 'Customer Support',
                      subtitle: 'KisanAI Direct Marketplace Helpline',
                      onTap: () {
                        _showDetails('Help & Support', [
                          ['Helpline', '+91 1800-425-KISAN'],
                          ['Support Email', 'support@kisanai.app'],
                          ['Operational Hours', '6:00 AM - 9:00 PM (Daily)'],
                          ['Platform', 'Farm-to-Door Delivery Ecosystem'],
                        ]);
                      },
                    ),

                    _option(
                      icon: Icons.info_outline_rounded,
                      title: 'About KisanAI',
                      subtitle: 'Version 1.0.0 • Direct farmer-to-buyer platform',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'KisanAI',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            Icons.eco_rounded,
                            color: orange,
                            size: 35,
                          ),
                          children: const [
                            Text(
                              'KisanAI is an ultra-reliable direct farmer-to-buyer agricultural commerce ecosystem empowering fair pricing and real-time live delivery.',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Logout Button
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: .30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 19),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'KisanAI • Buyer Ecosystem',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PROFILE CARD WIDGET
  // ============================================================
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: orange.withValues(alpha: .18),
        ),
      ),
      child: Column(
        children: [
          // Avatar Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _avatarAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _avatarAnimation.value),
                    child: child,
                  );
                },
                child: _avatarImage(selectedAvatar, 98),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _openAvatarPicker,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: background, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            buyerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Store Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded, color: orange, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),

          // Email
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],

          const SizedBox(height: 14),

          // Actions (Edit Profile & Change Avatar)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openEditProfileSheet,
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: const BorderSide(color: orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _openAvatarPicker,
                icon: const Icon(Icons.face_rounded, size: 15),
                label: const Text('Avatar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS ROW WIDGET
  // ============================================================
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Orders',
            value: '$totalOrders',
            icon: Icons.receipt_long_rounded,
            color: orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'In Transit',
            value: '$activeOrders',
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF29B6F6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Delivered',
            value: '$deliveredOrders',
            icon: Icons.check_circle_rounded,
            color: green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR IMAGE WIDGET
  // ============================================================
  Widget _avatarImage(String avatar, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: orange.withValues(alpha: .25),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/avatars/$avatar.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF1A1A1A),
            child: const Icon(Icons.person_rounded, color: orange, size: 42),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPTION TILE WIDGET
  // ============================================================
  Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: orange, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD HELPER
  // ============================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: orange, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: cardLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: orange),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS BOTTOM SHEET
  // ============================================================
  void _showDetails(String title, List<List<String>> details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openEditProfileSheet();
                      },
                      icon: const Icon(Icons.edit_rounded, color: orange, size: 16),
                      label: const Text('Edit', style: TextStyle(color: orange)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...details.map((item) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item[0],
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item[1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}