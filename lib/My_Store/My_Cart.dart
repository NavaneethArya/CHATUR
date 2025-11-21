// My_Cart.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatur_frontend/My_Store/StoreDetailView.dart';
import 'package:chatur_frontend/My_Store/productDetailMyStore.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Real-time listener
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  // Track which stores are expanded
  Map<String, bool> _expandedStores = {};

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  Future<void> _removeFromCart(String cartItemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Item removed from cart'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> cartData) {
    final product = Product(
      productName: cartData['productName'] ?? '',
      productDescription: cartData['productDescription'] ?? '',
      productType: cartData['productType'] ?? '',
      productPrice: (cartData['productPrice'] ?? 0.0).toDouble(),
      stockQuantity: cartData['stockQuantity'] ?? 0,
      shippingMethod: cartData['shippingMethod'] ?? '',
      shippingAvailability: cartData['shippingAvailability'] ?? '',
      productImages: [],
      productImageUrls: List<String>.from(cartData['productImageUrls'] ?? []),
    );

    final store = StoreData(
      storeName: cartData['storeName'] ?? '',
      storeDescription: cartData['storeDescription'] ?? '',
      storeLogo: null,
      storeLogoUrl: cartData['storeLogoUrl'],
      ownerName: cartData['ownerName'] ?? '',
      phoneNumber: cartData['phoneNumber'] ?? '',
      address: cartData['address'] ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StoreDetailView(product: product, storeData: store),
      ),
    );
  }

  // Group cart items by store
  Map<String, List<Map<String, dynamic>>> _groupByStore(
    List<QueryDocumentSnapshot> cartItems,
  ) {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var item in cartItems) {
      final data = item.data() as Map<String, dynamic>;
      final storeName = data['storeName'] ?? 'Unknown Store';

      if (!groupedItems.containsKey(storeName)) {
        groupedItems[storeName] = [];
        // Initialize as expanded by default
        if (!_expandedStores.containsKey(storeName)) {
          _expandedStores[storeName] = true;
        }
      }

      groupedItems[storeName]!.add({...data, 'cartItemId': item.id});
    }

    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple,
                Colors.deepPurple[300]!,
                Colors.purple[200]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.shopping_cart, size: 28),
            SizedBox(width: 10),
            Text(
              'My Cart',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
      ),
      body:
          userId == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'Please login to view cart',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('users')
                        .doc(userId)
                        .collection('cart')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Something went wrong!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Your Cart is Empty',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Start adding products to your cart!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final cartItems = snapshot.data!.docs;
                  final groupedItems = _groupByStore(cartItems);

                  double totalPrice = 0;
                  for (var item in cartItems) {
                    final data = item.data() as Map<String, dynamic>;
                    final price = (data['productPrice'] ?? 0.0).toDouble();
                    totalPrice += price;
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: groupedItems.length,
                          itemBuilder: (context, index) {
                            final storeName = groupedItems.keys.elementAt(
                              index,
                            );
                            final storeProducts = groupedItems[storeName]!;
                            final isExpanded =
                                _expandedStores[storeName] ?? true;

                            // Calculate store total
                            double storeTotal = 0;
                            for (var product in storeProducts) {
                              storeTotal +=
                                  (product['productPrice'] ?? 0.0).toDouble();
                            }

                            return _buildStoreContainer(
                              storeName,
                              storeProducts,
                              storeTotal,
                              isExpanded,
                            );
                          },
                        ),
                      ),
                      // Total Price Section (without checkout button)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_rupee,
                                    size: 20,
                                    color: Colors.deepPurple,
                                  ),
                                  Text(
                                    totalPrice.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildStoreContainer(
    String storeName,
    List<Map<String, dynamic>> products,
    double storeTotal,
    bool isExpanded,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Store Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedStores[storeName] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: isExpanded ? Radius.zero : Radius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, color: Colors.blue[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${products.length} item${products.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      Text(
                        storeTotal.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
          ),
          // Products List
          if (isExpanded)
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children:
                    products.map((product) {
                      return _buildCartItem(product, product['cartItemId']);
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartData, String cartItemId) {
    final imageUrls = List<String>.from(cartData['productImageUrls'] ?? []);
    final price = (cartData['productPrice'] ?? 0.0).toDouble();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProductDetail(cartData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    imageUrls.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[0],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.deepPurple,
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                        : Center(
                          child: Icon(
                            Icons.image,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
              ),
              SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartData['productName'] ?? 'Product',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      cartData['productType'] ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 14,
                          color: Colors.deepPurple,
                        ),
                        Text(
                          price.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete Button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text('Remove Item'),
                          content: Text(
                            'Are you sure you want to remove this item from cart?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _removeFromCart(cartItemId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Remove',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
