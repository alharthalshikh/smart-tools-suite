import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class _Preset {
  final String id;
  final String title;
  final int width;
  final int height;
  final int quality;
  _Preset(this.id, this.title, this.width, this.height, this.quality);
}

class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  static final List<_Preset> _presets = [
    _Preset('instagram', 'Instagram (1080×1080)', 1080, 1080, 90),
    _Preset('facebook', 'Facebook (1200×630)', 1200, 630, 90),
    _Preset('whatsapp', 'WhatsApp (1600×900)', 1600, 900, 90),
    _Preset('twitter', 'Twitter/X (1600×900)', 1600, 900, 90),
    _Preset('linkedin', 'LinkedIn (1200×627)', 1200, 627, 90),
  ];

  List<File> _files = [];
  int _presetIndex = 0;
  bool _busy = false;
  String? _error;
  String? _success;
  List<String> _tempPaths = [];

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

  Future<void> _optimize() async {
    setState(() { _busy = true; _error = null; _success = null; _tempPaths = []; });
    try {
      final preset = _presets[_presetIndex];
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < _files.length; i++) {
        final baseName = _files[i].path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
        final outPath = '${tempDir.path}/${baseName}_${preset.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await FlutterImageCompress.compressAndGetFile(
          _files[i].absolute.path,
          outPath,
          quality: preset.quality,
          minWidth: preset.width,
          minHeight: preset.height,
        );
        _tempPaths.add(outPath);
      }

      setState(() => _success = 'تم تحسين ${_files.length} صورة بنجاح! جاهزة للحفظ.');
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
        dialogTitle: 'اختر مجلدًا لحفظ الصور المحسنة فيه',
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
          _success = 'تم حفظ جميع الصور المحسنة في المجلد المختار بنجاح ✓';
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
      appBar: AppBar(title: const Text('تحسين السوشيال')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'تحسين الصور للسوشيال',
            subtitle: 'ضغط ذكي + إعدادات جاهزة للمنصات. كل شيء محلي.',
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: FilePickerButton(
              title: 'اختر الصور',
              subtitle: 'PNG / JPG / WEBP',
              icon: Icons.auto_awesome_rounded,
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
                          const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary),
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
                        color: AppTheme.primary.withValues(alpha: 0.05),
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
          // Preset Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المنصة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._presets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final active = i == _presetIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _presetIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary.withValues(alpha: 0.15) : (isDark ? const Color(0xFF111827) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppTheme.primary : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(p.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppTheme.primary : null))),
                          if (active) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
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
                    onPressed: (_files.isNotEmpty && !_busy) ? _optimize : null,
                    child: Text(_busy ? 'جاري التحسين...' : 'بدء التحسين'),
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

          // Info
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
                  const Text('ماذا يفعل هذا؟', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    '• يضغط الصورة لتصير مناسبة للنشر.\n• يحاول الحفاظ على الجودة قدر الإمكان.\n• بإمكانك اختيار منصة مختلفة حسب المقاس.',
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
