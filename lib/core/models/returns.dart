import 'models.dart';
import '../utils/url_utils.dart';

enum ReturnStatus { pending, approved, rejected, refunded, exchanged }

enum ReturnReason {
  defective,
  wrong_item,
  not_satisfied,
  damaged,
  expired,
  other
}

extension ReturnReasonExtension on ReturnReason {
  String get label {
    switch (this) {
      case ReturnReason.defective: return 'Produit défectueux';
      case ReturnReason.wrong_item: return 'Mauvais article reçu';
      case ReturnReason.not_satisfied: return 'Non satisfait';
      case ReturnReason.damaged: return 'Produit endommagé';
      case ReturnReason.expired: return 'Produit expiré';
      case ReturnReason.other: return 'Autre';
    }
  }
}

class ProductReturn {
  final String id;
  final String returnNumber;
  final String orderId;
  final String orderNumber;
  final String? customerId;
  final String customerName;
  final List<ReturnItem> items;
  final ReturnReason reason;
  final String? reasonDetails;
  final ReturnStatus status;
  final double refundAmount;
  final List<String> proofImages;
  final String createdAt;

  ProductReturn({
    required this.id,
    required this.returnNumber,
    required this.orderId,
    required this.orderNumber,
    this.customerId,
    required this.customerName,
    required this.items,
    required this.reason,
    this.reasonDetails,
    required this.status,
    required this.refundAmount,
    this.proofImages = const [],
    required this.createdAt,
  });

  factory ProductReturn.fromJson(Map<String, dynamic> json) {
    return ProductReturn(
      id: json['id'] as String,
      returnNumber: json['returnNumber'] as String? ?? 'RET-000',
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String? ?? '',
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ReturnItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reason: _parseReason(json['reason'] as String?),
      reasonDetails: json['reasonDetails'] as String?,
      status: _parseStatus(json['status'] as String?),
      refundAmount: (json['refundAmount'] as num? ?? 0).toDouble(),
      proofImages: (json['proofImages'] as List<dynamic>?)
              ?.map((e) => UrlUtils.fixLocalhost(e.toString()))
              .toList()
              .cast<String>() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  static ReturnReason _parseReason(String? reason) {
    switch (reason) {
      case 'defective': return ReturnReason.defective;
      case 'wrong_item': return ReturnReason.wrong_item;
      case 'not_satisfied': return ReturnReason.not_satisfied;
      case 'damaged': return ReturnReason.damaged;
      case 'expired': return ReturnReason.expired;
      default: return ReturnReason.other;
    }
  }

  static ReturnStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved': return ReturnStatus.approved;
      case 'rejected': return ReturnStatus.rejected;
      case 'refunded': return ReturnStatus.refunded;
      case 'exchanged': return ReturnStatus.exchanged;
      default: return ReturnStatus.pending;
    }
  }
}

class ReturnItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String condition;

  ReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.condition,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num? ?? 0).toDouble(),
      condition: json['condition'] as String? ?? 'used',
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'condition': condition,
  };
}
