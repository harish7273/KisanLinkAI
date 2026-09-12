import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/language_service.dart';
import '../screens/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  Widget _buildProductImage(ProductModel product) {
    const double size = 100;

    // 1. Check network URL in product.image
    if (product.image.isNotEmpty &&
        (product.image.startsWith('http://') || product.image.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          product.image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(product.name, size),
        ),
      );
    }

    // 1b. Check direct asset path in product.image
    if (product.image.isNotEmpty && product.image.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          product.image,
          width: size,
          height: size,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(product.name, size),
        ),
      );
    }

    // 2. Check local crop assets
    final localAssetPath = _getLocalCropAsset(product.name, product.category);
    if (localAssetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          localAssetPath,
          width: size,
          height: size,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(product.name, size),
        ),
      );
    }

    // 3. Elegant fallback placeholder
    return _buildFallbackImage(product.name, size);
  }

  String? _getLocalCropAsset(String cropName, String category) {
    final name = cropName.trim().toLowerCase();
    final cat = category.trim().toLowerCase();

    // Specific Crop Mappings
    if (name.contains("banana") || name.contains("nendran")) return "assets/crops/banana.png";
    if (name.contains("corn") || name.contains("maize")) return "assets/crops/corn.png";
    if (name.contains("cabbage")) return "assets/crops/cabbage.png";
    if (name.contains("brinjal") || name.contains("eggplant") || name.contains("aubergine")) return "assets/crops/brinjal.png";
    if (name.contains("mango") || name.contains("alphonso")) return "assets/crops/mango.png";
    if (name.contains("spinach") || name.contains("palak") || name.contains("keerai")) return "assets/crops/spinach.png";
    if (name.contains("onion")) return "assets/crops/onion.png";
    if (name.contains("potato")) return "assets/crops/potato.png";
    if (name.contains("carrot")) return "assets/crops/carrot.png";
    if (name.contains("chilli") || name.contains("chili")) return "assets/crops/chilli.png";
    if (name.contains("tomato")) return "assets/crops/tomato.png";

    // Category Level Fallbacks
    if (cat.contains("fruit") || name.contains("fruit") || name.contains("apple")) return "assets/products/fruits.png";
    if (cat.contains("grain") || cat.contains("cereal") || name.contains("paddy") || name.contains("rice") || name.contains("wheat")) return "assets/products/grains.png";
    if (cat.contains("dairy") || name.contains("milk") || name.contains("paneer") || name.contains("ghee")) return "assets/products/dairy.png";
    if (cat.contains("spice") || name.contains("turmeric") || name.contains("pepper") || name.contains("cardamom")) return "assets/products/spices.png";
    if (cat.contains("veg")) return "assets/products/vegetables.png";

    return null;
  }

  Widget _buildFallbackImage(String cropName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800.withOpacity(0.4),
            Colors.teal.shade900.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/kisan_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.spa_rounded,
                color: Colors.greenAccent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              cropName.isNotEmpty ? tr(cropName) : tr("Produce"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                  _buildProductImage(product),
                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(product.name),
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.purpleAccent.withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.purpleAccent,
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "AI",
                                      style: TextStyle(
                                        color: Colors.purpleAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: PopupMenuButton<String>(
                                tooltip: "Manage Listing",
                                offset: const Offset(0, 42),
                                elevation: 12,
                                color: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.12),
                                    width: 1,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case "active":
                                      await ProductService().updateAvailability(
                                        product.id,
                                        true,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Listing marked as Active 🟢"),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                      break;

                                    case "sold":
                                      await ProductService().updateAvailability(
                                        product.id,
                                        false,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Listing marked as Sold Out 🔴"),
                                            backgroundColor: Colors.orange,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                      break;

                                    case "delete":
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E1E1E),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: Colors.redAccent.withOpacity(0.3),
                                            ),
                                          ),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                              SizedBox(width: 10),
                                              Text("Delete Listing?", style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                          content: Text(
                                            "Are you sure you want to delete '${product.name}'? This action cannot be undone.",
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await ProductService().deleteProduct(product.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Listing deleted successfully"),
                                              backgroundColor: Colors.redAccent,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: "active",
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF00E676),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Mark Active",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: "sold",
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.sell_rounded,
                                            color: Color(0xFFFFB300),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Mark Sold Out",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(height: 1),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Delete Listing",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "₹${product.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              " / ${product.unit}",
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (product.suggestedPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                "(AI: ₹${product.suggestedPrice!.toStringAsFixed(0)})",
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildChip(
                              "${product.quantity} ${product.unit}",
                              Colors.orangeAccent,
                              Icons.inventory_2_outlined,
                            ),
                            _buildChip(
                              product.quality,
                              Colors.lightBlueAccent,
                              Icons.workspace_premium_outlined,
                            ),
                            if (product.organic)
                              _buildChip(
                                "Organic",
                                Colors.greenAccent,
                                Icons.eco_outlined,
                              ),
                          ],
                        ),

                        if (product.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.white38,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeAgo(product.createdAt),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (product.location.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white38,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        product.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.available
                                    ? Colors.green.withOpacity(.15)
                                    : Colors.red.withOpacity(.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: product.available
                                      ? Colors.greenAccent.withOpacity(0.3)
                                      : Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                product.available ? "🟢 Active" : "🔴 Sold Out",
                                style: TextStyle(
                                  color: product.available
                                      ? const Color(0xFF00E676)
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
