// firebase_store_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'productDetailMyStore.dart';

class FirebaseStoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cloudinary configuration
  static const String cloudName = "dihvyw4n4";
  static const String uploadPreset = "navarasa";

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Upload image to Cloudinary
  static Future<String?> _uploadToCloudinary(
    File imageFile,
    String folder,
  ) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    try {
      final request =
          http.MultipartRequest("POST", url)
            ..fields["upload_preset"] = uploadPreset
            ..fields["folder"] = folder
            ..files.add(
              await http.MultipartFile.fromPath("file", imageFile.path),
            );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        return jsonData["secure_url"];
      } else {
        print("Cloudinary upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary error: $e");
      return null;
    }
  }

  // ============ STORE OPERATIONS ============

  /// Create a new store
  static Future<bool> createStore(StoreData storeData) async {
    if (currentUserId == null) return false;

    try {
      // Upload logo to Cloudinary if exists
      String? logoUrl;
      if (storeData.storeLogo != null) {
        logoUrl = await _uploadToCloudinary(
          storeData.storeLogo!,
          "Store/Logos",
        );
        if (logoUrl == null) return false;
      }

      // Create store document
      await _firestore.collection('stores').doc(currentUserId).set({
        'userId': currentUserId,
        'storeName': storeData.storeName,
        'storeDescription': storeData.storeDescription,
        'storeLogoUrl': logoUrl,
        'ownerName': storeData.ownerName,
        'phoneNumber': storeData.phoneNumber,
        'address': storeData.address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'deactivatedUntil': null,
      });

      print('Store created successfully in Firestore');
      return true;
    } catch (e) {
      print('Error creating store: $e');
      return false;
    }
  }

  /// Get store data
  static Future<StoreData?> getStore() async {
    if (currentUserId == null) return null;

    try {
      final doc =
          await _firestore.collection('stores').doc(currentUserId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return StoreData(
        storeName: data['storeName'] ?? '',
        storeDescription: data['storeDescription'] ?? '',
        storeLogo: null, // We'll use URL instead
        storeLogoUrl: data['storeLogoUrl'],
        ownerName: data['ownerName'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        address: data['address'] ?? '',
      );
    } catch (e) {
      print('Error getting store: $e');
      return null;
    }
  }

  /// Update store
  static Future<bool> updateStore(StoreData storeData) async {
    if (currentUserId == null) return false;

    try {
      Map<String, dynamic> updateData = {
        'storeName': storeData.storeName,
        'storeDescription': storeData.storeDescription,
        'ownerName': storeData.ownerName,
        'phoneNumber': storeData.phoneNumber,
        'address': storeData.address,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Upload new logo if changed
      if (storeData.storeLogo != null) {
        final logoUrl = await _uploadToCloudinary(
          storeData.storeLogo!,
          "Store/Logos",
        );
        if (logoUrl != null) {
          updateData['storeLogoUrl'] = logoUrl;
        }
      }

      await _firestore
          .collection('stores')
          .doc(currentUserId)
          .update(updateData);
      print('Store updated successfully');
      return true;
    } catch (e) {
      print('Error updating store: $e');
      return false;
    }
  }

  /// Check if store exists
  static Future<bool> storeExists() async {
    if (currentUserId == null) return false;

    try {
      final doc =
          await _firestore.collection('stores').doc(currentUserId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking store: $e');
      return false;
    }
  }

  /// Delete store
  static Future<bool> deleteStore() async {
    if (currentUserId == null) return false;

    try {
      // Delete all products first
      final productsSnapshot =
          await _firestore
              .collection('stores')
              .doc(currentUserId)
              .collection('products')
              .get();

      for (var doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete store
      await _firestore.collection('stores').doc(currentUserId).delete();
      print('Store deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting store: $e');
      return false;
    }
  }

  /// Deactivate store
  static Future<bool> deactivateStore(DateTime until) async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('stores').doc(currentUserId).update({
        'status': 'deactivated',
        'deactivatedUntil': Timestamp.fromDate(until),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error deactivating store: $e');
      return false;
    }
  }

  /// Reactivate store
  static Future<bool> reactivateStore() async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('stores').doc(currentUserId).update({
        'status': 'active',
        'deactivatedUntil': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error reactivating store: $e');
      return false;
    }
  }

  // ============ PRODUCT OPERATIONS ============

  /// Add product
  /// Add product
  static Future<bool> addProduct(Product product) async {
    if (currentUserId == null) return false;

    try {
      // Use the image URLs that were already uploaded in AddProduct.dart
      List<String> imageUrls = product.productImageUrls;

      // Only upload new images if productImages is not empty (fallback)
      if (product.productImages.isNotEmpty) {
        for (var imageFile in product.productImages) {
          final url = await _uploadToCloudinary(imageFile, "Store/Products");
          if (url != null) imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        print('Failed to upload product images - no image URLs provided');
        return false;
      }

      // Create product document
      final productRef =
          _firestore
              .collection('stores')
              .doc(currentUserId)
              .collection('products')
              .doc();

      await productRef.set({
        'productId': productRef.id,
        'userId': currentUserId,
        'productName': product.productName,
        'productDescription': product.productDescription,
        'productType': product.productType,
        'productPrice': product.productPrice,
        'stockQuantity': product.stockQuantity,
        'shippingMethod': product.shippingMethod,
        'shippingAvailability': product.shippingAvailability,
        'productImageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      print('Product added successfully');
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  /// Get all products
  /// Get all products
  static Future<List<Product>> getProducts() async {
    if (currentUserId == null) return [];

    try {
      final snapshot =
          await _firestore
              .collection('stores')
              .doc(currentUserId)
              .collection('products')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          productName: data['productName'] ?? '',
          productDescription: data['productDescription'] ?? '',
          productType: data['productType'] ?? '',
          productPrice: (data['productPrice'] ?? 0.0).toDouble(),
          stockQuantity: data['stockQuantity'] ?? 0,
          shippingMethod: data['shippingMethod'] ?? '',
          shippingAvailability: data['shippingAvailability'] ?? '',
          productImages: [], // Empty as we use URLs now
          productImageUrls: List<String>.from(data['productImageUrls'] ?? []),
          productId: doc.id, // ADD THIS LINE - Very important!
        );
      }).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  /// Update product
  /// Update product
  static Future<bool> updateProduct(String productId, Product product) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: No user logged in');
        return false;
      }

      if (productId.isEmpty) {
        print('Error: Product ID is empty');
        return false;
      }

      print('Updating product $productId in Firebase...');

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(userId)
          .collection('products')
          .doc(productId)
          .update({
            'productName': product.productName,
            'productDescription': product.productDescription,
            'productType': product.productType,
            'productPrice': product.productPrice,
            'stockQuantity': product.stockQuantity,
            'shippingMethod': product.shippingMethod,
            'shippingAvailability': product.shippingAvailability,
            'productImageUrls': product.productImageUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Product updated successfully in Firebase: $productId');
      return true;
    } catch (e) {
      print('Error updating product in Firebase: $e');
      return false;
    }
  }

  /// Delete product
  static Future<bool> deleteProduct(String productId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('stores')
          .doc(currentUserId)
          .collection('products')
          .doc(productId)
          .delete();

      print('Product deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  /// Clear all products
  static Future<bool> clearAllProducts() async {
    if (currentUserId == null) return false;

    try {
      final snapshot =
          await _firestore
              .collection('stores')
              .doc(currentUserId)
              .collection('products')
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('All products cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing products: $e');
      return false;
    }
  }

  /// Get product count
  static Future<int> getProductCount() async {
    if (currentUserId == null) return 0;

    try {
      final snapshot =
          await _firestore
              .collection('stores')
              .doc(currentUserId)
              .collection('products')
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }

  // ============ STREAM OPERATIONS ============

  /// Stream store data
  static Stream<StoreData?> streamStore() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore.collection('stores').doc(currentUserId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;

      final data = doc.data()!;
      return StoreData(
        storeName: data['storeName'] ?? '',
        storeDescription: data['storeDescription'] ?? '',
        storeLogo: null,
        storeLogoUrl: data['storeLogoUrl'],
        ownerName: data['ownerName'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        address: data['address'] ?? '',
      );
    });
  }

  /// Stream products
  static Stream<List<Product>> streamProducts() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('stores')
        .doc(currentUserId)
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Product(
              productName: data['productName'] ?? '',
              productDescription: data['productDescription'] ?? '',
              productType: data['productType'] ?? '',
              productPrice: (data['productPrice'] ?? 0.0).toDouble(),
              stockQuantity: data['stockQuantity'] ?? 0,
              shippingMethod: data['shippingMethod'] ?? '',
              shippingAvailability: data['shippingAvailability'] ?? '',
              productImages: [],
              productImageUrls: List<String>.from(
                data['productImageUrls'] ?? [],
              ),
            );
          }).toList();
        });
  }
}
