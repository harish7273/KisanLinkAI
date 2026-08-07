import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final CollectionReference products =
      FirebaseFirestore.instance.collection("products");

  // Add Product
  Future<void> addProduct(ProductModel product) async {
  final doc = products.doc();

  final newProduct = ProductModel(
    id: doc.id,
    farmerId: product.farmerId,
    farmerName: product.farmerName,
    name: product.name,
    category: product.category,
    price: product.price,
    quantity: product.quantity,
    unit: product.unit,
    location: product.location,
    image: product.image,
    description: product.description,
    available: product.available,
    createdAt: product.createdAt,
  );

  await doc.set(newProduct.toMap());
}

  // Get All Products
  Stream<List<ProductModel>> getProducts() {
    return products
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ProductModel.fromMap(
                doc.data() as Map<String, dynamic>,
              );
            }).toList());
  }

  // Get Farmer Products
  Stream<List<ProductModel>> getFarmerProducts(
      String farmerId) {
    return products
        .where("farmerId", isEqualTo: farmerId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ProductModel.fromMap(
                doc.data() as Map<String, dynamic>,
              );
            }).toList());
  }

  // Update Product
  Future<void> updateProduct(
      ProductModel product) async {
    await products.doc(product.id).update(
          product.toMap(),
        );
  }

  // Delete Product
  Future<void> deleteProduct(String id) async {
    await products.doc(id).delete();
  }

  // Mark Available / Sold Out
  Future<void> updateAvailability(
      String id,
      bool available) async {
    await products.doc(id).update({
      "available": available,
    });
  }
}