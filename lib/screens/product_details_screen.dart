import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  Product? product;
  String? productImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (product == null) {
      final Product? receivedProduct =
          ModalRoute.of(context)?.settings.arguments as Product?;
      if (receivedProduct != null) {
        setState(() {
          product = receivedProduct;
        });
      }
    }
  }

  Widget _buildImage() {
    if (product == null) return const SizedBox();

    String categoryFolder;

    switch (product!.category) {
      case 'Paintings':
        categoryFolder = 'paintings';
        break;
      case 'Ceramics':
        categoryFolder = 'ceramics';
        break;
      case 'Jewelry':
        categoryFolder = 'jewelry';
        break;
      case 'Clothing':
        categoryFolder = 'clothing';
        break;
      case 'Miniature':
        categoryFolder = 'miniature';
        break;
      default:
        categoryFolder = product!.category.toLowerCase();
    }

    final jpgPath = 'assets/images/$categoryFolder/${product!.id}.jpg';

    return Image.asset(
      jpgPath,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        final pngPath = 'assets/images/$categoryFolder/${product!.id}.png';
        return Image.asset(
          pngPath,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error2, stackTrace2) {
            // If both asset images fail, try to use network image
            if (productImage != null && productImage!.startsWith('http')) {
              return Image.network(
                productImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error3, stackTrace3) {
                  return Container(
                    color: const Color(0xFFF5F5F0),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 40, color: Color(0xFF8B4513)),
                          SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8B4513)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return Container(
              color: const Color(0xFFF5F5F0),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 40, color: Color(0xFF8B4513)),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8B4513)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            color: Colors.amber,
            size: 18,
          );
        } else if (index < rating) {
          return const Icon(
            Icons.star_half,
            color: Colors.amber,
            size: 18,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.grey[400],
            size: 18,
          );
        }
      }),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
            icon: const Icon(Icons.remove),
            color: const Color(0xFF8B4513),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              quantity.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B4513),
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => quantity++),
            icon: const Icon(Icons.add),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Product Details',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final cartItemCount = cartProvider.cartItems.length;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart,
                            color: Color(0xFF8B4513)),
                        onPressed: () {
                          Navigator.pushNamed(context, '/cart');
                        },
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$cartItemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF8B4513),
              ),
              SizedBox(height: 16),
              Text(
                'Product not found',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The product you\'re looking for doesn\'t exist.',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Product Details',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final cartItemCount = cartProvider.cartItems.length;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart,
                              color: Color(0xFF8B4513)),
                          onPressed: () {
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                        if (cartItemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$cartItemCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            expandedHeight: 360,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF5F5F0),
                      Color(0xFFEDEDE5),
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(top: 80, left: 16, right: 16),
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImage(),
                        ),
                      ),
                      Positioned(
                        top: 90,
                        right: 26,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, child) {
                            final isInWishlist = wishlistProvider.wishlist
                                .any((p) => p.id == product!.id);
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (isInWishlist) {
                                    wishlistProvider
                                        .removeFromWishlist(product!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Removed from wishlist',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor: Colors.red[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    wishlistProvider.addToWishlist(product!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Added to wishlist',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF8B4513),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    isInWishlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isInWishlist
                                        ? Colors.red[400]
                                        : const Color(0xFF8B4513),
                                    size: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product!.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '\$${product!.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product!.description.isNotEmpty
                        ? product!.description
                        : 'No description available for this product.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildQuantitySelector(),
                      const Spacer(),
                      Text(
                        'Total: \$${(product!.price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cartProvider =
                            Provider.of<CartProvider>(context, listen: false);
                        await cartProvider.addToCart(
                          product!,
                          quantity: quantity,
                          imageUrl: productImage ??
                              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added $quantity ${product!.name}${quantity > 1 ? 's' : ''} to cart',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: const Color(0xFF8B4513),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add To Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
