import '../models/product_model.dart';

List<ProductModel> products = [
  ProductModel(
    id: "1",
    farmerId: "farmer001",
    farmerName: "Ramesh",
    name: "Organic Mango",
    category: "Fruit",
    price: 120,
    quantity: 100,
    unit: "kg",
    location: "Salem",
    image: "🥭",
    description: "Fresh Organic Mango",
    available: true,
    createdAt: DateTime.now(),
  ),

  ProductModel(
    id: "2",
    farmerId: "farmer002",
    farmerName: "Kumar",
    name: "Fresh Tomato",
    category: "Vegetable",
    price: 28,
    quantity: 80,
    unit: "kg",
    location: "Erode",
    image: "🍅",
    description: "Farm Fresh Tomato",
    available: true,
    createdAt: DateTime.now(),
  ),
];