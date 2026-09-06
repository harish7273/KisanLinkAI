import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET UNIQUE CHAT ID
  // ============================================================

  String getChatId({
    required String buyerId,
    required String farmerId,
    required String productId,
  }) {
    return '${buyerId}_${farmerId}_$productId';
  }

  // ============================================================
  // CREATE CHAT
  // ============================================================

  Future<void> createChat({
    required String chatId,
    required String buyerId,
    required String farmerId,
    required String farmerName,
    required String productId,
    required String productName,
    double? productPrice,
    String? productUnit,
    String? buyerName,
  }) async {
    final chatRef =
        _firestore.collection('chats').doc(chatId);

    final existingChat =
        await chatRef.get();

    if (existingChat.exists) {
      return;
    }

    await chatRef.set({
      'buyerId': buyerId,
      'buyerName': buyerName ?? 'Buyer',

      'farmerId': farmerId,
      'farmerName': farmerName,

      'productId': productId,
      'productName': productName,

      'productPrice': productPrice,
      'productUnit': productUnit,

      'lastMessage': '',
      'lastSenderId': '',

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    final text = message.trim();

    if (text.isEmpty) {
      return;
    }

    final chatRef =
        _firestore.collection('chats').doc(chatId);

    final messageRef =
        chatRef
            .collection('messages')
            .doc();

    // Add message
    await messageRef.set({
      'senderId': senderId,
      'senderName': senderName,
      'message': text,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    // Update chat preview
    await chatRef.update({
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // REAL-TIME MESSAGES
  //
  // No orderBy here.
  // This avoids Firestore index problems.
  // We sort locally in the chat screen.
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      messagesStream(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots();
  }

  // ============================================================
  // BUYER CHAT LIST
  //
  // No orderBy -> no composite index required.
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      buyerChatsStream(
    String buyerId,
  ) {
    return _firestore
        .collection('chats')
        .where(
          'buyerId',
          isEqualTo: buyerId,
        )
        .snapshots();
  }

  // ============================================================
  // FARMER CHAT LIST
  //
  // No orderBy -> fixes FAILED_PRECONDITION.
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      farmerChatsStream(
    String farmerId,
  ) {
    return _firestore
        .collection('chats')
        .where(
          'farmerId',
          isEqualTo: farmerId,
        )
        .snapshots();
  }

  // ============================================================
  // GET SINGLE CHAT
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getChat(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .get();
  }

  // ============================================================
  // DELETE CHAT
  // ============================================================

  Future<void> deleteChat(
    String chatId,
  ) async {
    final chatRef =
        _firestore
            .collection('chats')
            .doc(chatId);

    final messages =
        await chatRef
            .collection('messages')
            .get();

    final batch =
        _firestore.batch();

    for (final message
        in messages.docs) {
      batch.delete(
        message.reference,
      );
    }

    batch.delete(chatRef);

    await batch.commit();
  }
}