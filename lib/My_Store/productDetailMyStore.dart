// productDetailMyStore.dart
import 'dart:io';
import 'firebase_store_service.dart';

// Product class
class Product {
  final String productName;
  final String productDescription;
  final String productType;
  final double productPrice;
  final int stockQuantity;
  final String shippingMethod;
  final String shippingAvailability;
  final List<File> productImages;
  final List<String> productImageUrls;
  final String? productId; // NEW: For Firebase document ID

  Product({
    required this.productName,
    required this.productDescription,
    required this.productType,
    required this.productPrice,
    required this.stockQuantity,
    required this.shippingMethod,
    required this.shippingAvailability,
    required this.productImages,
    this.productImageUrls = const [],
    this.productId, // NEW
  });
}

// StoreData class
class StoreData {
  final String storeName;
  final String storeDescription;
  final File? storeLogo;
  final String? storeLogoUrl;
  final String ownerName;
  final String phoneNumber;
  final String address;

  StoreData({
    required this.storeName,
    required this.storeDescription,
    this.storeLogo,
    this.storeLogoUrl,
    required this.ownerName,
    required this.phoneNumber,
    required this.address,
  });
}

// Updated Singleton class to work with Firebase
class ProductManager {
  // Private constructor
  ProductManager._internal();

  // Single instance
  static final ProductManager _instance = ProductManager._internal();

  // Factory constructor to return the same instance
  factory ProductManager() => _instance;

  // ===== STORE MANAGEMENT =====
  StoreData? _storeData;
  DateTime? _deactivatedUntil;

  // Check if store is created
  bool get isStoreCreated => _storeData != null;

  // Get store data
  StoreData? get storeData => _storeData;

  // Check if store is currently deactivated
  bool get isStoreDeactivated {
    if (_deactivatedUntil == null) return false;
    if (DateTime.now().isAfter(_deactivatedUntil!)) {
      _deactivatedUntil = null;
      return false;
    }
    return true;
  }

  // Get deactivation time
  DateTime? get deactivatedUntil => _deactivatedUntil;

  // Initialize store from Firebase
  Future<void> initializeStore() async {
    _storeData = await FirebaseStoreService.getStore();
    print('Store initialized from Firebase: ${_storeData?.storeName}');
  }

  // Create store
  Future<bool> createStore(StoreData storeData) async {
    final success = await FirebaseStoreService.createStore(storeData);
    if (success) {
      _storeData = storeData;
      print('Store created: ${storeData.storeName}');
    }
    return success;
  }

  // Update existing store information
  Future<bool> updateStore(StoreData storeData) async {
    final success = await FirebaseStoreService.updateStore(storeData);
    if (success) {
      _storeData = storeData;
      print('Store updated: ${storeData.storeName}');
    }
    return success;
  }

  // Delete store completely
  Future<bool> deleteStore() async {
    final success = await FirebaseStoreService.deleteStore();
    if (success) {
      _storeData = null;
      _products.clear();
      _deactivatedUntil = null;
      print('Store deleted from Firebase');
    }
    return success;
  }

  // Deactivate store temporarily
  Future<bool> deactivateStore(DateTime until) async {
    final success = await FirebaseStoreService.deactivateStore(until);
    if (success) {
      _deactivatedUntil = until;
      print('Store deactivated until: $_deactivatedUntil');
    }
    return success;
  }

  // Reactivate store manually
  Future<bool> reactivateStore() async {
    final success = await FirebaseStoreService.reactivateStore();
    if (success) {
      _deactivatedUntil = null;
      print('Store reactivated');
    }
    return success;
  }

  // Clear store (for testing purposes)
  void clearStore() {
    _storeData = null;
    _products.clear();
    _deactivatedUntil = null;
  }

  // ===== PRODUCT MANAGEMENT =====
  final List<Product> _products = [];

  // Get all products
  List<Product> get products => _products;

  // Get product count
  int get productCount => _products.length;

  // Load products from Firebase
  Future<void> loadProducts() async {
    _products.clear();
    final firebaseProducts = await FirebaseStoreService.getProducts();
    _products.addAll(firebaseProducts);
    print('Loaded ${_products.length} products from Firebase');
  }

  // Add a product
  Future<bool> addProduct(Product product) async {
    final success = await FirebaseStoreService.addProduct(product);
    if (success) {
      await loadProducts(); // Reload to get the complete data with Firebase IDs
      print('Product added: ${product.productName}');
      print('Total products: ${_products.length}');
    }
    return success;
  }

  // Remove a product
  Future<bool> removeProduct(int index) async {
    if (index >= 0 && index < _products.length) {
      final productId = _products[index].productId;
      if (productId != null) {
        final success = await FirebaseStoreService.deleteProduct(productId);
        if (success) {
          _products.removeAt(index);
          print('Product removed at index: $index');
          return true;
        }
      }
    }
    return false;
  }

  // Update a product
  Future<bool> updateProduct(int index, Product product) async {
    if (index >= 0 && index < _products.length) {
      final productId = _products[index].productId;
      if (productId != null) {
        final success = await FirebaseStoreService.updateProduct(
          productId,
          product,
        );
        if (success) {
          await loadProducts(); // Reload to get updated data
          print('Product updated: ${product.productName}');
          return true;
        }
      }
    }
    return false;
  }

  // Get product by index
  Product? getProduct(int index) {
    if (index >= 0 && index < _products.length) {
      return _products[index];
    }
    return null;
  }

  // Clear all products but keep store data
  Future<bool> clearAllProducts() async {
    final success = await FirebaseStoreService.clearAllProducts();
    if (success) {
      _products.clear();
      print('All products cleared from Firebase');
    }
    return success;
  }

  // Stream operations for real-time updates
  Stream<StoreData?> streamStore() {
    return FirebaseStoreService.streamStore();
  }

  Stream<List<Product>> streamProducts() {
    return FirebaseStoreService.streamProducts();
  }
}
