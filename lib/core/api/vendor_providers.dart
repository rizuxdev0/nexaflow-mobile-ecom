import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/models/vendor.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';

final vendorServiceProvider = Provider((ref) => VendorService(ref.watch(apiClientProvider)));

final myVendorRequestsProvider = FutureProvider<List<VendorApplication>>((ref) async {
  return ref.watch(vendorServiceProvider).getMyRequests();
});

class VendorService {
  final ApiClient _api;
  VendorService(this._api);

  Future<List<VendorApplication>> getMyRequests() async {
    final response = await _api.get('/vendor-requests/my');
    if (response.data is List) {
      return (response.data as List).map((e) => VendorApplication.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createVendor(Map<String, dynamic> data) async {
    await _api.post('/vendor-requests', data: data);
  }
}
