// AddProduct.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'productDetailMyStore.dart';
import 'cloudinaryForStore.dart';

class AddProductPage extends StatefulWidget {
  final bool isEditMode;
  final Product? existingProduct;
  final int? productIndex;

  const AddProductPage({
    super.key,
    this.isEditMode = false,
    this.existingProduct,
    this.productIndex,
  });

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form Controllers
  final TextEditingController _productTypeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _shippingMethodController =
      TextEditingController();
  final TextEditingController _shippingAvailabilityController =
      TextEditingController();

  List<File> _productImages = [];
  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<Map<String, dynamic>> productCategories = [
    {'icon': '🥬', 'name': 'Fresh Vegetables'},
    {'icon': '🍎', 'name': 'Fresh Fruits'},
    {'icon': '🌾', 'name': 'Grains (rice, wheat, maize, pulses)'},
    {'icon': '🌶️', 'name': 'Spices & Herbs'},
    {'icon': '🥛', 'name': 'Dairy Products (milk, curd, ghee, butter)'},
    {'icon': '🥚', 'name': 'Eggs & Poultry'},
    {'icon': '🍯', 'name': 'Honey & Jaggery'},
    {'icon': '🥒', 'name': 'Pickles & Papads'},
    {'icon': '🍪', 'name': 'Homemade Snacks (chips, sweets, etc.)'},
    {'icon': '🌱', 'name': 'Organic Produce'},
    {'icon': '🌾', 'name': 'Seeds & Fertilizers'},
    {'icon': '🐄', 'name': 'Animal Feed'},
    {'icon': '👘', 'name': 'Handloom Sarees & Shawls'},
    {'icon': '👕', 'name': 'Cotton Clothes'},
    {'icon': '🧥', 'name': 'Woolen Wear'},
    {'icon': '👔', 'name': 'Tailored Garments'},
    {'icon': '🥻', 'name': 'Traditional Dress (dhoti, kurta, lungi)'},
    {'icon': '👜', 'name': 'Handmade Bags & Scarves'},
    {'icon': '👡', 'name': 'Footwear (chappals, sandals, slippers)'},
    {'icon': '🪑', 'name': 'Wooden Furniture'},
    {'icon': '🎋', 'name': 'Bamboo & Cane Products'},
    {'icon': '🧸', 'name': 'Handcrafted Toys'},
    {'icon': '🖼️', 'name': 'Handmade Home Decor'},
    {'icon': '🏺', 'name': 'Clay / Terracotta Pots'},
    {'icon': '🔨', 'name': 'Agricultural Tools'},
    {'icon': '🎁', 'name': 'Handicraft Gift Items'},
    {'icon': '🍽️', 'name': 'Utensils (steel, clay, aluminum)'},
    {'icon': '🧺', 'name': 'Baskets & Storage Containers'},
    {'icon': '🧼', 'name': 'Handmade Soaps & Detergents'},
    {'icon': '🕯️', 'name': 'Candles / Oil Lamps'},
    {'icon': '🧹', 'name': 'Home Cleaning Items'},
    {'icon': '🛏️', 'name': 'Blankets & Bedsheets'},
    {'icon': '⚙️', 'name': 'Farming Equipment'},
    {'icon': '💧', 'name': 'Irrigation Tools'},
    {'icon': '🌿', 'name': 'Livestock Feed & Supplements'},
    {'icon': '💊', 'name': 'Veterinary Products'},
    {'icon': '🐔', 'name': 'Poultry Equipment'},
    {'icon': '🌱', 'name': 'Seeds & Saplings'},
    {'icon': '🧱', 'name': 'Bricks, Cement, Sand'},
    {'icon': '🎨', 'name': 'Paint & Brushes'},
    {'icon': '🔩', 'name': 'Iron Rods'},
    {'icon': '🔨', 'name': 'Nails, Hammers, Wires'},
    {'icon': '🚰', 'name': 'Plumbing Materials'},
    {'icon': '🏠', 'name': 'Roofing Sheets'},
    {'icon': '💡', 'name': 'Light Bulbs, LEDs, Fans'},
    {'icon': '🔌', 'name': 'Switch Boards & Cables'},
    {'icon': '📱', 'name': 'Mobile Phones & Accessories'},
    {'icon': '📻', 'name': 'Radios & Speakers'},
    {'icon': '☀️', 'name': 'Solar Lamps / Solar Panels'},
    {'icon': '🌿', 'name': 'Ayurvedic / Herbal Products'},
    {'icon': '🧴', 'name': 'Soaps, Shampoo, Toothpaste'},
    {'icon': '🩹', 'name': 'Sanitary Products'},
    {'icon': '💉', 'name': 'First Aid Items'},
    {'icon': '😷', 'name': 'Masks & Sanitizers'},
    {'icon': '📓', 'name': 'Notebooks, Pens, Pencils'},
    {'icon': '🎒', 'name': 'Bags & School Uniforms'},
    {'icon': '📚', 'name': 'Books (educational, storybooks)'},
    {'icon': '✏️', 'name': 'Art & Craft Supplies'},
    {'icon': '🌺', 'name': 'Flower & Vegetable Seeds'},
    {'icon': '🪴', 'name': 'Gardening Tools'},
    {'icon': '🍂', 'name': 'Organic Compost / Manure'},
    {'icon': '🪴', 'name': 'Pots & Planters'},
  ];

  final List<Map<String, dynamic>> shippingMethods = [
    {'icon': '🚶', 'name': 'Self Delivery / Hand Delivery'},
    {'icon': '🏘️', 'name': 'Village-Level Delivery (within panchayat area)'},
    {'icon': '🛵', 'name': 'Delivery by Two-Wheeler / Bicycle'},
    {'icon': '🏪', 'name': 'Pickup from Store / Collection Point'},
    {'icon': '📮', 'name': 'India Post (Speed Post / Registered Parcel)'},
    {'icon': '📦', 'name': 'Rural Post Office Parcel Services'},
    {'icon': '🚐', 'name': 'Shared Jeep / Van Transport'},
    {'icon': '🚌', 'name': 'Bus Parcel Service (State Transport Bus)'},
  ];

  final List<Map<String, dynamic>> shippingAvailability = [
    {'icon': '📍', 'name': 'Local Area Only', 'color': Colors.green},
    {'icon': '🗺️', 'name': 'Within District', 'color': Colors.blue},
    {'icon': '🏛️', 'name': 'Within State', 'color': Colors.orange},
    {'icon': '🇮🇳', 'name': 'All India Delivery', 'color': Colors.purple},
    {'icon': '🏪', 'name': 'Pickup Only', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Populate fields if in edit mode
    if (widget.isEditMode && widget.existingProduct != null) {
      _productTypeController.text = widget.existingProduct!.productType;
      _productNameController.text = widget.existingProduct!.productName;
      _productDescriptionController.text =
          widget.existingProduct!.productDescription;
      _productPriceController.text =
          widget.existingProduct!.productPrice.toString();
      _stockQuantityController.text =
          widget.existingProduct!.stockQuantity.toString();
      _shippingMethodController.text = widget.existingProduct!.shippingMethod;
      _shippingAvailabilityController.text =
          widget.existingProduct!.shippingAvailability;
      _productImages = List.from(widget.existingProduct!.productImages);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _productTypeController.dispose();
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _stockQuantityController.dispose();
    _shippingMethodController.dispose();
    _shippingAvailabilityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _productImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _productImages.removeAt(index);
    });
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied || status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Microphone permission required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _productDescriptionController.text = result.recognizedWords;
          });
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_IN',
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _showProductTypeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Select Product Type',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(15),
                    itemCount: productCategories.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                productCategories[index]['icon'],
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            productCategories[index]['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple,
                            size: 16,
                          ),
                          onTap: () {
                            setState(() {
                              _productTypeController.text =
                                  productCategories[index]['name'];
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShippingMethodDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Shipping Method',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(15),
                    itemCount: shippingMethods.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                shippingMethods[index]['icon'],
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            shippingMethods[index]['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                          onTap: () {
                            setState(() {
                              _shippingMethodController.text =
                                  shippingMethods[index]['name'];
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShippingAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Shipping Coverage',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(15),
                    itemCount: shippingAvailability.length,
                    itemBuilder: (context, index) {
                      final item = shippingAvailability[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item['color'].withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: item['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                item['icon'],
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: item['color'],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: item['color'],
                            size: 16,
                          ),
                          onTap: () {
                            setState(() {
                              _shippingAvailabilityController.text =
                                  item['name'];
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_productImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add at least one product image'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    SizedBox(height: 15),
                    Text('Uploading images...', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
      );

      print('Uploading ${_productImages.length} images to Cloudinary...');

      // Upload images to Cloudinary
      List<String> imageUrls = await CloudinaryStoreService.uploadProductImages(
        _productImages,
      );

      Navigator.pop(context); // Close loading dialog

      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Successfully uploaded ${imageUrls.length} images');
      print('Image URLs: $imageUrls');

      final product = Product(
        productType: _productTypeController.text,
        productName: _productNameController.text,
        productDescription: _productDescriptionController.text,
        productPrice: double.parse(_productPriceController.text),
        stockQuantity: int.parse(_stockQuantityController.text),
        productImages: List.from(_productImages),
        productImageUrls: imageUrls, // Add Cloudinary URLs
        shippingMethod: _shippingMethodController.text,
        shippingAvailability: _shippingAvailabilityController.text,
      );

      print('Product created: ${product.productName}');
      print('Returning product to MyStore...');

      // Return the product to MyStore
      Navigator.pop(context, product);
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(20),
                      children: [
                        _buildSectionTitle('Product Information'),
                        SizedBox(height: 20),
                        _buildProductTypeField(),
                        SizedBox(height: 20),
                        _buildProductNameField(),
                        SizedBox(height: 20),
                        _buildProductDescriptionField(),
                        SizedBox(height: 20),
                        _buildProductPriceField(),
                        SizedBox(height: 20),
                        _buildStockQuantityField(),
                        SizedBox(height: 30),
                        _buildSectionTitle('Product Images'),
                        SizedBox(height: 20),
                        _buildImageUpload(),
                        SizedBox(height: 30),
                        _buildSectionTitle('Shipping Details'),
                        SizedBox(height: 20),
                        _buildShippingMethodField(),
                        SizedBox(height: 20),
                        _buildShippingAvailabilityField(),
                        SizedBox(height: 40),
                        _buildSubmitButton(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 10),
          Text(
            widget.isEditMode ? 'Edit Product' : 'Add New Product',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildProductTypeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _productTypeController,
        readOnly: false,
        onTap: _showProductTypeDialog,
        decoration: InputDecoration(
          labelText: 'Product Type',
          hintText: 'Select or type product category',
          prefixIcon: Icon(Icons.category, color: Colors.deepPurple),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_drop_down_circle, color: Colors.deepPurple),
            onPressed: _showProductTypeDialog,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please select or enter product type'
                    : null,
      ),
    );
  }

  Widget _buildProductNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _productNameController,
        decoration: InputDecoration(
          labelText: 'Product Name',
          prefixIcon: Icon(Icons.shopping_bag, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please enter product name'
                    : null,
      ),
    );
  }

  Widget _buildProductDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _productDescriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Product Description',
          prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
          suffixIcon: IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.deepPurple,
            ),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please enter product description'
                    : null,
      ),
    );
  }

  Widget _buildProductPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _productPriceController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Product Price (₹)',
          prefixIcon: Icon(Icons.currency_rupee, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter product price';
          }
          if (double.tryParse(value) == null) return 'Please enter valid price';
          return null;
        },
      ),
    );
  }

  Widget _buildStockQuantityField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _stockQuantityController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Stock Quantity',
          prefixIcon: Icon(Icons.inventory, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter stock quantity';
          }
          if (int.tryParse(value) == null) return 'Please enter valid quantity';
          return null;
        },
      ),
    );
  }

  Widget _buildImageUpload() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 60,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Upload Product Images',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap to select multiple images',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_productImages.isNotEmpty) ...[
          SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _productImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _productImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShippingMethodField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _shippingMethodController,
        readOnly: false,
        onTap: _showShippingMethodDialog,
        decoration: InputDecoration(
          labelText: 'Shipping Method',
          hintText: 'Select or type shipping method',
          prefixIcon: Icon(Icons.local_shipping, color: Colors.blue),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
            onPressed: _showShippingMethodDialog,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please select or enter shipping method'
                    : null,
      ),
    );
  }

  Widget _buildShippingAvailabilityField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _shippingAvailabilityController,
        readOnly: false,
        onTap: _showShippingAvailabilityDialog,
        decoration: InputDecoration(
          labelText: 'Shipping Coverage Area',
          hintText: 'Select or type shipping coverage',
          prefixIcon: Icon(Icons.public, color: Colors.orange),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_drop_down_circle, color: Colors.orange),
            onPressed: _showShippingAvailabilityDialog,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Please select or enter shipping coverage'
                    : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.deepPurple[300]!,
            Colors.purple[200]!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isEditMode ? Icons.save : Icons.check_circle_outline,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              widget.isEditMode ? 'Update Product' : 'Add Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
