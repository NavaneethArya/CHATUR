// MainStorePage.dart
import 'package:chatur_frontend/My_Store/My_Cart.dart';
import 'package:chatur_frontend/Other/profile_icon.dart';
import 'package:chatur_frontend/Other/support.dart';
import 'package:chatur_frontend/Screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'StoreDetailView.dart';
import 'MyStore.dart';
import 'createStore.dart';
import 'productDetailMyStore.dart';
//import 'StoreReviewsPage.dart';
import 'package:intl/intl.dart';

class MainStorePage extends StatefulWidget {
  const MainStorePage({super.key});

  @override
  State<MainStorePage> createState() => _MainStorePageState();
}

class _MainStorePageState extends State<MainStorePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showSearch = false;
  String _selectedView = 'Stores';

  final List<String> _categories = [
    'All',
    'Fresh Vegetable',
    'Pickles & Papads',
    'Dairy Products',
    'Grains',
    'Seeds & Fertilizers',
    'Home & Garden',
    'Animal Feed',
    'Tailored Garments',
    'Wooden Furniture',
    'clothing',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToMyStore() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showLoginDialog();
      return;
    }

    final storeDoc = await _firestore.collection('stores').doc(userId).get();

    if (storeDoc.exists) {
      final data = storeDoc.data()!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MyStorePage(
                storeName: data['storeName'] ?? '',
                storeDescription: data['storeDescription'] ?? '',
                storeLogo: null,
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateStorePage()),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text('Login Required'),
              ],
            ),
            content: Text('Please login to access your store.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to login page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          _buildCategoryFilter(),
          _buildViewToggle(),
          Expanded(
            child:
                _selectedView == 'Stores'
                    ? _buildStoreGrid()
                    : _buildProductsGrid(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child:
            _showSearch
                ? Container()
                : Row(
                  children: [
                    Icon(Icons.storefront, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Village Market',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
      ),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.store),
          tooltip: 'My Store',
          onPressed: _navigateToMyStore,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search stores, products...',
          prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: isSelected ? 3 : 0,
              shadowColor: Colors.deepPurple.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedView = 'Stores';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _selectedView == 'Stores'
                          ? Colors.deepPurple
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      color:
                          _selectedView == 'Stores'
                              ? Colors.white
                              : Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Stores',
                      style: TextStyle(
                        color:
                            _selectedView == 'Stores'
                                ? Colors.white
                                : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedView = 'Products';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _selectedView == 'Products'
                          ? Colors.deepPurple
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color:
                          _selectedView == 'Products'
                              ? Colors.white
                              : Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Products',
                      style: TextStyle(
                        color:
                            _selectedView == 'Products'
                                ? Colors.white
                                : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('stores')
              .where('status', isEqualTo: 'active')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Something went wrong!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var stores = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          stores =
              stores.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final storeName =
                    data['storeName']?.toString().toLowerCase() ?? '';
                final description =
                    data['storeDescription']?.toString().toLowerCase() ?? '';
                return storeName.contains(_searchQuery) ||
                    description.contains(_searchQuery);
              }).toList();
        }

        if (stores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No stores found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final storeData = stores[index].data() as Map<String, dynamic>;
            return _buildStoreCard(storeData, stores[index].id);
          },
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.deepPurple),
                SizedBox(height: 16),
                Text(
                  'Loading products...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Unable to load products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Please check your connection and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text('Retry', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No Products Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for new products',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        var products = snapshot.data!;

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          products =
              products.where((product) {
                final productName =
                    product['productData']['productName']
                        ?.toString()
                        .toLowerCase() ??
                    '';
                final productType =
                    product['productData']['productType']
                        ?.toString()
                        .toLowerCase() ??
                    '';
                return productName.contains(_searchQuery) ||
                    productType.contains(_searchQuery);
              }).toList();
        }

        // Filter by selected category
        // Filter by selected category
        if (_selectedCategory != 'All') {
          products =
              products.where((product) {
                final productType =
                    product['productData']['productType']
                        ?.toString()
                        .toLowerCase() ??
                    '';
                final searchCategory = _selectedCategory.toLowerCase();
                return productType.contains(searchCategory);
              }).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No products found'
                      : 'No products in this category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try adjusting your search'
                      : 'Check other categories',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductListCard(
              product['productData'] as Map<String, dynamic>,
              product['storeId'] as String,
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    try {
      List<Map<String, dynamic>> allProducts = [];

      final storesSnapshot =
          await _firestore
              .collection('stores')
              .where('status', isEqualTo: 'active')
              .get();

      for (var storeDoc in storesSnapshot.docs) {
        try {
          final productsSnapshot =
              await _firestore
                  .collection('stores')
                  .doc(storeDoc.id)
                  .collection('products')
                  .where('status', isEqualTo: 'active')
                  .get();

          for (var productDoc in productsSnapshot.docs) {
            allProducts.add({
              'storeId': storeDoc.id,
              'productData': productDoc.data(),
            });
          }
        } catch (e) {
          print('Error fetching products for store ${storeDoc.id}: $e');
        }
      }

      return allProducts;
    } catch (e) {
      print('Error in _fetchAllProducts: $e');
      throw e;
    }
  }

  Widget _buildProductListCard(
    Map<String, dynamic> productData,
    String storeId,
  ) {
    final imageUrls = List<String>.from(productData['productImageUrls'] ?? []);
    final stockQuantity = productData['stockQuantity'] ?? 0;
    final isOutOfStock = stockQuantity == 0;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('stores').doc(storeId).get(),
      builder: (context, storeSnapshot) {
        Map<String, dynamic>? storeData;
        if (storeSnapshot.hasData && storeSnapshot.data!.exists) {
          storeData = storeSnapshot.data!.data() as Map<String, dynamic>?;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  if (storeData != null) {
                    final product = Product(
                      productName: productData['productName'] ?? '',
                      productDescription:
                          productData['productDescription'] ?? '',
                      productType: productData['productType'] ?? '',
                      productPrice:
                          (productData['productPrice'] ?? 0.0).toDouble(),
                      stockQuantity: stockQuantity,
                      shippingMethod: productData['shippingMethod'] ?? '',
                      shippingAvailability:
                          productData['shippingAvailability'] ?? '',
                      productImages: [],
                      productImageUrls: imageUrls,
                    );

                    final store = StoreData(
                      storeName: storeData['storeName'] ?? '',
                      storeDescription: storeData['storeDescription'] ?? '',
                      storeLogo: null,
                      storeLogoUrl: storeData['storeLogoUrl'],
                      ownerName: storeData['ownerName'] ?? '',
                      phoneNumber: storeData['phoneNumber'] ?? '',
                      address: storeData['address'] ?? '',
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StoreDetailView(
                              product: product,
                              storeData: store,
                            ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            imageUrls.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrls[0],
                                    width: 100,
                                    height: 100,
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
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                            if (isOutOfStock)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'OUT OF STOCK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                productData['productType'] ?? 'Product',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              productData['productName'] ?? 'Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.currency_rupee,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),
                                    Text(
                                      '${(productData['productPrice'] ?? 0.0).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isOutOfStock
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2,
                                        size: 14,
                                        color:
                                            isOutOfStock
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        isOutOfStock ? 'Out' : '$stockQuantity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isOutOfStock
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (storeData != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      storeData['storeName'] ?? 'Store',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cart Button - Top Right Corner
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final userId = _auth.currentUser?.uid;
                    if (userId == null) {
                      _showLoginDialog();
                      return;
                    }

                    if (isOutOfStock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('This product is out of stock'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _firestore
                          .collection('users')
                          .doc(userId)
                          .collection('cart')
                          .add({
                            'productName': productData['productName'],
                            'productType': productData['productType'],
                            'productPrice': productData['productPrice'],
                            'productImageUrls': imageUrls,
                            'productDescription':
                                productData['productDescription'],
                            'stockQuantity': stockQuantity,
                            'shippingMethod': productData['shippingMethod'],
                            'shippingAvailability':
                                productData['shippingAvailability'],
                            'storeId': storeId,
                            'storeName': storeData?['storeName'] ?? '',
                            'storeDescription':
                                storeData?['storeDescription'] ?? '',
                            'storeLogoUrl': storeData?['storeLogoUrl'],
                            'ownerName': storeData?['ownerName'] ?? '',
                            'phoneNumber': storeData?['phoneNumber'] ?? '',
                            'address': storeData?['address'] ?? '',
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Added to cart'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding to cart'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> storeData, String storeId) {
    final userId = _auth.currentUser?.uid;

    return GestureDetector(
      onTap: () => _navigateToStoreProducts(storeData, storeId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.withOpacity(0.7),
                        Colors.purple.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child:
                        storeData['storeLogoUrl'] != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: storeData['storeLogoUrl'],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.store,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                              ),
                            )
                            : Icon(Icons.store, size: 50, color: Colors.white),
                  ),
                ),
                // REVIEWS & RATING BUTTONS
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reviews Button
                      // Reviews Button
                      Expanded(
                        child: InkWell(
                          onTap:
                              () => _showReviewsBottomSheet(storeId, storeData),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review,
                                size: 20, // CHANGE THIS from 16 to 20 or 22
                                color: Colors.deepPurple,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Reviews',
                                style: TextStyle(
                                  fontSize:
                                      12, // OPTIONALLY increase from 11 to 12
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 20, color: Colors.grey[300]),
                      // Rating Button with Average
                      Expanded(
                        child: InkWell(
                          onTap: () => _showRatingDialog(storeId, storeData),
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                _firestore
                                    .collection('stores')
                                    .doc(storeId)
                                    .collection('ratings')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              double avgRating = 0.0;
                              if (snapshot.hasData &&
                                  snapshot.data!.docs.isNotEmpty) {
                                double totalRating = 0;
                                for (var doc in snapshot.data!.docs) {
                                  totalRating +=
                                      (doc.data()
                                          as Map<String, dynamic>)['rating'] ??
                                      0;
                                }
                                avgRating =
                                    totalRating / snapshot.data!.docs.length;
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 20, // CHANGE THIS from 16 to 20 or 22
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    avgRating > 0
                                        ? avgRating.toStringAsFixed(1)
                                        : 'Rate',
                                    style: TextStyle(
                                      fontSize:
                                          12, // OPTIONALLY increase from 11 to 12
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeData['storeName'] ?? 'Store',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          storeData['storeDescription'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                storeData['address'] ?? 'Local',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (userId != null)
              Positioned(
                top: 8,
                right: 8,
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      _firestore
                          .collection('users')
                          .doc(userId)
                          .collection('favorites')
                          .doc(storeId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.hasData && snapshot.data!.exists;

                    return GestureDetector(
                      onTap: () => _toggleFavorite(storeId, storeData),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // REVIEW BOTTOM SHEET METHOD
  void _showReviewsBottomSheet(String storeId, Map<String, dynamic> storeData) {
    final userId = _auth.currentUser?.uid;
    final TextEditingController reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(top: 12, bottom: 8),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.rate_review,
                              color: Colors.deepPurple,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reviews',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    storeData['storeName'] ?? 'Store',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1),
                      // Reviews List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              _firestore
                                  .collection('stores')
                                  .doc(storeId)
                                  .collection('reviews')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.reviews_outlined,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No reviews yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Be the first to review!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final reviewData =
                                    snapshot.data!.docs[index].data()
                                        as Map<String, dynamic>;
                                final timestamp =
                                    reviewData['timestamp'] as Timestamp?;
                                final date =
                                    timestamp != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(timestamp.toDate())
                                        : 'Recently';

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.deepPurple
                                                .withOpacity(0.2),
                                            child: Icon(
                                              Icons.person,
                                              size: 20,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  reviewData['userName'] ??
                                                      'Anonymous',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  date,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        reviewData['review'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Write Review Section
                      if (userId != null)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: reviewController,
                                    decoration: InputDecoration(
                                      hintText: 'Write your review...',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    maxLines: null,
                                  ),
                                ),
                                SizedBox(width: 10),
                                FloatingActionButton(
                                  onPressed: () async {
                                    if (reviewController.text.trim().isEmpty)
                                      return;

                                    try {
                                      final user = _auth.currentUser;
                                      await _firestore
                                          .collection('stores')
                                          .doc(storeId)
                                          .collection('reviews')
                                          .add({
                                            'userId': userId,
                                            'userName':
                                                user?.displayName ??
                                                'Anonymous User',
                                            'review':
                                                reviewController.text.trim(),
                                            'timestamp':
                                                FieldValue.serverTimestamp(),
                                          });

                                      reviewController.clear();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Review posted successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error posting review'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  backgroundColor: Colors.deepPurple,
                                  child: Icon(Icons.send, color: Colors.white),
                                  mini: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }

  // RATING DIALOG METHOD
  void _showRatingDialog(String storeId, Map<String, dynamic> storeData) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      _showLoginDialog();
      return;
    }

    int selectedRating = 0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Column(
                    children: [
                      Icon(Icons.star_rate, size: 50, color: Colors.amber),
                      SizedBox(height: 10),
                      Text(
                        'Rate this Store',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        storeData['storeName'] ?? 'Store',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to rate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                selectedRating > index
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 40,
                                color: Colors.amber,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 10),
                      if (selectedRating > 0)
                        Text(
                          '$selectedRating Star${selectedRating > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedRating == 0
                              ? null
                              : () async {
                                try {
                                  await _firestore
                                      .collection('stores')
                                      .doc(storeId)
                                      .collection('ratings')
                                      .doc(userId)
                                      .set({
                                        'userId': userId,
                                        'rating': selectedRating,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.white),
                                          SizedBox(width: 10),
                                          Text(
                                            'Rating submitted successfully!',
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error submitting rating'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.2),
                    Colors.purple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(75),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'No Stores Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Be the first to create a store\nand start selling!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _navigateToMyStore,
              icon: Icon(Icons.add_business, color: Colors.white),
              label: Text(
                'Create Your Store',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToMyStore,
      backgroundColor: Colors.deepPurple,
      icon: Icon(Icons.add_business, color: Colors.white),
      label: Text(
        'My Store',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevation: 8,
    );
  }

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(user),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileIcon()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              title: 'My Store',
              onTap: () {
                Navigator.pop(context);
                _navigateToMyStore();
              },
            ),
            // _buildDrawerItem(
            //   icon: Icons.category,
            //   title: 'Categories',
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            Divider(height: 30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'Favorites',
              onTap: () {
                Navigator.pop(context);
                _navigateToFavorites();
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: 'Cart',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyCartPage()),
                );
              },
            ),
            // _buildDrawerItem(
            //   icon: Icons.message,
            //   title: 'Messages',
            //   trailing: _buildBadge('3'),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // Divider(height: 30, thickness: 1),
            // _buildDrawerItem(
            //   icon: Icons.settings,
            //   title: 'Settings',
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const SupportScreen(isAboutPage: false),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: 'About CHATUR',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const SupportScreen(isAboutPage: true),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            if (user != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(User? user) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.deepPurple[300]!,
            Colors.purple[200]!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 45, color: Colors.deepPurple),
          ),
          SizedBox(height: 15),
          Text(
            user?.displayName ?? 'Guest User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            user?.email ?? 'Please login to continue',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.deepPurple, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.storefront, color: Colors.deepPurple, size: 28),
                SizedBox(width: 10),
                Text('Village Market'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Connecting villages, empowering local businesses.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                Text(
                  '© 2024 Chatur. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  void _navigateToStoreProducts(
    Map<String, dynamic> storeData,
    String storeId,
  ) async {
    final productsSnapshot =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .where('status', isEqualTo: 'active')
            .get();

    if (productsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This store has no products yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                StoreProductsPage(storeData: storeData, storeId: storeId),
      ),
    );
  }

  Future<void> _toggleFavorite(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showLoginDialog();
      return;
    }

    try {
      final favoriteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(storeId);

      final favoriteDoc = await favoriteRef.get();

      if (favoriteDoc.exists) {
        await favoriteRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.white),
                SizedBox(width: 10),
                Text('Removed from favorites'),
              ],
            ),
            backgroundColor: Colors.grey[700],
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await favoriteRef.set({
          'storeId': storeId,
          'storeName': storeData['storeName'],
          'storeDescription': storeData['storeDescription'],
          'storeLogoUrl': storeData['storeLogoUrl'],
          'address': storeData['address'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 10),
                Text('Added to favorites'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToFavorites() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showLoginDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritesPage()),
    );
  }
}

// Favorites Page
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

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
            Icon(Icons.favorite, size: 28),
            SizedBox(width: 10),
            Text(
              'My Favorites',
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
                      'Please login to view favorites',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('favorites')
                        .orderBy('timestamp', descending: true)
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
                            Icons.favorite_border,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No Favorites Yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Start adding stores to your favorites!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final favoriteData =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      final storeId = favoriteData['storeId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('stores')
                                .doc(storeId)
                                .get(),
                        builder: (context, storeSnapshot) {
                          if (!storeSnapshot.hasData ||
                              !storeSnapshot.data!.exists) {
                            return Container();
                          }

                          final storeData =
                              storeSnapshot.data!.data()
                                  as Map<String, dynamic>;

                          return _buildFavoriteStoreCard(
                            context,
                            storeData,
                            storeId,
                            userId!,
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }

  static Widget _buildFavoriteStoreCard(
    BuildContext context,
    Map<String, dynamic> storeData,
    String storeId,
    String userId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    StoreProductsPage(storeData: storeData, storeId: storeId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.withOpacity(0.7),
                        Colors.purple.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child:
                        storeData['storeLogoUrl'] != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: storeData['storeLogoUrl'],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.store,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                              ),
                            )
                            : Icon(Icons.store, size: 50, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeData['storeName'] ?? 'Store',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          storeData['storeDescription'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                storeData['address'] ?? 'Local',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('favorites')
                      .doc(storeId)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.favorite_border, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Removed from favorites'),
                        ],
                      ),
                      backgroundColor: Colors.grey[700],
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Store Products Page
class StoreProductsPage extends StatelessWidget {
  final Map<String, dynamic> storeData;
  final String storeId;

  const StoreProductsPage({
    super.key,
    required this.storeData,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                storeData['storeName'] ?? 'Store',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  storeData['storeLogoUrl'] != null
                      ? CachedNetworkImage(
                        imageUrl: storeData['storeLogoUrl'],
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.deepPurple.withOpacity(0.3),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.deepPurple.withOpacity(0.3),
                              child: Icon(
                                Icons.store,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.purple[300]!],
                          ),
                        ),
                        child: Icon(Icons.store, size: 80, color: Colors.white),
                      ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.deepPurple,
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeData['storeDescription'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storeData['address'] ?? 'Local Area',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 18, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        storeData['phoneNumber'] ?? 'N/A',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('stores')
                      .doc(storeId)
                      .collection('products')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No products available'),
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final productData =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _buildProductCard(context, productData, storeData);
                  }, childCount: snapshot.data!.docs.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> productData,
    Map<String, dynamic> storeData,
  ) {
    final imageUrls = List<String>.from(productData['productImageUrls'] ?? []);

    return GestureDetector(
      onTap: () {
        final product = Product(
          productName: productData['productName'] ?? '',
          productDescription: productData['productDescription'] ?? '',
          productType: productData['productType'] ?? '',
          productPrice: (productData['productPrice'] ?? 0.0).toDouble(),
          stockQuantity: productData['stockQuantity'] ?? 0,
          shippingMethod: productData['shippingMethod'] ?? '',
          shippingAvailability: productData['shippingAvailability'] ?? '',
          productImages: [],
          productImageUrls: imageUrls,
        );

        final store = StoreData(
          storeName: storeData['storeName'] ?? '',
          storeDescription: storeData['storeDescription'] ?? '',
          storeLogo: null,
          storeLogoUrl: storeData['storeLogoUrl'],
          ownerName: storeData['ownerName'] ?? '',
          phoneNumber: storeData['phoneNumber'] ?? '',
          address: storeData['address'] ?? '',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    StoreDetailView(product: product, storeData: store),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  imageUrls.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[0],
                          width: double.infinity,
                          height: 140,
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
                                size: 50,
                                color: Colors.grey,
                              ),
                        ),
                      )
                      : Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                  if (productData['stockQuantity'] != null &&
                      productData['stockQuantity'] == 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData['productName'] ?? 'Product',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      productData['productType'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${(productData['productPrice'] ?? 0.0).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (productData['stockQuantity'] ?? 0) > 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (productData['stockQuantity'] ?? 0) > 0
                                ? '${productData['stockQuantity']}'
                                : 'Out',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  (productData['stockQuantity'] ?? 0) > 0
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
