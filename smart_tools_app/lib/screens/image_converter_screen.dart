import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  List<File> _files = [];
  String _outFormat = 'webp';
  double _quality = 90; // 0–100
  bool _busy = false;
  String? _error;
  String? _success;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() {
      _error = null;
      _success = null;
      _files.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  List<String> _tempPaths = [];

  Future<void> _convert() async {
    setState(() { _busy = true; _error = null; _success = null; _tempPaths = []; });
    try {
      final tempDir = await getTemporaryDirectory();
      
      for (int i = 0; i < _files.length; i++) {
        Uint8List encoded;
        String ext;

        if (_outFormat == 'webp') {
          // Use flutter_image_compress for WebP as 'image' package only supports decoding
          final result = await FlutterImageCompress.compressWithFile(
            _files[i].absolute.path,
            quality: _quality.round(),
            format: CompressFormat.webp,
          );
          if (result == null) throw Exception('فشل تحويل الصورة لـ WebP');
          encoded = result;
          ext = 'webp';
        } else {
          final bytes = await _files[i].readAsBytes();
          final decoded = img.decodeImage(bytes);
          if (decoded == null) throw Exception('فشل تحميل الصورة: ${_files[i].path.split('/').last}');

          switch (_outFormat) {
            case 'png':
              encoded = Uint8List.fromList(img.encodePng(decoded));
              ext = 'png';
              break;
            case 'jpg':
              encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: _quality.round()));
              ext = 'jpg';
              break;
            default:
              encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: _quality.round()));
              ext = 'jpg';
              break;
          }
        }

        final baseName = _files[i].path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
        final outPath = '${tempDir.path}/${baseName}_converted_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(outPath).writeAsBytes(encoded);
        _tempPaths.add(outPath);
      }

      setState(() => _success = 'تم تجهيز تحويل ${_files.length} صورة بنجاح! اضغط أدناه لحفظهم في جهازك.');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveToDownloads() async {
    if (_tempPaths.isEmpty) return;
    setState(() { _error = null; _success = null; _busy = true; });

    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلدًا لحفظ الصور المحولة فيه',
      );

      if (folderPath != null) {
        for (final p in _tempPaths) {
          final originalName = p.split('/').last;
          final lastDot = originalName.lastIndexOf('.');
          final baseName = lastDot != -1 ? originalName.substring(0, lastDot) : originalName;
          final ext = lastDot != -1 ? originalName.substring(lastDot + 1) : '';

          String finalName = originalName;
          int counter = 1;
          while (await File('$folderPath/$finalName').exists()) {
            finalName = '${baseName}_$counter.$ext';
            counter++;
          }

          final bytes = await File(p).readAsBytes();
          await File('$folderPath/$finalName').writeAsBytes(bytes);
        }
        setState(() {
          _success = 'تم حفظ جميع الصور في المجلد المختار بنجاح ✓';
          _tempPaths = [];
        });
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ. التفاصيل: $e');
    } finally {
      setState(() => _busy = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('تحويل الصور')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'تحويل الصور',
            subtitle: 'حوّل صورك (PNG/JPG/WebP) على جهازك بجودة عالية.',
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: FilePickerButton(
              title: 'اسحب الصور هنا',
              subtitle: 'PNG / JPG / WEBP',
              icon: Icons.image_rounded,
              onTap: _pickImages,
            ),
          ),

          if (_files.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ...List.generate(_files.length, (index) {
                    final f = _files[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: index == _files.length - 1 ? null : Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _removeFile(index),
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.destructive),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f.path.split('/').last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                          Text('${(f.lengthSync() / 1024).round()} KB', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                          const SizedBox(width: 8),
                          const Icon(Icons.image_outlined, size: 18, color: AppTheme.primary),
                        ],
                      ),
                    );
                  }),
                  InkWell(
                    onTap: _pickImages,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('إضافة المزيد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Format and Quality
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الصيغة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _outFormat,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'webp', child: Text('WEBP')),
                          DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                          DropdownMenuItem(value: 'png', child: Text('PNG')),
                        ],
                        onChanged: (v) => setState(() => _outFormat = v ?? 'webp'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الجودة (${_quality.round()}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      Slider(
                        value: _quality,
                        min: 10,
                        max: 100,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _quality = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_files.isNotEmpty && !_busy) ? _convert : null,
                    child: Text(_busy ? 'جاري التحويل...' : 'بدء التحويل'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => setState(() { _files = []; _error = null; _success = null; _tempPaths = []; }),
                  child: const Text('مسح'),
                ),
              ],
            ),
          ),

          if (_error != null) StatusBanner(message: _error!, isError: true),
          if (_success != null) 
            StatusBanner(
              message: _success!,
              actionLabel: _tempPaths.isNotEmpty ? 'حفظ في الجهاز' : null,
              onAction: _tempPaths.isNotEmpty ? _saveToDownloads : null,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تنبيهات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'عملية التحويل تتم بالكامل على جهازك بشكل آمن وسريع.\nالصور ذات الأحجام الكبيرة قد تستغرق بضع ثوانٍ إضافية.',
                    style: TextStyle(fontSize: 12, height: 1.7, color: isDark ? Colors.white38 : Colors.black45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
