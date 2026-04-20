import '../utils/url_utils.dart';

/// Product model matching NexaFlow backend /shop/products
class Product {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String? shortDescription;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final double costPrice;
  final int stock;
  final List<String> images;
  final String? brand;
  final bool isActive;
  final bool? isFeatured;
  final List<String> tags;
  final String? categoryId;
  final String? categoryName;
  final double taxRate;
  final String createdAt;
  final String updatedAt;
  final double averageRating;
  final int reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.shortDescription,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    required this.costPrice,
    required this.stock,
    required this.images,
    this.brand, 
    required this.isActive,
    this.isFeatured,
    required this.tags,
    this.categoryId,
    this.categoryName,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;
  double get discountPercent =>
      hasDiscount ? ((compareAtPrice! - price) / compareAtPrice! * 100).roundToDouble() : 0;
  String? get mainImage => images.isNotEmpty ? images.first : null;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String? ?? '',
    shortDescription: json['shortDescription'] as String?,
    sku: json['sku'] as String? ?? '',
    price: _safeParseDouble(json['price']),
    compareAtPrice: json['compareAtPrice'] != null ? _safeParseDouble(json['compareAtPrice']) : null,
    costPrice: json['costPrice'] != null ? _safeParseDouble(json['costPrice']) : 0,
    stock: json['stock'] as int? ?? 0,
    images: (json['images'] as List<dynamic>?)
            ?.map((e) => UrlUtils.fixLocalhost(e.toString()))
            .toList() ??
        [],
    brand: json['brand'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    isFeatured: json['isFeatured'] as bool?,
    tags: (json['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    categoryId: json['categoryId'] as String?,
    categoryName: json['categoryName'] as String?,
    taxRate: json['taxRate'] != null ? _safeParseDouble(json['taxRate']) : 0,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    averageRating: _safeParseDouble(json['averageRating']),
    reviewCount: _safeParseInt(json['reviewCount']),
  );
}

/// Review model
class Review {
  final String id;
  final String productId;
  final String? customerId;
  final String customerName;
  final String? title;
  final int rating;
  final String comment;
  final String? reply;
  final String? adminReply;
  final String createdAt;

  const Review({
    required this.id,
    required this.productId,
    this.customerId,
    required this.customerName,
    this.title,
    required this.rating,
    required this.comment,
    this.reply,
    this.adminReply,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    productId: json['productId'] as String? ?? '',
    customerId: json['customerId'] as String?,
    customerName: json['customerName'] as String? ?? 'Anonyme',
    title: json['title'] as String?,
    rating: _safeParseInt(json['rating'], defaultValue: 5),
    comment: json['comment'] as String? ?? '',
    reply: json['reply'] as String?,
    adminReply: json['adminReply'] as String?,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

/// Category model
class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    required this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    image: UrlUtils.fixLocalhost(json['image'] as String?),
    productCount: _safeParseInt(json['productCount']),
  );
}

/// Cart item
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// Customer model
class Customer {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String? city;
  final String role;
  final int loyaltyPoints;
  final String loyaltyTier;
  final String createdAt;

  const Customer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.city,
    required this.role,
    required this.loyaltyPoints,
    required this.loyaltyTier,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    role: json['role'] is Map
        ? ((json['role'] as Map)['name'] ?? 'customer').toString()
        : (json['role'] as String? ?? 'customer'),
    loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
    loyaltyTier: json['loyaltyTier'] as String? ?? 'bronze',
    createdAt: json['createdAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'address': address,
    'city': city,
    'role': role,
    'loyaltyPoints': loyaltyPoints,
    'loyaltyTier': loyaltyTier,
    'createdAt': createdAt,
  };
}

/// Order model
class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final double subtotal;
  final double? deliveryFee;
  final String createdAt;
  final String? updatedAt;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String? notes;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.subtotal,
    this.deliveryFee,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.deliveryAddress,
    this.notes,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String? ?? '#',
    status: json['status'] as String? ?? 'pending',
    total: _safeParseDouble(json['total']),
    subtotal: _safeParseDouble(json['subtotal'] ?? json['total']),
    deliveryFee: json['deliveryFee'] != null ? _safeParseDouble(json['deliveryFee']) : null,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String?,
    paymentMethod: json['paymentMethod'] as String?,
    deliveryAddress: json['deliveryAddress'] as String?,
    notes: json['notes'] as String?,
    items: (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double total;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = _safeParseInt(json['quantity'], defaultValue: 1);
    final unitPrice = _safeParseDouble(json['unitPrice'] ?? json['price']);
    double total = _safeParseDouble(json['total'] ?? json['totalPrice']);
    
    // If total is 0 but price and qty are positive, calculate it
    if (total == 0 && unitPrice > 0) {
      total = unitPrice * qty;
    }

    return OrderItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productImage: UrlUtils.fixLocalhost(json['productImage'] as String?),
      quantity: qty,
      unitPrice: unitPrice,
      total: total,
    );
  }
}

double _safeParseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Banner model for advertising
class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? ctaText;
  final String? ctaLink;
  final String? image;
  final String? bgColor;
  final String? textColor;
  final String position;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.ctaText,
    this.ctaLink,
    this.image,
    this.bgColor,
    this.textColor,
    required this.position,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    description: json['description'] as String?,
    ctaText: json['ctaText'] as String?,
    ctaLink: json['ctaLink'] as String?,
    image: UrlUtils.fixLocalhost(json['image'] as String?),
    bgColor: json['bgColor'] as String?,
    textColor: json['textColor'] as String?,
    position: json['position'] as String? ?? 'hero',
  );
}

/// Store Configuration model
class StoreConfig {
  final Map<String, dynamic> appearance;
  final Map<String, dynamic> identity;
  
  const StoreConfig({
    required this.appearance,
    required this.identity,
  });

  int get heroSlideDuration => _safeParseInt(appearance['heroSlideDuration'], defaultValue: 5);

  factory StoreConfig.fromJson(Map<String, dynamic> json) {
    // If it's wrapped in { data: ... }
    final data = json['data'] ?? json;
    return StoreConfig(
      appearance: (data['appearance'] as Map<String, dynamic>?) ?? {},
      identity: (data['identity'] as Map<String, dynamic>?) ?? {},
    );
  }
}
