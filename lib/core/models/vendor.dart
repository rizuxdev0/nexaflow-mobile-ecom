import 'models.dart';

class VendorApplication {
  final String id;
  final String storeName;
  final String email;
  final String phone;
  final String? description;
  final String? address;
  final String? city;
  final String country;
  final String contactPerson;
  final String status; // pending, approved, rejected
  final String? adminNotes;
  final String createdAt;

  VendorApplication({
    required this.id,
    required this.storeName,
    required this.email,
    required this.phone,
    this.description,
    this.address,
    this.city,
    required this.country,
    required this.contactPerson,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory VendorApplication.fromJson(Map<String, dynamic> json) {
    return VendorApplication(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      storeName: json['name'] as String? ?? json['storeName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'Sénégal',
      contactPerson: json['contactPerson'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
