import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._internal();

  OfflineSyncService._internal() {
    _init();
  }

  static const String _queueKey = 'kisan_offline_queue_items';
  static const String _lastSyncKey = 'kisan_last_sync_timestamp';

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> _init() async {
    // Check initial connectivity
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }

    // Listen to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
      if (isOnlineNotifier.value) {
        // Auto-sync when back online
        syncPendingQueue();
      }
    });

    // Load initial queue count
    await refreshQueueCount();
  }

  bool isSimulatedOffline = false;

  void toggleSimulatedOffline(bool offline) {
    isSimulatedOffline = offline;
    if (offline) {
      isOnlineNotifier.value = false;
    } else {
      isOnlineNotifier.value = true;
      syncPendingQueue();
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (isSimulatedOffline) return;
    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);
    isOnlineNotifier.value = hasConnection;
  }

  Future<int> refreshQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    pendingCountNotifier.value = raw.length;
    return raw.length;
  }

  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  /// Queues an item when the user is offline or has low connectivity
  Future<void> enqueueOfflineItem({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];

    final item = {
      'id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
      'collection': collection,
      'data': data,
      'queuedAt': DateTime.now().toIso8601String(),
    };

    queue.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, queue);
    await refreshQueueCount();

    debugPrint('📦 [OfflineSync] Enqueued offline item in $collection. Total pending: ${queue.length}');

    // If we happen to be online and not simulated offline, immediately flush
    if (isOnlineNotifier.value && !isSimulatedOffline) {
      syncPendingQueue();
    }
  }

  /// Flushes all pending items to Cloud Firestore
  Future<bool> syncPendingQueue() async {
    if (isSyncingNotifier.value) return false;
    if (isSimulatedOffline) return false;
    isSyncingNotifier.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];

      if (queue.isEmpty) {
        isSyncingNotifier.value = false;
        return true;
      }

      debugPrint('🔄 [OfflineSync] Syncing ${queue.length} items to Firestore...');

      final List<String> failedItems = [];
      final firestore = FirebaseFirestore.instance;

      for (final rawItem in queue) {
        try {
          final item = jsonDecode(rawItem) as Map<String, dynamic>;
          final collection = item['collection'] as String;
          final data = Map<String, dynamic>.from(item['data'] as Map);

          // Add server timestamp
          data['syncedAt'] = FieldValue.serverTimestamp();
          data['offlineCreated'] = true;

          await firestore.collection(collection).add(data);
        } catch (e) {
          debugPrint('⚠️ [OfflineSync] Item sync failed: $e');
          failedItems.add(rawItem);
        }
      }

      await prefs.setStringList(_queueKey, failedItems);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      await refreshQueueCount();

      debugPrint('✅ [OfflineSync] Sync complete. Remaining: ${failedItems.length}');
      isSyncingNotifier.value = false;
      return failedItems.isEmpty;
    } catch (e) {
      debugPrint('❌ [OfflineSync] Sync error: $e');
      isSyncingNotifier.value = false;
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
