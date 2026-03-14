import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class VideoConverterScreen extends StatefulWidget {
  const VideoConverterScreen({super.key});

  @override
  State<VideoConverterScreen> createState() => _VideoConverterScreenState();
}

class _VideoConverterScreenState extends State<VideoConverterScreen> {
  List<File> _videoFiles = [];
  String? _error;
  String? _success;
  bool _busy = false;
  List<String> _tempPaths = [];

  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _error = null;
      _success = null;
      _videoFiles.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
    });
  }

  void _removeFile(int index) {
    setState(() {
      _videoFiles.removeAt(index);
    });
  }

  Future<void> _convertAll() async {
    if (_videoFiles.isEmpty) return;
    setState(() { _busy = true; _error = null; _success = null; _tempPaths = []; });

    try {
      final tempDir = await getTemporaryDirectory();
      
      for (final videoFile in _videoFiles) {
        final baseName = videoFile.path.split('/').last.split('.').first;
        final outPath = '${tempDir.path}/${baseName}_${DateTime.now().millisecondsSinceEpoch}.mp3';

        final command = '-i "${videoFile.path}" -vn -acodec libmp3lame -q:a 2 "$outPath"';
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          _tempPaths.add(outPath);
        }
      }

      if (_tempPaths.isNotEmpty) {
        setState(() => _success = 'تم استخراج الصوت من ${_tempPaths.length} ملفات بنجاح! جاهزة للحفظ.');
      } else {
        throw Exception('فشل التحويل لجميع الملفات.');
      }
    } catch (e) {
      setState(() => _error = 'فشل التحويل: تأكد من صلاحية الملفات.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveAll() async {
    if (_tempPaths.isEmpty) return;
    setState(() { _busy = true; _error = null; _success = null; });

    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلدًا لحفظ الملفات الصوتية المستخرجة',
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
          _success = 'تم حفظ جميع الملفات الصوتية في المجلد المختار بنجاح ✓';
          _tempPaths = [];
        });
      }
    } catch (e) {
      setState(() => _error = 'فشل حفظ الملفات: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('فيديو إلى صوت')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'تحويل الفيديو إلى صوت',
            subtitle: 'استخراج الصوت من ملفات الفيديو بصيغة MP3 عالية الجودة.',
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FileDropzone(
                  onTap: _pickVideos,
                  title: 'اسحب ملفات الفيديو هنا',
                  subtitle: 'MP4, MKV, MOV وأكثر',
                  icon: Icons.video_call_outlined,
                ),

                  if (_videoFiles.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_videoFiles.length, (index) {
                            final f = _videoFiles[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: index == _videoFiles.length - 1 ? null : Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
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
                                    const SizedBox(width: 8),
                                    const Icon(Icons.movie_outlined, size: 18, color: AppTheme.primary),
                                  ],
                                ),
                            );
                          }),
                          InkWell(
                            onTap: _pickVideos,
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

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_videoFiles.isNotEmpty && !_busy) ? _convertAll : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_busy) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 10),
                        Text(_busy ? 'جاري التحويل...' : 'بدء استخراج الصوت من الكل'),
                      ],
                    ),
                  ),
                  if (_videoFiles.isNotEmpty && !_busy) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() { _videoFiles = []; _error = null; _success = null; _tempPaths = []; }),
                      child: const Text('مسح جميع الملفات', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),

          if (_error != null) StatusBanner(message: _error!, isError: true),
          if (_success != null) 
            StatusBanner(
              message: _success!,
              actionLabel: _tempPaths.isNotEmpty ? 'حفظ في الجهاز' : null,
              onAction: _tempPaths.isNotEmpty ? _saveAll : null,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لماذا هذه الأداة؟', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  _infoItem('خصوصية تامة: التحويل يتم بالكامل داخل جهازك.', isDark),
                  _infoItem('جودة عالية: نستخدم أفضل التقنيات لضمان استخراج الصوت بأعلى نقاء.', isDark),
                  _infoItem('سرعة فائقة: المعالجة فورية وتعتمد على قوة جهازك.', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 12)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.6, color: isDark ? Colors.white38 : Colors.black45))),
        ],
      ),
    );
  }
}
