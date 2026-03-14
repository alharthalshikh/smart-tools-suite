import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  File? _imageFile;
  Color? _dominantColor;
  List<Color> _palette = [];
  bool _loading = false;

  String? _toastMsg;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _dominantColor = null;
      _palette = [];
      _loading = true;
    });

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        FileImage(_imageFile!),
        maximumColorCount: 10,
      );

      setState(() {
        _dominantColor = generator.dominantColor?.color;
        _palette = generator.paletteColors.map((p) => p.color).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  String _colorToRgb(Color c) {
    return 'rgb(${(c.r * 255).round() & 0xff},${(c.g * 255).round() & 0xff},${(c.b * 255).round() & 0xff})';
  }

  Future<void> _copyColor(Color color) async {
    final hex = _colorToHex(color);
    final rgb = _colorToRgb(color);
    final text = '$hex | $rgb';
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _toastMsg = 'تم نسخ $hex و $rgb بنجاح ✓');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('مستخرج الألوان')),
      body: Stack(
        children: [
          ListView(
            children: [
              GradientHeroSection(
                title: 'مستخرج الألوان الذكي',
                subtitle: 'ارفع صورة واستخرج لوحة الألوان المستخدمة فيها فوراً.',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickImage,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_rounded, size: 40, color: AppTheme.primary.withValues(alpha: 0.5)),
                                    const SizedBox(height: 8),
                                    Text('اختر صورة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickImage,
                      child: const Text('تغيير الصورة'),
                    ),
                  ),
                ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),

              // Dominant Color
              if (_dominantColor != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('اللون السائد:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _copyColor(_dominantColor!),
                        child: Container(
                          height: 70,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _dominantColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                          ),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_colorToRgb(_dominantColor!)} | ${_colorToHex(_dominantColor!)}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Palette
              if (_palette.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لوحة الألوان (Palette):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _palette.length,
                        itemBuilder: (context, index) {
                          final color = _palette[index];
                          return GestureDetector(
                            onTap: () => _copyColor(color),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          'نصيحة: اضغط على أي لون لنسخ كود الـ RGB و HEX الخاص به.',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),

          // Toast
          if (_toastMsg != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.check, size: 14, color: AppTheme.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _toastMsg!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
