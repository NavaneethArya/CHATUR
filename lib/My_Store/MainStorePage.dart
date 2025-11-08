// MainStorePage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'StoreDetailView.dart';
import 'MyStore.dart';
import 'createStore.dart';
import 'productDetailMyStore.dart';

class MainStorePage extends StatefulWidget {
  const MainStorePage({Key? key}) : super(key: key);

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

  final List<String> _categories = [
    'All',
    'Food & Groceries',
    'Clothing & Textiles',
    'Handicrafts',
    'Electronics',
    'Agriculture',
    'Home & Garden',
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

    // Check if user has a store
    final storeDoc = await _firestore.collection('stores').doc(userId).get();

    if (storeDoc.exists) {
      final data = storeDoc.data()!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyStorePage(
            storeName: data['storeName'] ?? '',
            storeDescription: data['storeDescription'] ?? '',
            storeLogo: null,
          ),
        ),
      );
    } else {
      // Navigate to create store
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateStorePage()),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          Expanded(child: _buildStoreGrid()),
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
              Colors.purple[200]!
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _showSearch
            ? Container()
            : Row(
                children: [
                  Icon(Icons.storefront, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Village Marketplace',
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

  Widget _buildStoreGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('stores')
          .where('status', isEqualTo: 'active')
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

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          stores = stores.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final storeName = data['storeName']?.toString().toLowerCase() ?? '';
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
            childAspectRatio: 0.75,
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

  Widget _buildStoreCard(Map<String, dynamic> storeData, String storeId) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Logo
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
                child: storeData['storeLogoUrl'] != null
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
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        size: 50,
                        color: Colors.white,
                      ),
              ),
            ),
            // Store Info
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
                        Icon(Icons.location_on,
                            size: 14, color: Colors.deepPurple),
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
      icon: Icon(Icons.add_business),
      label: Text(
        'My Store',
        style: TextStyle(fontWeight: FontWeight.bold),
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
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(user),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.store,
              title: 'My Store',
              onTap: () {
                Navigator.pop(context);
                _navigateToMyStore();
              },
            ),
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Categories',
              onTap: () {
                Navigator.pop(context);
                // Navigate to categories
              },
            ),
            Divider(height: 30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'Favorites',
              onTap: () {
                Navigator.pop(context);
                // Navigate to favorites
              },
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Order History',
              onTap: () {
                Navigator.pop(context);
                // Navigate to order history
              },
            ),
            _buildDrawerItem(
              icon: Icons.message,
              title: 'Messages',
              trailing: _buildBadge('3'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to messages
              },
            ),
            Divider(height: 30, thickness: 1),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                // Navigate to help
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
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
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
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
            child: Icon(
              Icons.person,
              size: 45,
              color: Colors.deepPurple,
            ),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.storefront, color: Colors.deepPurple, size: 28),
            SizedBox(width: 10),
            Text('Village Marketplace'),
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
      Map<String, dynamic> storeData, String storeId) async {
    // Fetch products for this store
    final productsSnapshot = await _firestore
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

    // Navigate to store products page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreProductsPage(
          storeData: storeData,
          storeId: storeId,
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
    Key? key,
    required this.storeData,
    required this.storeId,
  }) : super(key: key);

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
                          placeholder: (context, url) => Container(
                            color: Colors.deepPurple.withOpacity(0.3),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.deepPurple.withOpacity(0.3),
                            child: Icon(Icons.store, size: 80, color: Colors.white),
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
                      Icon(Icons.location_on, size: 18, color: Colors.deepPurple),
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
              stream: FirebaseFirestore.instance
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final productData =
                          snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildProductCard(context, productData, storeData);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, Map<String, dynamic> productData, Map<String, dynamic> storeData) {
    final imageUrls = List<String>.from(productData['productImageUrls'] ?? []);

    return GestureDetector(
      onTap: () {
        // Create Product and StoreData objects
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

        // Navigate to product detail view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailView(
              product: product,
              storeData: store,
            ),
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
            // Product Image
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
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepPurple,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            // Product Info
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (productData['stockQuantity'] ?? 0) > 0
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
                              color: (productData['stockQuantity'] ?? 0) > 0
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