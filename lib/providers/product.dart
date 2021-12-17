import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.description,
    @required this.id,
    @required this.imageUrl,
    this.isFavorite = false,
    @required this.price,
    @required this.title,
  });

  void _setFavValue(bool newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  // optimistic upadating pattern
  Future<void> toggleIsFavorite(String token) async {
    var _params = {
      'auth': token,
    };
    final oldStatus = isFavorite;
    final url = Uri.https(
        'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
        '/products/$id.json',
        _params);

    _setFavValue(!isFavorite);

    final result =
        await http.patch(url, body: json.encode({'isFavorite': isFavorite}));

    if (result.statusCode >= 400) {
      _setFavValue(oldStatus);

      throw HttpException('Error in updating product.');
    }
  }
}
