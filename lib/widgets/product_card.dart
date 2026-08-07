import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  String getCropImage(String crop) {
    switch (crop.toLowerCase()) {
      case "tomato":
        return "assets/crops/tomato.png";
      case "onion":
        return "assets/crops/onion.png";
      case "potato":
        return "assets/crops/potato.png";
      case "carrot":
        return "assets/crops/carrot.png";
      case "chilli":
        return "assets/crops/chilli.png";
      default:
        return "assets/crops/default.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xff181818),
        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          ///==========================
          /// Header
          ///==========================

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              ClipRRect(
                borderRadius: BorderRadius.circular(18),

                child: Image.asset(
                  getCropImage(product.name),
                  width: 105,
height: 105,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Row(
  children: [

    Expanded(
      child: Text(
        product.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ),

    if (product.suggestedPrice != null)
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              Icons.auto_awesome,
              color: Colors.purple,
              size: 15,
            ),

            SizedBox(width: 5),

            Text(
              "AI",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

    PopupMenuButton<String>(
  tooltip: "More",

  offset: const Offset(0, 40),

  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),

  elevation: 8,

  color: const Color(0xff252525),

      onSelected: (value) async {

        switch (value) {

          case "active":
            await ProductService().updateAvailability(
              product.id,
              true,
            );
            break;

          case "sold":
            await ProductService().updateAvailability(
              product.id,
              false,
            );
            break;

          case "delete":
            await ProductService().deleteProduct(
              product.id,
            );
            break;
        }
      },

      itemBuilder: (_) => [

        const PopupMenuItem(
          value: "active",
          child: Row(
            children: [
              Icon(Icons.check_circle,color: Colors.green),
              SizedBox(width: 10),
              Text("Mark Active"),
            ],
          ),
        ),

        const PopupMenuItem(
          value: "sold",
          child: Row(
            children: [
              Icon(Icons.sell,color: Colors.orange),
              SizedBox(width: 10),
              Text("Mark Sold Out"),
            ],
          ),
        ),

        const PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete,color: Colors.red),
              SizedBox(width: 10),
              Text("Delete Product"),
            ],
          ),
        ),
      ],
    ),
  ],
),


                    Text(
                      "₹${product.price.toStringAsFixed(0)} / ${product.unit}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 3),
                    Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [

    _buildChip(
      "${product.quantity} ${product.unit}",
      Colors.orange,
      Icons.inventory_2,
    ),

    _buildChip(
      product.quality,
      Colors.blue,
      Icons.workspace_premium,
    ),

    if (product.organic)
      _buildChip(
        "Organic",
        Colors.green,
        Icons.eco,
      ),
  ],
),

const SizedBox(height: 8),

Row(
  children: [

    const Icon(
      Icons.schedule,
      color: Colors.white54,
      size: 16,
    ),

    const SizedBox(width: 5),

    Text(
      _timeAgo(product.createdAt),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
      ),
    ),
  ],
),
const SizedBox(height: 6),

Align(
  alignment: Alignment.centerRight,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: product.available
          ? Colors.green.withOpacity(.15)
          : Colors.red.withOpacity(.15),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Text(
      product.available
          ? "🟢 Active Listing"
          : "🔴 Sold Out",
      style: TextStyle(
        color: product.available
            ? Colors.green
            : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

                  ],
                ), // End Column
              ), // End Expanded
            ], // End Row
          ),

        ], // End Column
      ),
    );
  }
Widget _buildChip(
  String text,
  Color color,
  IconData icon,
) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(.15),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        Icon(
          icon,
          color: color,
          size: 15,
        ),

        const SizedBox(width: 5),

        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 60) {
    return "${diff.inMinutes} min ago";
  }

  if (diff.inHours < 24) {
    return "${diff.inHours} hours ago";
  }

  return "${diff.inDays} days ago";
}
}
