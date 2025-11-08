// MyStore.dart
import 'package:chatur_frontend/My_Store/StoreDetailView.dart';
import 'package:chatur_frontend/My_Store/createStore.dart';
import 'package:chatur_frontend/My_Store/productDetailMyStore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'AddProduct.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyStorePage extends StatefulWidget {
  final String storeName;
  final String storeDescription;
  final File? storeLogo;

  MyStorePage({
    required this.storeName,
    required this.storeDescription,
    this.storeLogo,
  });

  @override
  _MyStorePageState createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage>
    with TickerProviderStateMixin {
  final ProductManager _productManager = ProductManager();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _checkStoreCreation();

    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fabAnimation =
        CurvedAnimation(parent: _fabController, curve: Curves.easeInOut);
    _fabController.forward();

    print('MyStore initialized with ${_productManager.productCount} products');

    _initializeFromFirebase();
  
  _fabController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 300),
  );
  _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeInOut);
  _fabController.forward();
  }

  Future<void> _initializeFromFirebase() async {
  await _productManager.initializeStore();
  await _productManager.loadProducts();
  
  if (mounted) {
    setState(() {});
    _checkStoreCreation();
  }
  
  print('MyStore initialized with ${_productManager.productCount} products');
}

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailView(
          product: product,
          storeData: _productManager.storeData!,
        ),
      ),
    );
  }

  void _checkStoreCreation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_productManager.isStoreCreated) {
        _showNoStoreDialog();
      }
    });
  }

  void _showNoStoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('No Store Found')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 60, color: Colors.deepPurple.withOpacity(0.5)),
            SizedBox(height: 15),
            Text(
              'You haven\'t created a store yet!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Please create your store first to start adding products and manage your business.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: Size(double.infinity, 45),
            ),
            child: Text('Create Store Now',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Store Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.edit,
              title: 'Edit Store',
              subtitle: 'Update store information',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _navigateToEditStore();
              },
            ),
            Divider(height: 1),
            _buildMenuOption(
              icon: Icons.delete_sweep,
              title: 'Clear All Products',
              subtitle: 'Remove all products from store',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showClearProductsDialog();
              },
            ),
            Divider(height: 1),
            _buildMenuOption(
              icon: Icons.pause_circle_outline,
              title: 'Deactivate Store Temporarily',
              subtitle: 'Hide store but keep data saved',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                _showDeactivateStoreDialog();
              },
            ),
            Divider(height: 1),
            _buildMenuOption(
              icon: Icons.delete_forever,
              title: 'Delete Store',
              subtitle: 'Permanently delete store and all data',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteStoreDialog();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToEditStore() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStorePage(
          storeData: _productManager.storeData!,
        ),
      ),
    );

    if (result != null && result is StoreData) {
      setState(() {
        _productManager.updateStore(result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Store updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showClearProductsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Clear All Products'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep,
                size: 60, color: Colors.orange.withOpacity(0.5)),
            SizedBox(height: 15),
            Text(
              'Are you sure you want to clear all products?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'This will remove all ${_productManager.productCount} products from your store. This action cannot be undone.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _productManager.clearAllProducts();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('All products cleared'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeactivateStoreDialog() {
    final TextEditingController daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Deactivate Store')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 60, color: Colors.amber.withOpacity(0.5)),
            SizedBox(height: 15),
            Text(
              'How long do you want to deactivate your store?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of days',
                prefixIcon: Icon(Icons.calendar_today, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your store will be hidden but all data will be saved securely.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(daysController.text);
              if (days == null || days <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number of days'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final deactivateUntil = DateTime.now().add(Duration(days: days));
              _productManager.deactivateStore(deactivateUntil);

              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Store deactivated for $days day${days > 1 ? 's' : ''}',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.amber,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Store'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_forever,
                size: 60, color: Colors.red.withOpacity(0.5)),
            SizedBox(height: 15),
            Text(
              'Are you sure you want to delete your store?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'This will permanently delete your store, all products, and store information. This action cannot be undone.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Store: ${widget.storeName}\nProducts: ${_productManager.productCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _productManager.deleteStore();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Store deleted successfully'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete Permanently',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          isEditMode: false,
        ),
      ),
    );

    if (result != null && result is Product) {
      _productManager.addProduct(result);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Product "${result.productName}" added successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToEditProduct(int index) async {
    final product = _productManager.products[index];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          isEditMode: true,
          existingProduct: product,
          productIndex: index,
        ),
      ),
    );

    if (result != null && result is Product) {
      setState(() {
        _productManager.products[index] = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Product "${result.productName}" updated successfully!')),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showImageZoomFromUrl(
      List<String> imageUrls, int initialIndex, String productName) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return ImageZoomDialogUrl(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          productName: productName,
        );
      },
    );
  }

  void _deleteProduct(int index) {
    final productName = _productManager.products[index].productName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Delete Product'),
            ],
          ),
          content: Text(
              'Are you sure you want to delete "$productName"?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _productManager.removeProduct(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Product deleted'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _productManager.products;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
              Colors.purple.shade50
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(products.length),
              Expanded(
                child: products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsList(products),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddProduct,
          backgroundColor: Colors.deepPurple,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text('Add Product',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildAppBar(int productCount) {
    return Container(
      padding: EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          if (widget.storeLogo != null)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(widget.storeLogo!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.store, color: Colors.deepPurple, size: 30),
            ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.storeName,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('$productCount Product${productCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
            onPressed: _showMenuOptions,
            tooltip: 'Store Options',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 800),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.deepPurple.withOpacity(0.2),
                        Colors.purple.withOpacity(0.1)
                      ]),
                      borderRadius: BorderRadius.circular(75),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 80, color: Colors.deepPurple),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 1000),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text('No Products Yet',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Start adding products to your store\nand grow your business!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5),
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.purple[300]!]),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8))
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToAddProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          icon: Icon(Icons.add_circle_outline,
                              size: 28, color: Colors.white),
                          label: Text('Add Your First Product',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, index);
      },
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final storeData = _productManager.storeData;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 200,
                child: Stack(
                  children: [
                    product.productImageUrls.isNotEmpty
                        ? PageView.builder(
                            itemCount: product.productImageUrls.length,
                            itemBuilder: (context, imgIndex) {
                              return GestureDetector(
                                onTap: () => _showImageZoomFromUrl(
                                    product.productImageUrls,
                                    imgIndex,
                                    product.productName),
                                child: Hero(
                                  tag:
                                      'product_image_${product.productName}_$imgIndex',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20)),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          product.productImageUrls[imgIndex],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color:
                                            Colors.deepPurple.withOpacity(0.1),
                                        child: Icon(Icons.error,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20)),
                            ),
                            child: Center(
                                child: Icon(Icons.image,
                                    size: 60, color: Colors.deepPurple)),
                          ),
                    if (storeData?.storeLogo != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.deepPurple, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: ClipOval(
                            child: Image.file(
                              storeData!.storeLogo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.store,
                                    color: Colors.deepPurple, size: 20);
                              },
                            ),
                          ),
                        ),
                      ),
                    if (product.productImageUrls.length > 1)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.photo_library,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('${product.productImageUrls.length}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(product.productType,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(height: 8),
                      Text(product.productName,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 8),
                      Text(product.productDescription,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${product.productPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.stockQuantity > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Stock: ${product.stockQuantity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: product.stockQuantity > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_shipping,
                              size: 14, color: Colors.blue),
                          SizedBox(width: 5),
                          Expanded(
                              child: Text(product.shippingMethod,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.public, size: 14, color: Colors.orange),
                          SizedBox(width: 5),
                          Expanded(
                              child: Text(product.shippingAvailability,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToProductDetail(product),
                  icon: Icon(Icons.visibility, size: 18, color: Colors.green),
                  label: Text('View', style: TextStyle(color: Colors.green)),
                ),
                SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _navigateToEditProduct(index),
                  icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                  label: Text('Edit', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _deleteProduct(index),
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Image Zoom Dialog Widget for URLs
class ImageZoomDialogUrl extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String productName;

  ImageZoomDialogUrl({
    required this.imageUrls,
    required this.initialIndex,
    required this.productName,
  });

  @override
  _ImageZoomDialogUrlState createState() => _ImageZoomDialogUrlState();
}

class _ImageZoomDialogUrlState extends State<ImageZoomDialogUrl> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'product_image_${widget.productName}_$index',
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${widget.imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.imageUrls.length > 1) ...[
              if (currentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              if (currentIndex < widget.imageUrls.length - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
