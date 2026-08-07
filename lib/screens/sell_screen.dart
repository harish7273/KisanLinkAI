import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';


class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {

  final ProductService _productService = ProductService();

final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),

      appBar: AppBar(
        backgroundColor: const Color(0xff0B0B0B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "My Products",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Row(
              children: [

                Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 18,
                ),

                SizedBox(width: 5),

                Text(
                  "Coimbatore, Tamil Nadu",
                  style: TextStyle(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ================= Stats =================

            StreamBuilder<List<ProductModel>>(
  stream: _productService.getFarmerProducts(user!.uid),

  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final products = snapshot.data!;

    final total = products.length;

    final active =
        products.where((p) => p.available).length;

    final sold =
        products.where((p) => !p.available).length;

    return Container(
  padding: const EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 12,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.08),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  ),

  child: Row(
    children: [

      Expanded(
        child: _buildStatItem(
          title: "Total Products",
          value: total.toString(),
          color: Colors.green,
          icon: Icons.inventory_2_outlined,
        ),
      ),

      Container(
        width: 1,
        height: 70,
        color: Colors.grey.shade300,
      ),

      Expanded(
        child: _buildStatItem(
          title: "Active",
          value: active.toString(),
          color: Colors.green,
          icon: Icons.check_circle_outline,
        ),
      ),

      Container(
        width: 1,
        height: 70,
        color: Colors.grey.shade300,
      ),

      Expanded(
        child: _buildStatItem(
          title: "Sold",
          value: sold.toString(),
          color: Colors.blue,
          icon: Icons.shopping_bag_outlined,
        ),
      ),
    ],
  ),
);
  },
),

            const SizedBox(height: 25),

            // ================= Add Product =================

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xff171717),
                borderRadius: BorderRadius.circular(22),
              ),

              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "List Your Produce",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Reach buyers directly using AI pricing.",
                          style: TextStyle(
                            color: Colors.white60,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AddProductScreen(),
                              ),
                            );

                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),

                          icon: const Icon(Icons.add),

                          label: const Text(
                            "Add New",
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 90,
                    height: 90,

                    decoration: BoxDecoration(
                      color:
                          Colors.green.withOpacity(.15),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.orange,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              "My Listings",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 30),

            StreamBuilder<List<ProductModel>>(
  stream: _productService.getProducts(),

  builder: (context, snapshot) {

    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData ||
        snapshot.data!.isEmpty) {

      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "No products yet.",
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    final products = snapshot.data!;

    return ListView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount: products.length,

      itemBuilder: (context, index) {

        final product = products[index];

        return ProductCard(
          product: product,
        );

      },
    );
  },
),
          ],
        ),
      ),
    );
  }
}

Widget _buildStatItem({
  required String title,
  required String value,
  required Color color,
  required IconData icon,
}) {
  return Column(
    children: [

      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.green.shade900,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      CircleAvatar(
        radius: 16,
        backgroundColor: color.withOpacity(.12),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    ],
  );
}