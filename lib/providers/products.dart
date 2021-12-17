import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  final String _authToken;
  final String _userId;

  Products(this._authToken, this._userId, this._items);

  //var _showFavoritesOnly = false;

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    // return a copy of the list
    return [..._items];
  }

  List<Product> get favoriteItems {
    print('inside get favoriteItems');
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoriteOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var _params;

    if (filterByUser) {
      _params = {
        'auth': _authToken,
        'orderBy': json.encode("creatorId"),
        'equalTo': json.encode(_userId),
      };
    } else {
      _params = {
        'auth': _authToken,
      };
    }

    var url = Uri.https(
        'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
        '/products.json',
        _params);
    try {
      final response = await http.get(url);
      final extracetdData = json.decode(response.body) as Map<String, dynamic>;

      if (extracetdData == null) {
        return;
      }

      url = Uri.https(
          'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
          '/userFavorites/$_userId.json',
          _params);

      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];

      extracetdData.forEach((prodId, prodData) {
        loadedProducts.add(
          Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'],
            imageUrl: prodData['imageUrl'],
            isFavorite:
                favoriteData == null ? false : favoriteData[prodId] ?? false,
          ),
        );
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProoduct(Product product) async {
    var _params = {
      'auth': _authToken,
    };

    final url = Uri.https(
        'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
        '/products.json',
        _params);
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': _userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    var _params = {
      'auth': _authToken,
    };

    final prodIdx = _items.indexWhere((prod) => prod.id == id);
    if (prodIdx >= 0) {
      final url = Uri.https(
          'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
          '/products/$id.json',
          _params);
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));
      _items[prodIdx] = newProduct;
      notifyListeners();
    }
  }

  // use of optimistic updating pattern
  Future<void> deleteProduct(String id) async {
    var _params = {
      'auth': _authToken,
    };

    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    // retain a reference to the product in memory
    var selectedProd = _items[prodIndex];
    final url = Uri.https(
        'flutter-myshop-72fc3-default-rtdb.europe-west1.firebasedatabase.app',
        '/products/$id.json',
        _params);

    _items.removeWhere((prod) => prod.id == id);
    notifyListeners();

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _items.insert(prodIndex, selectedProd);
      notifyListeners();

      throw HttpException('Could not delete product.');
    }

    // release the reference to the product in memory
    selectedProd = null;
  }
}
