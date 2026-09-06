import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final CollectionReference products =
      FirebaseFirestore.instance.collection("products");

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> addProduct(ProductModel product) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        "No farmer is currently logged in.",
      );
    }

    // Always use the currently authenticated Firebase UID.
    final String farmerId = user.uid;

    debugPrint(
      "========================================",
    );
    debugPrint(
      "🌾 PRODUCT SERVICE - ADD PRODUCT",
    );
    debugPrint(
      "Firebase Auth UID: $farmerId",
    );
    debugPrint(
      "Product farmerId received: ${product.farmerId}",
    );
    debugPrint(
      "Product name: ${product.name}",
    );
    debugPrint(
      "========================================",
    );

    // Create a new Firestore document.
    final DocumentReference doc =
        products.doc();

    // Keep ALL fields from ProductModel.
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      product.toMap(),
    );

    // ==========================================================
    // FORCE CORRECT FARMER INFORMATION
    // ==========================================================

    data["id"] = doc.id;

    data["farmerId"] = farmerId;

    data["farmerName"] =
        product.farmerName.isNotEmpty
            ? product.farmerName
            : (user.displayName ?? "Farmer");

    // ==========================================================
    // CREATED AT
    // ==========================================================

    data["createdAt"] =
        data["createdAt"] ??
        Timestamp.now();

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      "📦 FINAL FIRESTORE FARMER ID: "
      "${data["farmerId"]}",
    );

    debugPrint(
      "📦 FIRESTORE PRODUCT ID: "
      "${doc.id}",
    );

    // Safety check.
    if (data["farmerId"] != user.uid) {
      throw Exception(
        "Farmer UID mismatch before Firestore save.",
      );
    }

    // ==========================================================
    // SAVE TO FIRESTORE
    // ==========================================================

    await doc.set(data);

    debugPrint(
      "✅ PRODUCT SAVED SUCCESSFULLY",
    );

    debugPrint(
      "Product ID: ${doc.id}",
    );

    debugPrint(
      "Farmer ID: ${data["farmerId"]}",
    );

    debugPrint(
      "========================================",
    );
  }

  // ============================================================
  // GET ALL PRODUCTS
  // ============================================================

  Stream<List<ProductModel>> getProducts() {
    return products
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                data["id"] = doc.id;

                return ProductModel.fromMap(
                  data,
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // GET FARMER PRODUCTS
  // ============================================================

  Stream<List<ProductModel>> getFarmerProducts(
    String farmerId,
  ) {
    return products
        .where(
          "farmerId",
          isEqualTo: farmerId,
        )
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                data["id"] = doc.id;

                return ProductModel.fromMap(
                  data,
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // GET CURRENT FARMER PRODUCTS
  // ============================================================

  Stream<List<ProductModel>>
      getCurrentFarmerProducts() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <ProductModel>[],
      );
    }

    debugPrint(
      "🌾 Loading products for farmer: "
      "${user.uid}",
    );

    return getFarmerProducts(
      user.uid,
    );
  }

  // ============================================================
  // GET SINGLE PRODUCT
  // ============================================================

  Future<ProductModel?> getProduct(
    String productId,
  ) async {
    final DocumentSnapshot snapshot =
        await products.doc(productId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    data["id"] = snapshot.id;

    return ProductModel.fromMap(
      data,
    );
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================

  Future<void> updateProduct(
    ProductModel product,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        "No farmer is currently logged in.",
      );
    }

    final DocumentReference doc =
        products.doc(product.id);

    final DocumentSnapshot snapshot =
        await doc.get();

    if (!snapshot.exists) {
      throw Exception(
        "Product does not exist.",
      );
    }

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final String? existingFarmerId =
        data["farmerId"]?.toString();

    if (existingFarmerId != user.uid) {
      throw Exception(
        "You are not authorized to update this product.",
      );
    }

    final Map<String, dynamic> updatedData =
        Map<String, dynamic>.from(
      product.toMap(),
    );

    updatedData["id"] =
        product.id;

    updatedData["farmerId"] =
        user.uid;

    updatedData["updatedAt"] =
        FieldValue.serverTimestamp();

    await doc.update(
      updatedData,
    );

    debugPrint(
      "✅ PRODUCT UPDATED: ${product.id}",
    );
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> deleteProduct(
    String id,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        "No farmer is currently logged in.",
      );
    }

    final DocumentReference doc =
        products.doc(id);

    final DocumentSnapshot snapshot =
        await doc.get();

    if (!snapshot.exists) {
      throw Exception(
        "Product does not exist.",
      );
    }

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final String? farmerId =
        data["farmerId"]?.toString();

    if (farmerId != user.uid) {
      throw Exception(
        "You are not authorized to delete this product.",
      );
    }

    await doc.delete();

    debugPrint(
      "🗑️ PRODUCT DELETED: $id",
    );
  }

  // ============================================================
  // UPDATE AVAILABILITY
  // ============================================================

  Future<void> updateAvailability(
    String id,
    bool available,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        "No farmer is currently logged in.",
      );
    }

    final DocumentReference doc =
        products.doc(id);

    final DocumentSnapshot snapshot =
        await doc.get();

    if (!snapshot.exists) {
      throw Exception(
        "Product does not exist.",
      );
    }

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final String? farmerId =
        data["farmerId"]?.toString();

    if (farmerId != user.uid) {
      throw Exception(
        "You are not authorized to change this product.",
      );
    }

    await doc.update({
      "available": available,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    debugPrint(
      "✅ PRODUCT AVAILABILITY UPDATED: "
      "$id → $available",
    );
  }

  // ============================================================
  // UPDATE ONLY PRICE
  // ============================================================

  Future<void> updatePrice(
    String id,
    double price,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        "No farmer is currently logged in.",
      );
    }

    final DocumentReference doc =
        products.doc(id);

    final DocumentSnapshot snapshot =
        await doc.get();

    if (!snapshot.exists) {
      throw Exception(
        "Product does not exist.",
      );
    }

    final data =
        snapshot.data()
            as Map<String, dynamic>;

    final String? farmerId =
        data["farmerId"]?.toString();

    if (farmerId != user.uid) {
      throw Exception(
        "You are not authorized to change this product.",
      );
    }

    await doc.update({
      "price": price,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    debugPrint(
      "✅ PRODUCT PRICE UPDATED: "
      "$id → ₹$price",
    );
  }
}