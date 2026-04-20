import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/returns.dart';
import '../../features/auth/providers/auth_provider.dart';

final returnHistoryProvider = FutureProvider<List<ProductReturn>>((ref) async {
  final api = ApiClient();
  final auth = ref.watch(authProvider);
  final customerId = auth.customer?.id;
  
  if (customerId == null) return [];

  try {
    // Note: The backend typically uses /shop/returns or similar for customer returns
    final response = await api.get('/shop/returns');
    final rawData = response.data;
    
    List<dynamic> list = [];
    if (rawData is Map) {
      final content = rawData['data'];
      if (content is List) {
        list = content;
      } else if (content is Map && content['data'] is List) {
        list = content['data'] as List<dynamic>;
      }
    } else if (rawData is List) {
      list = rawData;
    }

    return list.map((e) => ProductReturn.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement historiques retours: $e");
    return [];
  }
});

class ReturnRequestService {
  final ApiClient _api = ApiClient();

  Future<ProductReturn> createReturn({
    required String orderId,
    required String orderNumber,
    required List<ReturnItem> items,
    required ReturnReason reason,
    String? reasonDetails,
    double refundAmount = 0,
    List<String> images = const [], // File paths
  }) async {
    // If we have images, we might need to upload them first or use FormData
    dynamic data;
    
    if (images.isNotEmpty) {
      final formData = FormData.fromMap({
        'orderId': orderId,
        'orderNumber': orderNumber,
        'reason': reason.name,
        'reasonDetails': reasonDetails,
        'refundAmount': refundAmount,
        'items': items.map((e) => e.toJson()).toList(),
      });

      for (var i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'proofs',
          await MultipartFile.fromFile(images[i], filename: 'proof_$i.jpg'),
        ));
      }
      data = formData;
    } else {
      data = {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'reason': reason.name,
        'reasonDetails': reasonDetails,
        'refundAmount': refundAmount,
      };
    }

    final response = await _api.post('/shop/returns', data: data);
    final resData = response.data;
    final json = resData is Map ? (resData['data'] ?? resData) : resData;
    return ProductReturn.fromJson(json as Map<String, dynamic>);
  }
}

final returnRequestServiceProvider = Provider((ref) => ReturnRequestService());
