import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/language_service.dart';

class FarmerPayoutsScreen extends StatefulWidget {
  const FarmerPayoutsScreen({super.key});

  @override
  State<FarmerPayoutsScreen> createState() => _FarmerPayoutsScreenState();
}

class _FarmerPayoutsScreenState extends State<FarmerPayoutsScreen> {
  static const Color green = Color(0xFF22C55E);
  static const Color greenAccent = Color(0xFF4ADE80);
  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080D09);
  static const Color card = Color(0xFF131A14);
  static const Color border = Color(0xFF243426);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessingWithdrawal = false;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final farmerUid = user?.uid ?? 'farmer_demo';

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              LanguageService.tr('payouts', defaultText: 'Earnings & Payouts'),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: greenAccent),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh Balance',
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('orders').snapshots(),
            builder: (context, snapshot) {
              double availableBalance = 0;
              double inTransitAmount = 0;
              double lifetimeEarnings = 0;
              final List<Map<String, dynamic>> settlementOrders = [];

              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data();
                  final fid = (data['farmerId'] ?? '').toString();
                  final items = data['items'] as List<dynamic>? ?? [];
                  bool belongs = fid == farmerUid;
                  if (!belongs) {
                    for (final it in items) {
                      if (it is Map && it['farmerId'] == farmerUid) {
                        belongs = true;
                        break;
                      }
                    }
                  }

                  if (!belongs) continue;

                  final status = (data['orderStatus'] ?? '').toString().toLowerCase();
                  final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                  final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
                  final netFarmerEarnings = (totalAmount - deliveryFee) > 0 ? (totalAmount - deliveryFee) : totalAmount;

                  if (status == 'delivered' || status == 'completed') {
                    availableBalance += netFarmerEarnings;
                    lifetimeEarnings += netFarmerEarnings;
                    settlementOrders.add({...data, 'docId': doc.id, 'netEarnings': netFarmerEarnings});
                  } else if (status == 'out for delivery' || status == 'picked up' || status == 'in progress' || status == 'accepted') {
                    inTransitAmount += netFarmerEarnings;
                    settlementOrders.add({...data, 'docId': doc.id, 'netEarnings': netFarmerEarnings});
                  }
                }
              }

              // Also check dedicated wallets collection
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection('wallets').doc(farmerUid).snapshots(),
                builder: (context, walletSnap) {
                  double walletCredit = 0;
                  if (walletSnap.hasData && walletSnap.data!.exists) {
                    walletCredit = (walletSnap.data!.data()?['balance'] as num?)?.toDouble() ?? 0.0;
                  }
                  final finalBalance = availableBalance + walletCredit;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zero Commission Guarantee Banner
                        _buildZeroCommissionBanner(),

                        const SizedBox(height: 16),

                        // Main Balance Card
                        _buildBalanceCard(finalBalance, inTransitAmount, lifetimeEarnings),

                        const SizedBox(height: 18),

                        // Quick Action Buttons (Withdraw, Direct Pay QR)
                        _buildActionRow(finalBalance, farmerUid),

                        const SizedBox(height: 24),

                        // Instant Settlement History
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Instant Settlements',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${settlementOrders.length} Records',
                                style: const TextStyle(color: greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (settlementOrders.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: settlementOrders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final order = settlementOrders[index];
                              return _buildSettlementCard(order);
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildZeroCommissionBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF142416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: greenAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Direct Farmer Settlement',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Zero middleman commissions deducted. 100% of produce price goes straight to your wallet.',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double available, double inTransit, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3820), Color(0xFF112215)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available for Withdrawal',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.flash_on_rounded, color: orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Instant Payout',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${available.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('In Transit (Pending Handover)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('₹${inTransit.toStringAsFixed(0)}', style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Lifetime Earnings', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(double balance, String farmerUid) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showWithdrawModal(context, balance, farmerUid),
            icon: const Icon(Icons.account_balance_rounded, size: 18),
            label: const Text('Withdraw to Bank / UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white70),
            onPressed: () => _showFarmPaymentQr(context),
            tooltip: 'Show Farm Pickup QR Code',
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? order['docId'] ?? '').toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    final status = (order['orderStatus'] ?? 'Placed').toString();
    final netEarnings = (order['netEarnings'] as num?)?.toDouble() ?? 0.0;
    final isSettled = status.toLowerCase() == 'delivered' || status.toLowerCase() == 'completed';

    String cropName = 'Farm Produce';
    double qty = 0;
    final items = order['items'] as List<dynamic>? ?? [];
    if (items.isNotEmpty && items.first is Map) {
      cropName = items.first['name']?.toString() ?? cropName;
      qty = (items.first['quantity'] as num?)?.toDouble() ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSettled ? green.withValues(alpha: 0.15) : orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSettled ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: isSettled ? greenAccent : orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$shortId • $cropName',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '+₹${netEarnings.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: isSettled ? greenAccent : orange, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      qty > 0 ? '${qty.toStringAsFixed(0)} kg • Direct Farm Sale' : 'Direct Farm Sale',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSettled ? green.withValues(alpha: 0.1) : orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSettled ? 'Settled (0% Comm)' : 'In Transit',
                        style: TextStyle(color: isSettled ? greenAccent : orange, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              'No Settlements Yet',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Produce earnings from completed buyer orders will automatically settle here with zero middleman commissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawModal(BuildContext context, double currentBalance, String farmerUid) {
    final upiController = TextEditingController(text: 'farmer.kovai@oksbi');
    final amountController = TextEditingController(text: currentBalance > 0 ? currentBalance.toStringAsFixed(0) : '2500');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1611),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: border, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Withdraw to Bank or UPI',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Direct transfer to your linked Indian bank account or UPI ID.',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 18),
            Text('Withdrawal Amount (₹)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: greenAccent, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 14),
            Text('UPI ID / VPA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: upiController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                prefixIcon: const Icon(Icons.payment_rounded, color: greenAccent, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessingWithdrawal
                    ? null
                    : () async {
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        if (amt <= 0) return;

                        setState(() => _isProcessingWithdrawal = true);
                        Navigator.pop(sheetContext);

                        // Save payout transaction
                        try {
                          await _firestore.collection('payouts').add({
                            'farmerId': farmerUid,
                            'amount': amt,
                            'method': 'UPI',
                            'target': upiController.text,
                            'status': 'Processed',
                            'settlementType': 'Instant Direct Payout',
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        } catch (_) {}

                        setState(() => _isProcessingWithdrawal = false);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF142416),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: greenAccent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Payout of ₹${amt.toStringAsFixed(0)} initiated via UPI!',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Confirm Instant Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmPaymentQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1611),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: border)),
        title: Text(
          'Farm Gate Direct Pay QR',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 160),
            ),
            const SizedBox(height: 14),
            Text(
              'Show to Buyer for Branch A Direct Farm Pickup',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 6),
            const Text(
              'Zero delivery fee • Instant direct UPI transfer to your wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
