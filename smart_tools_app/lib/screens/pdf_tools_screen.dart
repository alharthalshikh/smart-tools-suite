import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

enum PdfToolId {
  merge, split, rotate, delete, watermark,
  excelToPdf, wordToPdf, pdfToJpg, jpgToPdf
}

class PdfToolMeta {
  final String title;
  final String description;
  final String icon;
  PdfToolMeta(this.title, this.description, this.icon);
}

final Map<PdfToolId, PdfToolMeta> pdfToolMeta = {
  PdfToolId.merge: PdfToolMeta('دمج ملفات PDF', 'اجمع عدة ملفات في ملف واحد مرتب', '⧉'),
  PdfToolId.split: PdfToolMeta('تقسيم PDF', 'استخرج نطاق صفحات (مثل 1-5)', '✂'),
  PdfToolId.rotate: PdfToolMeta('تدوير الصفحات', 'تدوير 90°/180°/270° لإصلاح الاتجاه', '⟳'),
  PdfToolId.delete: PdfToolMeta('حذف صفحات', 'احذف صفحات محددة بسرعة', '🗑'),
  PdfToolId.watermark: PdfToolMeta('علامة مائية', 'أضف نص علامة مائية داخل كل صفحة', '⛨'),
  PdfToolId.excelToPdf: PdfToolMeta('إكسل إلى PDF', 'حول جداول Excel إلى ملفات PDF مرتبة', '📑'),
  PdfToolId.wordToPdf: PdfToolMeta('وورد إلى PDF', 'حول ملفات Word (docx) إلى PDF نصي', '📝'),
  PdfToolId.pdfToJpg: PdfToolMeta('PDF إلى صور (JPG)', 'حول صفحات ملف PDF إلى صور منفصلة', '🖼'),
  PdfToolId.jpgToPdf: PdfToolMeta('صور إلى PDF', 'حول مجموعة صور إلى ملف PDF واحد', '📄'),
};

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  PdfToolId _activeTool = PdfToolId.merge;
  List<File> _pickedFiles = [];
  bool _busy = false;
  String? _error;
  String? _success;
  String _statusText = '';
  List<String> _tempPaths = [];

  // Split settings
  int _splitFrom = 1;
  int _splitTo = 1;
  int? _pageCount;

  // Rotate settings
  int _rotation = 90;

  // Delete settings
  String _deleteMode = 'list';
  String _pagesToDelete = '2, 3';
  int _deleteFrom = 1;
  int _deleteTo = 1;

  // Watermark
  String _watermarkText = 'نسخة تجريبية';

  String get _filePickerLabel {
    switch (_activeTool) {
      case PdfToolId.excelToPdf: return 'اختر ملف Excel';
      case PdfToolId.wordToPdf: return 'اختر ملف Word';
      case PdfToolId.jpgToPdf: return 'اختر صور';
      default: return _activeTool == PdfToolId.merge ? 'اختر ملفات PDF' : 'اختر ملف PDF';
    }
  }

  List<String> get _allowedExtensions {
    switch (_activeTool) {
      case PdfToolId.excelToPdf: return ['xlsx', 'xls'];
      case PdfToolId.wordToPdf: return ['docx'];
      case PdfToolId.jpgToPdf: return ['jpg', 'jpeg', 'png', 'webp'];
      default: return ['pdf'];
    }
  }

  bool get _canRun {
    switch (_activeTool) {
      case PdfToolId.merge: return _pickedFiles.length >= 2;
      case PdfToolId.jpgToPdf: return _pickedFiles.isNotEmpty;
      default: return _pickedFiles.length == 1;
    }
  }

  Future<void> _pickFiles() async {
    if (_busy) return;
    
    try {
      FileType type = FileType.custom;
      List<String>? extensions = _allowedExtensions;

      if (_activeTool == PdfToolId.jpgToPdf) {
        type = FileType.image;
        extensions = null; // Important: FileType.image doesn't allow extensions
      }

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: extensions,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _error = null;
          _success = null;
          // For tools that only support one file, replace the list
          if (_activeTool != PdfToolId.merge && _activeTool != PdfToolId.jpgToPdf) {
            _pickedFiles = result.paths.where((p) => p != null).map((p) => File(p!)).toList();
          } else {
            _pickedFiles.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
          }
          _updatePageCount();
        });
      }
    } catch (e) {
      setState(() => _error = 'فشل اختيار الملفات: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
      if (_pickedFiles.isEmpty) {
        _pageCount = null;
      } else {
        _updatePageCount();
      }
    });
  }

  Future<void> _updatePageCount() async {
    if (_pickedFiles.length == 1 && _allowedExtensions.contains('pdf')) {
      try {
        final bytes = await _pickedFiles.first.readAsBytes();
        // Simple PDF page count from raw bytes
        final content = String.fromCharCodes(bytes);
        final matches = RegExp(r'/Type\s*/Page[^s]').allMatches(content);
        final count = matches.length;
        if (count > 0) {
          setState(() {
            _pageCount = count;
            _splitTo = count;
          });
        }
      } catch (_) {}
    }
  }

  void _reset() {
    setState(() {
      _pickedFiles = [];
      _error = null;
      _success = null;
      _pageCount = null;
      _tempPaths = [];
    });
  }

  Future<void> _runTool() async {
    setState(() { _busy = true; _error = null; _success = null; });
    try {
      if (!_canRun) throw Exception('اختر ملفات مناسبة للأداة أولاً');

      switch (_activeTool) {
        case PdfToolId.jpgToPdf:
          await _convertJpgToPdf();
          break;
        case PdfToolId.merge:
          await _mergePdfs();
          break;
        case PdfToolId.split:
          await _splitPdf();
          break;
        case PdfToolId.rotate:
          await _rotatePdf();
          break;
        case PdfToolId.delete:
          await _deletePages();
          break;
        case PdfToolId.watermark:
          await _addWatermark();
          break;
        case PdfToolId.pdfToJpg:
          await _pdfToJpg();
          break;
        default:
          throw Exception('هذه الأداة غير متاحة حاليًا على الجوال');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() { _busy = false; _statusText = ''; });
    }
  }

  Future<void> _mergePdfs() async {
    final pdf = pw.Document();
    for (final file in _pickedFiles) {
      final bytes = await file.readAsBytes();
      // Using a lower DPI (72) to prevent memory crashes on large PDFs
      await for (final page in Printing.raster(bytes, dpi: 72)) {
        final image = await page.toPng();
        final memImage = pw.MemoryImage(image);
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
          build: (context) => pw.Center(child: pw.Image(memImage)),
        ));
      }
    }
    await _savePdf(pdf, 'merged.pdf');
  }

  Future<void> _splitPdf() async {
    final bytes = await _pickedFiles.first.readAsBytes();
    final pdf = pw.Document();
    int pageIndex = 0;
    await for (final page in Printing.raster(bytes, dpi: 72)) {
      pageIndex++;
      if (pageIndex >= _splitFrom && pageIndex <= _splitTo) {
        final image = await page.toPng();
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
          build: (context) => pw.Center(child: pw.Image(pw.MemoryImage(image))),
        ));
      }
    }
    await _savePdf(pdf, 'split.pdf');
  }

  Future<void> _rotatePdf() async {
    final bytes = await _pickedFiles.first.readAsBytes();
    final pdf = pw.Document();
    await for (final page in Printing.raster(bytes, dpi: 72)) {
      final image = await page.toPng();
      final decoded = img.decodeImage(image);
      if (decoded == null) continue;
      final rotated = img.copyRotate(decoded, angle: _rotation);
      final rotatedPng = Uint8List.fromList(img.encodePng(rotated));
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(rotated.width.toDouble(), rotated.height.toDouble()),
        build: (context) => pw.Center(child: pw.Image(pw.MemoryImage(rotatedPng))),
      ));
    }
    await _savePdf(pdf, 'rotated-$_rotation.pdf');
  }

  Future<void> _deletePages() async {
    Set<int> pagesToRemove = {};
    if (_deleteMode == 'list') {
      pagesToRemove = _pagesToDelete
          .split(RegExp(r'[,\s]+'))
          .map((s) => int.tryParse(s.trim()))
          .where((n) => n != null && n > 0)
          .map((n) => n!)
          .toSet();
      if (pagesToRemove.isEmpty) throw Exception('اكتب أرقام الصفحات المراد حذفها');
    } else {
      final from = _deleteFrom < _deleteTo ? _deleteFrom : _deleteTo;
      final to = _deleteFrom > _deleteTo ? _deleteFrom : _deleteTo;
      for (int i = from; i <= to; i++) {
        pagesToRemove.add(i);
      }
    }

    final bytes = await _pickedFiles.first.readAsBytes();
    final pdf = pw.Document();
    int pageIndex = 0;
    await for (final page in Printing.raster(bytes, dpi: 92)) {
      pageIndex++;
      if (!pagesToRemove.contains(pageIndex)) {
        final image = await page.toPng();
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
          build: (context) => pw.Center(child: pw.Image(pw.MemoryImage(image))),
        ));
      }
    }
    await _savePdf(pdf, 'deleted-pages.pdf');
  }

  Future<void> _addWatermark() async {
    if (_watermarkText.trim().isEmpty) throw Exception('اكتب نص العلامة المائية');
    final bytes = await _pickedFiles.first.readAsBytes();
    final pdf = pw.Document();
    await for (final page in Printing.raster(bytes, dpi: 72)) {
      final image = await page.toPng();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
        build: (context) => pw.Stack(children: [
          pw.Center(child: pw.Image(pw.MemoryImage(image))),
          pw.Center(
            child: pw.Transform.rotate(
              angle: -0.4,
              child: pw.Text(
                _watermarkText.trim(),
                style: pw.TextStyle(
                  fontSize: 48,
                  color: PdfColor.fromInt(0x26000000),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ]),
      ));
    }
    await _savePdf(pdf, 'watermark.pdf');
  }

  Future<void> _pdfToJpg() async {
    final bytes = await _pickedFiles.first.readAsBytes();
    final dir = await getTemporaryDirectory();
    final List<String> paths = [];
    int pageIndex = 0;
    setState(() => _statusText = 'جاري تحويل الصفحات...');
    await for (final page in Printing.raster(bytes, dpi: 100)) {
      pageIndex++;
      setState(() => _statusText = 'جاري تحويل صفحة $pageIndex...');
      final png = await page.toPng();
      final path = '${dir.path}/page_$pageIndex.png';
      await File(path).writeAsBytes(png);
      paths.add(path);
    }
    if (paths.isNotEmpty) {
      setState(() {
        _tempPaths = paths;
        _success = 'تم تجهيز تحويل صفحات PDF إلى صور بنجاح! جاهزة للحفظ.';
      });
    }
  }

  Future<void> _saveResultToDownloads() async {
    if (_tempPaths.isEmpty) return;
    
    setState(() { _error = null; _success = null; _busy = true; });

    try {
      String? folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلدًا لحفظ الملفات فيه',
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
          _success = 'تم حفظ جميع الملفات بنجاح في: $folderPath ✓';
          _tempPaths = [];
        });
      }
    } catch (e) {
      setState(() => _error = 'فشل الحفظ: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _convertJpgToPdf() async {
    setState(() => _statusText = 'جاري تجميع الصور...');
    final pdf = pw.Document();
    for (int i = 0; i < _pickedFiles.length; i++) {
        setState(() => _statusText = 'جاري إضافة صورة ${i + 1} من ${_pickedFiles.length}...');
        final bytes = await _pickedFiles[i].readAsBytes();
        
        // Optional: Resize image if too large to prevent OOM
        // final image = img.decodeImage(bytes);
        // ...
        
        final pdfImage = pw.MemoryImage(bytes);
        pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
        ));
        // Add a tiny delay to allow garbage collection between huge images
        await Future.delayed(const Duration(milliseconds: 50));
    }
    await _savePdf(pdf, 'images-converted.pdf');
  }

  Future<pw.Document?> _loadSelectedPdf() async {
    if (_pickedFiles.isEmpty) return null;
    try {
      final bytes = await _pickedFiles.first.readAsBytes();
      return pw.Document()..addPage(pw.Page(build: (c) => pw.Center(child: pw.Text('PDF Content Placeholder')))); 
      // This is a placeholder, actual tools should load and manipulate.
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePdf(pw.Document pdf, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final baseName = filename.split('.').first;
    final ext = filename.split('.').last;
    
    String finalName = filename;
    int counter = 1;
    while (await File('${tempDir.path}/$finalName').exists()) {
      finalName = '${baseName}_$counter.$ext';
      counter++;
    }

    final path = '${tempDir.path}/$finalName';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    setState(() {
      _tempPaths = [path];
      _success = 'تمت العملية بنجاح! اضغط أدناه لاختيار مكان الحفظ في جهازك.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات PDF'),
      ),
      body: ListView(
        children: [
          // Hero
          GradientHeroSection(
            title: 'أدوات PDF مجانية واحترافية',
            subtitle: 'دمج، تقسيم، تدوير، حذف صفحات، وإضافة علامة مائية — كل ذلك يتم محليًا على جهازك.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'خصوصية 100%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success),
              ),
            ),
          ),

          // File Picker Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilePickerButton(
                  title: _filePickerLabel,
                  subtitle: _activeTool == PdfToolId.merge ? 'اختر ملفين أو أكثر للدمج' : 'اختر ملف واحد للتعديل',
                  icon: Icons.upload_file_rounded,
                  onTap: _pickFiles,
                ),
                if (_pickedFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الملفات المختارة (${_pickedFiles.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            GestureDetector(
                              onTap: _reset,
                              child: Text('مسح الكل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _pickedFiles.length,
                            separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                            itemBuilder: (context, index) {
                              final file = _pickedFiles[index];
                              final name = file.path.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.destructive),
                                      onPressed: () => _removeFile(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.insert_drive_file_outlined, size: 18, color: AppTheme.primary),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (_pickedFiles.isNotEmpty && (_activeTool == PdfToolId.merge || _activeTool == PdfToolId.jpgToPdf))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ActionButton(
                              title: 'إضافة ملفات أخرى',
                              icon: Icons.add_rounded,
                              onTap: _pickFiles,
                              isSecondary: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tools grid
          SectionWidget(
            title: 'الأدوات',
            subtitle: 'اختر الأداة التي تريدها ثم ارفع الملف/الملفات.',
            child: Column(
              children: pdfToolMeta.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ToolCardWidget(
                  title: e.value.title,
                  description: e.value.description,
                  icon: e.value.icon,
                  active: _activeTool == e.key,
                  onTap: () {
                    setState(() {
                      _activeTool = e.key;
                      _error = null;
                      _success = null;
                      if (e.key != PdfToolId.merge && e.key != PdfToolId.jpgToPdf && _pickedFiles.length > 1) {
                        _pickedFiles = [_pickedFiles.first];
                      }
                    });
                  },
                ),
              )).toList(),
            ),
          ),

          // Settings
          _buildSettings(isDark),

          // Status
          if (_error != null)
            StatusBanner(message: _error!, isError: true),
          if (_success != null)
            StatusBanner(
              message: _success!,
              actionLabel: _tempPaths.isNotEmpty ? 'حفظ في الجهاز' : null,
              onAction: _tempPaths.isNotEmpty ? _saveResultToDownloads : null,
            ),

          // Run Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canRun && !_busy) ? _runTool : null,
                child: Text(_busy ? (_statusText.isNotEmpty ? _statusText : 'جاري التنفيذ...') : 'تنفيذ'),
              ),
            ),
          ),

          // FAQ
          _buildFaq(isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettings(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const Text('إعدادات الأداة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('حسب الأداة المختارة', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45)),
            const SizedBox(height: 16),

            if (_activeTool == PdfToolId.split) ...[
              _buildNumberField('من صفحة', _splitFrom.toString(), (v) => setState(() => _splitFrom = int.tryParse(v) ?? 1)),
              const SizedBox(height: 10),
              _buildNumberField('إلى صفحة', _splitTo.toString(), (v) => setState(() => _splitTo = int.tryParse(v) ?? 1)),
              if (_pageCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('عدد صفحات الملف: $_pageCount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45)),
                ),
            ],

            if (_activeTool == PdfToolId.rotate) ...[
              const Text('درجة التدوير', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _rotation,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 90, child: Text('90°')),
                  DropdownMenuItem(value: 180, child: Text('180°')),
                  DropdownMenuItem(value: 270, child: Text('270°')),
                ],
                onChanged: (v) => setState(() => _rotation = v ?? 90),
              ),
            ],

            if (_activeTool == PdfToolId.delete) ...[
              // Mode selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeChip('صفحات محددة', _deleteMode == 'list', () => setState(() => _deleteMode = 'list'), isDark),
                    const SizedBox(width: 4),
                    _modeChip('نطاق (من-إلى)', _deleteMode == 'range', () => setState(() => _deleteMode = 'range'), isDark),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_deleteMode == 'list')
                _buildTextField('أرقام الصفحات للحذف', _pagesToDelete, 'مثال: 2, 3, 8', (v) => setState(() => _pagesToDelete = v))
              else ...[
                _buildNumberField('من صفحة', _deleteFrom.toString(), (v) => setState(() => _deleteFrom = int.tryParse(v) ?? 1)),
                const SizedBox(height: 10),
                _buildNumberField('إلى صفحة', _deleteTo.toString(), (v) => setState(() => _deleteTo = int.tryParse(v) ?? 1)),
              ],
              if (_pageCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('عدد الصفحات المتاحة: $_pageCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45)),
                ),
            ],

            if (_activeTool == PdfToolId.watermark)
              _buildTextField('نص العلامة المائية', _watermarkText, 'مثال: سري', (v) => setState(() => _watermarkText = v)),

            if (_activeTool == PdfToolId.merge)
              Text('ارفع ملفين أو أكثر، ثم اضغط تنفيذ.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),

            if (_activeTool == PdfToolId.jpgToPdf)
              Text('ارفع صورة أو أكثر ليتم تجميعها في ملف واحد.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? (isDark ? const Color(0xFF0A0F1A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppTheme.primary : (isDark ? Colors.white38 : Colors.black45),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, String hint, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildFaq(bool isDark) {
    return SectionWidget(
      title: 'الأسئلة الشائعة',
      subtitle: 'إجابات سريعة',
      child: Column(
        children: [
          _faqItem('هل ترفعون ملفاتي للسيرفر؟', 'لا. المعالجة تتم محليًا على جهازك.', isDark),
          const SizedBox(height: 8),
          _faqItem('هل الخدمة مجانية؟', 'نعم، مجانية بالكامل للاستخدام الشخصي.', isDark),
        ],
      ),
    );
  }

  Widget _faqItem(String q, String a, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(a, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
        ],
      ),
    );
  }
}
