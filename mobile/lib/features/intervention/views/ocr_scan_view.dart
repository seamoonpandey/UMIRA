import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/umira_card.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../preferences/providers/preferences_provider.dart';
import '../data/intervention_repository.dart';

class OcrScanView extends ConsumerStatefulWidget {
  const OcrScanView({super.key});

  @override
  ConsumerState<OcrScanView> createState() => _OcrScanViewState();
}

class _OcrScanViewState extends ConsumerState<OcrScanView> {
  final _picker = ImagePicker();
  File? _imageFile;
  String? _extractedText;
  bool _isProcessing = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 3072,
        maxHeight: 3072,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() {
          _imageFile = File(xFile.path);
          _extractedText = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not open camera or gallery: $e');
      }
    }
  }

  Future<void> _scanText() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final repo = ref.read(interventionRepoProvider);
      final text = await repo.performOcr(_imageFile!.path);

      if (mounted) {
        setState(() {
          _extractedText = text;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'OCR failed: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _extractedText = null;
      _error = null;
    });
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4CAF50),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo of the text'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose an image from your library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    final useDyslexic = prefs.useDyslexiaFont;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Text'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Text Scanner',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: useDyslexic ? 'Lexend' : null,
                  fontWeight: useDyslexic ? FontWeight.normal : FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan text from images or your camera',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: useDyslexic ? 'Lexend' : null,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Image preview area
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _imageFile!,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 280,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Choose another'),
                  onPressed: _showSourcePicker,
                ),
                const SizedBox(width: 12),
                if (!_isProcessing)
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Clear'),
                    onPressed: _clearImage,
                  ),
              ],
            ),
          ] else ...[
            // Empty state — prompt to pick
            UmiraCard(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showSourcePicker,
                child: Container(
                  height: 280,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to select an image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a photo or pick from gallery',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Error display
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UmiraCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scan button
          if (_imageFile != null && _extractedText == null)
            UmiraButton(
              label: _isProcessing ? 'Scanning...' : 'Scan Text',
              primary: true,
              icon: _isProcessing ? null : Icons.document_scanner,
              onPressed: _isProcessing ? null : _scanText,
            ),

          // Loading indicator
          if (_isProcessing) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Extracting text from image...'),
                ],
              ),
            ),
          ],

          // Results
          if (_extractedText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Text extracted successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            UmiraCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _extractedText!,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    fontFamily: useDyslexic ? 'Lexend' : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: UmiraButton(
                    label: 'Scan Again',
                    icon: Icons.refresh,
                    onPressed: _clearImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UmiraButton(
                    label: 'Copy Text',
                    primary: true,
                    icon: Icons.copy,
                    onPressed: () {
                      if (_extractedText != null) {
                        Clipboard.setData(
                          ClipboardData(text: _extractedText!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Text copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
