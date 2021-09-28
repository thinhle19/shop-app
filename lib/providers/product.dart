import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  void _setFavValue(bool val) {
    isFavorite = val;
    notifyListeners();
  }

  void toggleFavoriteStatus() async {
    // isFavorite ? isFavorite = false : isFavorite = true;
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = Uri.parse(
        "https://shop-app-980dd-default-rtdb.firebaseio.com/products/$id.json");
    try {
      final response = await http.patch(
        url,
        body: json.encode(
          {
            "isFavorite": isFavorite,
          },
        ),
      );
      if (response.statusCode >= 400) {
        _setFavValue(oldStatus);
      }
    } catch (error) {
      _setFavValue(oldStatus);
    }
  }
}
