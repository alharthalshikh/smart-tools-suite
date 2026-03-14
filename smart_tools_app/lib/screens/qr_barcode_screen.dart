import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class QrBarcodeScreen extends StatefulWidget {
  const QrBarcodeScreen({super.key});

  @override
  State<QrBarcodeScreen> createState() => _QrBarcodeScreenState();
}

class _QrBarcodeScreenState extends State<QrBarcodeScreen> {
  String _mode = 'qr';
  String _text = 'https://';
  double _qrSize = 250; // Fixed size for consistency
  Color _qrFg = const Color(0xFF0F6D7A);
  Color _qrFgSecondary = const Color(0xFF0F6D7A);
  bool _useGradient = false;
  Color _qrBg = const Color(0xFF0B1F3A);
  bool _qrTransparentBg = false;
  String _designPattern = 'traditional';
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataShape = QrDataModuleShape.square;
  bool _gapless = true;
  File? _logoFile;

  // Barcode settings
  String _barcodeFormat = 'CODE128';
  Color _barcodeLine = const Color(0xFF0F6D7A);
  Color _barcodeBg = const Color(0xFF0B1F3A);
  bool _barcodeTransparentBg = false;
  double _barcodeHeight = 100; // Fixed height for consistency

  String? _error;
  bool _busy = false;

  final GlobalKey _qrKey = GlobalKey();
  final GlobalKey _barcodeKey = GlobalKey();

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Teal', 'color': const Color(0xFF0F6D7A)},
    {'name': 'Navy', 'color': const Color(0xFF0B1F3A)},
    {'name': 'Black', 'color': const Color(0xFF111827)},
    {'name': 'Blue', 'color': const Color(0xFF2563EB)},
    {'name': 'Green', 'color': const Color(0xFF16A34A)},
    {'name': 'Red', 'color': const Color(0xFFDC2626)},
    {'name': 'Purple', 'color': const Color(0xFF7C3AED)},
    {'name': 'Pink', 'color': const Color(0xFFDB2777)},
    {'name': 'White', 'color': const Color(0xFFFFFFFF)},
    {'name': 'Amber', 'color': const Color(0xFFF59E0B)},
  ];

  String? _tempPath;
  String? _success;

  Future<void> _downloadQr() async {
    setState(() { _busy = true; _error = null; _success = null; _tempPath = null; });
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('QR غير جاهز');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('فشل التصدير');
      final bytes = byteData.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      
      setState(() { 
        _tempPath = path; 
        _success = 'تم توليد QR بنجاح! اضغط أدناه لحفظه في جهازك.'; 
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _downloadBarcode() async {
    setState(() { _busy = true; _error = null; _success = null; _tempPath = null; });
    try {
      final boundary = _barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Barcode غير جاهز');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('فشل التصدير');
      final bytes = byteData.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      setState(() { 
        _tempPath = path; 
        _success = 'تم توليد الباركود بنجاح! اضغط أدناه لحفظه في جهازك.'; 
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _logoFile = File(result.files.single.path!));
    }
  }

  void _pickCustomColor(Color current, Function(Color) onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = current;
        return AlertDialog(
          title: const Text('اختر لوناً مخصصاً', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: current,
              onColorChanged: (c) => tempColor = c,
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                onSelected(tempColor);
                Navigator.pop(context);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToDownloads() async {
    if (_tempPath == null) return;
    setState(() { _error = null; _success = null; _busy = true; });

    try {
      final fileName = _tempPath!.split('/').last;
      final bytes = await File(_tempPath!).readAsBytes();

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ الكود',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputPath != null) {
        setState(() {
          _success = 'تم حفظ الكود بنجاح ✓';
          _tempPath = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ. التفاصيل: $e');
    } finally {
      setState(() => _busy = false);
    }
  }



  bw.Barcode _getBarcodeType() {
    switch (_barcodeFormat) {
      case 'EAN13': return bw.Barcode.ean13();
      case 'EAN8': return bw.Barcode.ean8();
      case 'UPC': return bw.Barcode.upcA();
      case 'ITF14': return bw.Barcode.itf14();
      default: return bw.Barcode.code128();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('QR + باركود')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'QR + باركود',
            subtitle: 'توليد QR قابل للتخصيص + باركود بعدة معايير، مع تحميل مباشر.',
          ),

          // Mode Switcher
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'qr'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _mode == 'qr' ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _mode == 'qr' ? AppTheme.primary : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
                      ),
                      child: Center(child: Text('QR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _mode == 'qr' ? Colors.white : null))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'barcode'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _mode == 'barcode' ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _mode == 'barcode' ? AppTheme.primary : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))),
                      ),
                      child: Center(child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _mode == 'barcode' ? Colors.white : null))),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('البيانات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() => _text = v),
                  controller: TextEditingController(text: _text)..selection = TextSelection.collapsed(offset: _text.length),
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'اكتب رابط أو نص...', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_mode == 'qr') ..._buildQrSettings(isDark),
          if (_mode == 'barcode') ..._buildBarcodeSettings(isDark),

          // Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const Text('المعاينة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (_mode == 'qr')
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: _qrTransparentBg ? Colors.transparent : _qrBg,
                        child: _useGradient
                            ? ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    colors: [_qrFg, _qrFgSecondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: QrImageView(
                                  data: _text.trim().isEmpty ? ' ' : _text.trim(),
                                  version: QrVersions.auto,
                                  size: _qrSize,
                                  eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: Colors.white),
                                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: _dataShape, color: Colors.white),
                                  backgroundColor: Colors.transparent,
                                  gapless: _gapless,
                                  embeddedImage: _logoFile != null ? FileImage(_logoFile!) : null,
                                  embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(50, 50)),
                                ),
                              )
                            : QrImageView(
                                data: _text.trim().isEmpty ? ' ' : _text.trim(),
                                version: QrVersions.auto,
                                size: _qrSize,
                                eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: _qrFg),
                                dataModuleStyle: QrDataModuleStyle(dataModuleShape: _dataShape, color: _qrFg),
                                backgroundColor: _qrTransparentBg ? Colors.transparent : _qrBg,
                                gapless: _gapless,
                                embeddedImage: _logoFile != null ? FileImage(_logoFile!) : null,
                                embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(50, 50)),
                              ),
                      ),
                    ),
                  if (_mode == 'barcode')
                    RepaintBoundary(
                      key: _barcodeKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: _barcodeTransparentBg ? Colors.transparent : _barcodeBg,
                        child: Builder(
                          builder: (context) {
                            final bool hasArabic = _text.contains(RegExp(r'[^\x00-\x7F]'));
                            final String trimmedText = _text.trim();
                            
                            if (hasArabic || trimmedText.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_rounded, color: AppTheme.destructive, size: 28),
                                    const SizedBox(height: 10),
                                    Text(
                                      trimmedText.isEmpty ? 'الرجاء إدخال بيانات' : 'هذا المعيار لا يدعم اللغة العربية.\nاستخدم أرقام أو حروف إنجليزية فقط.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppTheme.destructive, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return bw.BarcodeWidget(
                              barcode: _getBarcodeType(),
                              data: trimmedText,
                              width: double.infinity,
                              height: _barcodeHeight,
                              color: _barcodeLine,
                              backgroundColor: _barcodeTransparentBg ? Colors.transparent : _barcodeBg,
                              style: TextStyle(fontSize: 12, color: _barcodeLine),
                              errorBuilder: (context, error) => Container(
                                padding: const EdgeInsets.all(10),
                                child: const Text(
                                  'بيانات غير صالحة لهذا المعيار',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.destructive, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : (_mode == 'qr' ? _downloadQr : _downloadBarcode),
                    child: Text(_busy ? 'جاري...' : 'حفظ PNG'),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            StatusBanner(message: _error!, isError: true),
          if (_success != null)
            StatusBanner(
              message: _success!,
              actionLabel: _tempPath != null ? 'حفظ في الجهاز' : null,
              onAction: _tempPath != null ? _saveToDownloads : null,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ملاحظة: بعض معايير الباركود تتطلب طولًا محددًا (مثل EAN13). إذا ظهر خطأ، غيّر المعيار إلى CODE128.',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  List<Widget> _buildQrSettings(bool isDark) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حجم الكود ثابت (250px) لضمان أفضل مسح ضوئي على كافة الأجهزة.', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('تدرج لوني', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Switch(value: _useGradient, activeTrackColor: AppTheme.primary, onChanged: (v) => setState(() => _useGradient = v)),
              ],
            ),
            const Text('لون الكود (الأساسي)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildColorPicker(_qrFg, (c) => setState(() => _qrFg = c))),
                const SizedBox(width: 8),
                IconButton(onPressed: () => _pickCustomColor(_qrFg, (c) => setState(() => _qrFg = c)), icon: const Icon(Icons.colorize_rounded, color: AppTheme.primary)),
              ],
            ),
            if (_useGradient) ...[
              const SizedBox(height: 12),
              const Text('لون التدرج الثاني', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildColorPicker(_qrFgSecondary, (c) => setState(() => _qrFgSecondary = c))),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => _pickCustomColor(_qrFgSecondary, (c) => setState(() => _qrFgSecondary = c)), icon: const Icon(Icons.colorize_rounded, color: AppTheme.primary)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('نمط التصميم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _designPattern,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'traditional', child: Text('مربعات (تقليدي)')),
                DropdownMenuItem(value: 'dots', child: Text('نقاط (دائرية)')),
                DropdownMenuItem(value: 'rounded', child: Text('ناعم (Rounded)')),
                DropdownMenuItem(value: 'circular', child: Text('دائري جداً')),
                DropdownMenuItem(value: 'classy', child: Text('كلاسيكي (Classy)')),
                DropdownMenuItem(value: 'soft_classy', child: Text('كلاسيكي ناعم')),
              ],
              onChanged: (v) {
                setState(() {
                  _designPattern = v ?? 'traditional';
                  switch (_designPattern) {
                    case 'traditional':
                      _eyeShape = QrEyeShape.square;
                      _dataShape = QrDataModuleShape.square;
                      _gapless = true;
                      break;
                    case 'dots':
                      _eyeShape = QrEyeShape.square;
                      _dataShape = QrDataModuleShape.circle;
                      _gapless = true;
                      break;
                    case 'rounded':
                      _eyeShape = QrEyeShape.circle;
                      _dataShape = QrDataModuleShape.square;
                      _gapless = true;
                      break;
                    case 'circular':
                      _eyeShape = QrEyeShape.circle;
                      _dataShape = QrDataModuleShape.circle;
                      _gapless = false;
                      break;
                    case 'classy':
                      _eyeShape = QrEyeShape.square;
                      _dataShape = QrDataModuleShape.circle;
                      _gapless = false;
                      break;
                    case 'soft_classy':
                      _eyeShape = QrEyeShape.circle;
                      _dataShape = QrDataModuleShape.circle;
                      _gapless = true;
                      break;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('شعار في المنتصف (اختياري)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(_logoFile != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined, color: AppTheme.primary),
                    Text(_logoFile != null ? 'تم اختيار الشعار' : 'اختر صورة شعار (PNG)', style: const TextStyle(fontSize: 11)),
                    if (_logoFile != null) TextButton(onPressed: () => setState(() => _logoFile = null), child: const Text('حذف الشعار', style: TextStyle(color: Colors.red, fontSize: 10))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('خلفية شفافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Switch(value: _qrTransparentBg, activeTrackColor: AppTheme.primary, onChanged: (v) => setState(() => _qrTransparentBg = v)),
              ],
            ),
            if (!_qrTransparentBg) ...[
              const Text('لون الخلفية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildColorPicker(_qrBg, (c) => setState(() => _qrBg = c))),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => _pickCustomColor(_qrBg, (c) => setState(() => _qrBg = c)), icon: const Icon(Icons.colorize_rounded, color: AppTheme.primary)),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  final Map<String, String> _barcodeDescriptions = {
    'CODE128': 'الأكثر مرونة، يدعم جميع الحروف الإنجليزية والأرقام والرموز. مثالي لمعظم الاستخدامات العامة.',
    'EAN13': 'المعيار العالمي للمنتجات الاستهلاكية. يتطلب بالضبط 12 رقماً (يُضاف الرقم الـ13 تلقائياً كتحقق).',
    'EAN8': 'نسخة مصغرة من EAN13 للمنتجات ذات الحجم الصغير. يتطلب بالضبط 7 أرقام.',
    'UPC': 'يستخدم بشكل أساسي في أمريكا الشمالية للمنتجات. يتطلب 11 أو 12 رقماً.',
    'ITF14': 'يستخدم في صناديق الشحن والتوزيع الكبيرة. يتطلب 13 أو 14 رقماً.',
  };

  List<Widget> _buildBarcodeSettings(bool isDark) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المعيار', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _barcodeFormat,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'CODE128', child: Text('CODE128')),
                DropdownMenuItem(value: 'EAN13', child: Text('EAN13')),
                DropdownMenuItem(value: 'EAN8', child: Text('EAN8')),
                DropdownMenuItem(value: 'UPC', child: Text('UPC')),
                DropdownMenuItem(value: 'ITF14', child: Text('ITF14')),
              ],
              onChanged: (v) => setState(() => _barcodeFormat = v ?? 'CODE128'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _barcodeDescriptions[_barcodeFormat] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('ارتفاع الباركود ثابت لضمان الوضوح.', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('لون الباركود', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildColorPicker(_barcodeLine, (c) => setState(() => _barcodeLine = c)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('خلفية شفافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Switch(value: _barcodeTransparentBg, activeTrackColor: AppTheme.primary, onChanged: (v) => setState(() => _barcodeTransparentBg = v)),
              ],
            ),
            if (!_barcodeTransparentBg) ...[
              const Text('لون الخلفية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _buildColorPicker(_barcodeBg, (c) => setState(() => _barcodeBg = c)),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildColorPicker(Color selected, Function(Color) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((c) {
        final color = c['color'] as Color;
        final isSelected = selected.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade600,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }
}
