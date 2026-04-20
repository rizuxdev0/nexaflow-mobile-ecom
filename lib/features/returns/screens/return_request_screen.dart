import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/return_providers.dart';
import '../../../core/models/models.dart';
import '../../../core/models/returns.dart';

class ReturnRequestScreen extends ConsumerStatefulWidget {
  final Order order;

  const ReturnRequestScreen({super.key, required this.order});

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _reasonDetailsController = TextEditingController();
  ReturnReason _selectedReason = ReturnReason.defective;
  final List<String> _selectedItemIds = [];
  final List<XFile> _proofImages = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _reasonDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _proofImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _proofImages.removeAt(index);
    });
  }

  double get _estimatedRefund {
    double total = 0;
    for (final itemId in _selectedItemIds) {
      final item = widget.order.items.firstWhere((i) => i.id == itemId || i.productId == itemId);
      total += item.total;
    }
    return total;
  }

  Future<void> _submitRequest() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un article.')),
      );
      return;
    }

    if (_reasonDetailsController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez donner plus de détails sur le motif.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final returnItems = widget.order.items
          .where((i) => _selectedItemIds.contains(i.id) || _selectedItemIds.contains(i.productId))
          .map((i) => ReturnItem(
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                condition: 'used',
              ))
          .toList();

      await ref.read(returnRequestServiceProvider).createReturn(
            orderId: widget.order.id,
            orderNumber: widget.order.orderNumber,
            items: returnItems,
            reason: _selectedReason,
            reasonDetails: _reasonDetailsController.text,
            refundAmount: _estimatedRefund,
            images: _proofImages.map((f) => f.path).toList(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre demande de retour a été envoyée !')),
        );
        ref.invalidate(returnHistoryProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarer un Problème'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande #${widget.order.orderNumber}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            
            Text('Articles concernés', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...widget.order.items.map((item) {
              final id = item.id.isNotEmpty ? item.id : item.productId;
              final isSelected = _selectedItemIds.contains(id);
              return CheckboxListTile(
                value: isSelected,
                title: Text(item.productName),
                subtitle: Text('Qté: ${item.quantity} • ${(item.total).toStringAsFixed(0)} FCFA'),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedItemIds.add(id);
                    } else {
                      _selectedItemIds.remove(id);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primaryColor,
              );
            }),

            const SizedBox(height: 24),
            Text('Motif du retour', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReturnReason>(
              value: _selectedReason,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: ReturnReason.values.map((r) {
                return DropdownMenuItem(value: r, child: Text(r.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),

            const SizedBox(height: 24),
            Text('Détails du problème', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonDetailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Expliquez-nous ce qui ne va pas...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            Text('Preuves (Photos)', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildImagePicker(),

            const SizedBox(height: 32),
            if (_selectedItemIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remboursement estimé', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_estimatedRefund.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Soumettre ma demande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_proofImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _proofImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_proofImages[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_proofImages.isNotEmpty) const SizedBox(height: 12),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text('Ajouter des photos de preuve', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
