// lib/presentation/features/transactions/widgets/payment_proof_picker.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';


/// 📎 Sélecteur de preuve de paiement (capture d'écran Mobile Money).
///
/// Permet de sélectionner une image depuis la galerie ou l'appareil photo.
/// Affiche l'image avec un flou artistique et un bouton de remplacement.
class PaymentProofPicker extends StatefulWidget {
  final Function(File? imageFile) onImageSelected;

  const PaymentProofPicker({super.key, required this.onImageSelected});

  @override
  State<PaymentProofPicker> createState() => _PaymentProofPickerState();
}

class _PaymentProofPickerState extends State<PaymentProofPicker> {
  static const String tag = 'PaymentProofPicker';
  final Logger _logger = Logger();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    const method = '_pickImage';
    _logger.i('$tag.$method - Sélection image depuis ${source == ImageSource.gallery ? 'galerie' : 'caméra'}.');
    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75, // Compression pour économiser espace
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        widget.onImageSelected(_selectedImage);
        _logger.i('$tag.$method - Image sélectionnée: ${image.path}');
      } else {
        _logger.i('$tag.$method - Aucune image sélectionnée.');
      }
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      _showError('Impossible de sélectionner l\'image.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.riskRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearImage() {
    const method = '_clearImage';
    _logger.i('$tag.$method - Image effacée.');
    setState(() => _selectedImage = null);
    widget.onImageSelected(null);
  }

  Future<void> _showSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDeepBlue.withOpacity(0.9),
        title: const Text('Ajouter une preuve', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sélectionnez la capture d\'écran de votre confirmation Mobile Money.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galerie', style: TextStyle(color: AppColors.accentTeal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Appareil photo', style: TextStyle(color: AppColors.accentTeal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
    if (source != null) {
      await _pickImage(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectedImage == null ? _showSourceDialog : null,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentTeal.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          color: Colors.white.withOpacity(0.05),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedImage == null
                ? _buildEmptyState()
                : _buildImagePreview(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.accentTeal.withOpacity(0.7)),
        const SizedBox(height: 12),
        const Text(
          'Appuyez pour ajouter la capture',
          style: TextStyle(color: Colors.white70),
        ),
        const Text(
          'd\'écran Mobile Money',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image en arrière-plan avec flou
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
          ),
        ),
        // Overlay flou et bouton
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.solvencyGreen, size: 40),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showSourceDialog,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Changer la preuve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeepBlue.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearImage,
                      child: const Text('Supprimer', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}