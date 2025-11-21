// productDetailMyStore.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_store_service.dart';

class Product {
  final String productName;
  final String productDescription;
  final String productType;
  final double productPrice;
  final int stockQuantity;
  final List<File> productImages;
  final List<String> productImageUrls;
  final String shippingMethod;
  final String shippingAvailability;
  final String? productId;

  Product({
    required this.productName,
    required this.productDescription,
    required this.productType,
    required this.productPrice,
    required this.stockQuantity,
    required this.productImages,
    required this.productImageUrls,
    required this.shippingMethod,
    required this.shippingAvailability,
    this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productDescription': productDescription,
      'productType': productType,
      'productPrice': productPrice,
      'stockQuantity': stockQuantity,
      'productImageUrls': productImageUrls,
      'shippingMethod': shippingMethod,
      'shippingAvailability': shippingAvailability,
      'productId': productId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['productName'] ?? '',
      productDescription: json['productDescription'] ?? '',
      productType: json['productType'] ?? '',
      productPrice: (json['productPrice'] ?? 0.0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      productImages: [],
      productImageUrls: List<String>.from(json['productImageUrls'] ?? []),
      shippingMethod: json['shippingMethod'] ?? '',
      shippingAvailability: json['shippingAvailability'] ?? '',
      productId: json['productId'],
    );
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'storeDescription': storeDescription,
      'storeLogoUrl': storeLogoUrl,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      storeName: json['storeName'] ?? '',
      storeDescription: json['storeDescription'] ?? '',
      storeLogo: null,
      storeLogoUrl: json['storeLogoUrl'],
      ownerName: json['ownerName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class ProductManager {
  List<Product> products = [];
  StoreData? storeData;
  bool isStoreCreated = false;
  bool isStoreDeactivated = false;
  DateTime? deactivatedUntil;

  int get productCount => products.length;

  Future<void> initializeStore() async {
    try {
      print('Initializing store from Firebase...');
      storeData = await FirebaseStoreService.getStore();
      isStoreCreated = storeData != null;

      if (isStoreCreated) {
        print('Store loaded: ${storeData!.storeName}');
        await _checkStoreStatus();
      } else {
        print('No store found for current user');
      }
    } catch (e) {
      print('Error initializing store: $e');
      isStoreCreated = false;
    }
  }

  Future<void> _checkStoreStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final storeDoc =
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(userId)
              .get();

      if (storeDoc.exists) {
        final data = storeDoc.data()!;
        final status = data['status'] ?? 'active';
        isStoreDeactivated = status == 'deactivated';

        if (isStoreDeactivated && data['deactivatedUntil'] != null) {
          deactivatedUntil = (data['deactivatedUntil'] as Timestamp).toDate();

          if (deactivatedUntil!.isBefore(DateTime.now())) {
            await reactivateStore();
            isStoreDeactivated = false;
            deactivatedUntil = null;
          }
        }
      }
    } catch (e) {
      print('Error checking store status: $e');
    }
  }

  Future<void> loadProducts() async {
    try {
      print('Loading products from Firebase...');
      final loadedProducts = await FirebaseStoreService.getProducts();
      products = loadedProducts;
      print('Loaded ${products.length} products from Firebase');
    } catch (e) {
      print('Error loading products: $e');
      products = [];
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      print('Adding product to Firebase: ${product.productName}');
      final success = await FirebaseStoreService.addProduct(product);

      if (success) {
        await loadProducts();
        print('Product added successfully and list refreshed');
        return true;
      }

      print('Failed to add product to Firebase');
      return false;
    } catch (e) {
      print('Error in addProduct: $e');
      return false;
    }
  }

  Future<bool> updateProduct(int index, Product updatedProduct) async {
    if (index < 0 || index >= products.length) return false;

    try {
      final productId = products[index].productId;

      if (productId == null || productId.isEmpty) {
        print('Error: Product ID is missing for product at index $index');
        return false;
      }

      print('Updating product with ID: $productId');

      final success = await FirebaseStoreService.updateProduct(
        productId,
        updatedProduct,
      );

      if (success) {
        await loadProducts();
        print('Product updated successfully and list refreshed');
        return true;
      }

      print('Failed to update product in Firebase');
      return false;
    } catch (e) {
      print('Error in updateProduct: $e');
      return false;
    }
  }

  // ============ NEW METHOD: Remove product locally (instant, no Firebase call) ============
  /// Removes product from local list only - for instant UI update
  /// Use this for optimistic UI updates, then call deleteProductInBackground separately
  void removeProductLocally(int index) {
    if (index >= 0 && index < products.length) {
      final productName = products[index].productName;
      products.removeAt(index);
      print('Product removed locally: $productName');
    }
  }

  // ============ NEW METHOD: Delete from Firebase in background (no await needed) ============
  /// Deletes product from Firebase without blocking UI
  /// Returns Future but you don't need to await it
  Future<bool> deleteProductInBackground(String productId) async {
    try {
      print('Deleting product from Firebase in background: $productId');
      final success = await FirebaseStoreService.deleteProduct(productId);
      if (success) {
        print('Product deleted from Firebase successfully: $productId');
      } else {
        print('Failed to delete product from Firebase: $productId');
      }
      return success;
    } catch (e) {
      print('Error deleting product in background: $e');
      return false;
    }
  }

  // Old method - kept for backward compatibility but consider using the new methods above
  Future<bool> removeProduct(int index) async {
    if (index < 0 || index >= products.length) return false;

    try {
      final productId = products[index].productId;
      if (productId == null) {
        print('Error: Product ID is null');
        return false;
      }

      print('Deleting product from Firebase: $productId');
      final success = await FirebaseStoreService.deleteProduct(productId);

      if (success) {
        // Don't reload from Firebase - just remove locally for instant UI
        products.removeAt(index);
        print('Product deleted successfully');
        return true;
      }

      print('Failed to delete product from Firebase');
      return false;
    } catch (e) {
      print('Error in removeProduct: $e');
      return false;
    }
  }

  Future<void> clearAllProducts() async {
    try {
      print('Clearing all products from Firebase...');
      final success = await FirebaseStoreService.clearAllProducts();

      if (success) {
        products.clear();
        print('All products cleared successfully');
      } else {
        print('Failed to clear products from Firebase');
      }
    } catch (e) {
      print('Error clearing products: $e');
    }
  }

  Future<void> deleteStore() async {
    try {
      print('Deleting store from Firebase...');
      final success = await FirebaseStoreService.deleteStore();

      if (success) {
        products.clear();
        storeData = null;
        isStoreCreated = false;
        print('Store deleted successfully');
      } else {
        print('Failed to delete store from Firebase');
      }
    } catch (e) {
      print('Error deleting store: $e');
    }
  }

  Future<void> deactivateStore(DateTime until) async {
    try {
      print('Deactivating store until $until...');
      final success = await FirebaseStoreService.deactivateStore(until);

      if (success) {
        isStoreDeactivated = true;
        deactivatedUntil = until;
        print('Store deactivated successfully');
      } else {
        print('Failed to deactivate store');
      }
    } catch (e) {
      print('Error deactivating store: $e');
    }
  }

  Future<bool> reactivateStore() async {
    try {
      print('Reactivating store...');
      final success = await FirebaseStoreService.reactivateStore();

      if (success) {
        isStoreDeactivated = false;
        deactivatedUntil = null;
        print('Store reactivated successfully');
        return true;
      }

      print('Failed to reactivate store');
      return false;
    } catch (e) {
      print('Error reactivating store: $e');
      return false;
    }
  }

  Future<bool> createStore(StoreData storeData) async {
    try {
      print('Creating store in Firebase...');
      final success = await FirebaseStoreService.createStore(storeData);

      if (success) {
        this.storeData = storeData;
        isStoreCreated = true;
        print('Store created successfully: ${storeData.storeName}');
        return true;
      }

      print('Failed to create store in Firebase');
      return false;
    } catch (e) {
      print('Error in createStore: $e');
      return false;
    }
  }

  void updateStore(StoreData newStoreData) {
    storeData = newStoreData;
    FirebaseStoreService.updateStore(newStoreData);
    print('Store data updated: ${newStoreData.storeName}');
  }
}
