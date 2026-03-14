import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class BgRemoverScreen extends StatefulWidget {
  const BgRemoverScreen({super.key});

  @override
  State<BgRemoverScreen> createState() => _BgRemoverScreenState();
}

class _BgRemoverScreenState extends State<BgRemoverScreen> {
  File? _image;
  Uint8List? _processedImage;
  bool _processing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
        _processedImage = null;
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_image == null) return;
    setState(() => _processing = true);

    try {
      final inputImage = InputImage.fromFile(_image!);
      final segmenter = SelfieSegmenter();
      
      // 1. Get the segmentation mask
      final mask = await segmenter.processImage(inputImage);
      if (mask == null) throw Exception("Could not generate mask");

      // 2. Process the image bytes
      final imageBytes = await _image!.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) throw Exception("Could not decode image");

      final width = mask.width;
      final height = mask.height;
      final confidences = mask.confidences;

      // Create a copy of the image to manipulate (with Alpha channel)
      final resultImg = img.Image(width: decodedImage.width, height: decodedImage.height, numChannels: 4);

      // Resizing mask-based logic or direct pixel manipulation
      // For simplicity and speed in this version, we'll iterate and apply mask
      for (int y = 0; y < decodedImage.height; y++) {
        for (int x = 0; x < decodedImage.width; x++) {
          final pixel = decodedImage.getPixel(x, y);
          
          // Map image pixel to mask confidence (basic nearest neighbor scaling)
          final mx = (x * width / decodedImage.width).floor();
          final my = (y * height / decodedImage.height).floor();
          final confidence = confidences[my * width + mx];

          if (confidence > 0.7) { // Threshold for foreground
            resultImg.setPixel(x, y, pixel);
          } else {
            resultImg.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0)); // Transparent
          }
        }
      }

      // 3. Encode to PNG
      final pngBytes = Uint8List.fromList(img.encodePng(resultImg));
      
      setState(() {
        _processedImage = pngBytes;
      });

      await segmenter.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المعالجة: $e')),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;
    
    setState(() => _processing = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImageBytes(_processedImage!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الصورة في الاستوديو بنجاح! 🖼️')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إزالة خلفية الصورة')),
      body: Column(
        children: [
          GradientHeroSection(
            title: 'إزالة الخلفية الذكية',
            subtitle: 'معالجة محلية 100% للحفاظ على خصوصيتك.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: _processedImage != null
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(_processedImage!),
                        ),
                      )
                    : _image == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_search_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              const Text('اختر صورة للبدء بالقص التلقائي', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(_image!),
                          ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('تبديل الصورة'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_image != null && _processedImage == null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : _removeBackground,
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(_processing ? 'جاري القص...' : 'حذف الخلفية'),
                    ),
                  ),
                if (_processedImage != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : _saveImage,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.download_for_offline_rounded),
                      label: Text(_processing ? 'جاري الحفظ...' : 'حفظ في الاستوديو'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
