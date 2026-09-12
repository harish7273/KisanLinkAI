import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  static const Color background = Color(0xFF080A09);
  static const Color cardColor = Color(0xFF141715);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color darkGreen = Color(0xFF102819);
  static const Color borderColor = Color(0xFF223326);

  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncTime();
  }

  Future<void> _loadSyncTime() async {
    final t = await OfflineSyncService.instance.getLastSyncTime();
    setState(() => _lastSyncTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A150D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/kisan_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.cloud_sync_rounded,
                color: primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Sync Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rural Low-Connectivity Engine',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: OfflineSyncService.instance.isOnlineNotifier,
        builder: (context, isOnline, _) {
          return ValueListenableBuilder<int>(
            valueListenable: OfflineSyncService.instance.pendingCountNotifier,
            builder: (context, pendingCount, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: OfflineSyncService.instance.isSyncingNotifier,
                builder: (context, isSyncing, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        _buildStatusCard(isOnline, pendingCount, isSyncing),

                        const SizedBox(height: 20),

                        // Actions (Sync Now / Enqueue Test)
                        _buildSyncActions(isOnline, isSyncing, pendingCount),

                        const SizedBox(height: 20),

                        // How Offline Mode Works info card
                        _buildExplainerCard(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isOnline, int pendingCount, bool isSyncing) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOnline ? primaryGreen.withOpacity(0.4) : Colors.amber.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? primaryGreen : Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'Online & Connected' : 'Offline Mode Active',
                    style: TextStyle(
                      color: isOnline ? primaryGreen : Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isOnline
                ? 'Cloud synchronization is live. Any newly recorded listings and quality scans are automatically mirrored to Firestore.'
                : 'No network detected. Your produce listings and scans are safely saved in local offline storage on your device.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const Divider(color: Color(0xFF223528), height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Sync Queue', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    '$pendingCount items',
                    style: TextStyle(
                      color: pendingCount > 0 ? Colors.amber : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Last Synced', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    _lastSyncTime != null ? 'Today Just Now' : 'Synced',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActions(bool isOnline, bool isSyncing, int pendingCount) {
    return Column(
      children: [
        // Offline Simulation Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF142018),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF263C2D)),
          ),
          child: Row(
            children: [
              const Icon(Icons.signal_cellular_connected_no_internet_4_bar_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulate Zero Connectivity', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('Test offline queue accumulation', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: OfflineSyncService.instance.isSimulatedOffline,
                activeColor: Colors.amber,
                onChanged: (val) {
                  setState(() {
                    OfflineSyncService.instance.toggleSimulatedOffline(val);
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              isSyncing ? 'Syncing Queue to Cloud...' : 'Sync Now with Cloud',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: isSyncing
                ? null
                : () async {
                    final success = await OfflineSyncService.instance.syncPendingQueue();
                    await _loadSyncTime();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF13361E),
                        content: Row(
                          children: [
                            Icon(success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: primaryGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                success
                                    ? 'All offline items synced with Firestore!'
                                    : 'No internet connection or queue empty.',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF283F2F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add_task_rounded, color: primaryGreen),
            label: const Text('Simulate Offline Produce Listing'),
            onPressed: () async {
              await OfflineSyncService.instance.enqueueOfflineItem(
                collection: 'products',
                data: {
                  'name': 'Local Field Tomato (Offline Draft)',
                  'price': 28.0,
                  'quantity': 400,
                  'location': 'Pollachi Village',
                  'available': true,
                },
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF13361E),
                  content: Text('Simulated produce saved to local offline storage!'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExplainerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'How KisanAI Rural Offline Mode Works',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1. Zero Signal Protection: If you are at a farm with zero cellular bars, you can still record harvests, scan produce quality, and place auction bids.\n\n'
            '2. Tamper-Proof Local Cache: Items are stamped with a local cryptographic hash and queued in private phone storage.\n\n'
            '3. Auto-Flush on Reconnection: The moment you reach the highway or connect to village Wi-Fi, KisanAI quietly uploads all entries to the national buyer marketplace.',
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
