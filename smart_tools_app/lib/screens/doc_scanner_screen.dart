import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DocScannerScreen extends StatefulWidget {
  const DocScannerScreen({super.key});

  @override
  State<DocScannerScreen> createState() => _DocScannerScreenState();
}

class _DocScannerScreenState extends State<DocScannerScreen> {
  DocumentScanner? _scanner;
  List<String> _scannedImages = [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
          isGalleryImport: true,
          pageLimit: 10,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanner?.close();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (kIsWeb || _scanner == null) return;

    try {
      final result = await _scanner!.scanDocument();
      setState(() {
        _scannedImages.addAll(result.images);
      });
    } catch (e) {
      // Don't show error if user cancelled the scan
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        debugPrint('User cancelled the scan');
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء المسح: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ماسح المستندات')),
      body: Column(
        children: [
          GradientHeroSection(
            title: 'ماسح المستندات الذكي',
            subtitle: 'قم بتحويل الأوراق والمستندات لصور رقمية واضحة ومقصوصة بدقة.',
          ),
          if (kIsWeb)
            const StatusBanner(
              message: 'هذه الميزة مدعومة حالياً على تطبيقات الجوال فقط.',
              isError: true,
            ),
          Expanded(
            child: _scannedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('ابدأ بمسح أول ورقة الآن', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scannedImages.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Image.network(_scannedImages[index]), // File path as URL
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => setState(() => _scannedImages.removeAt(index)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: kIsWeb ? null : _startScan,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('بدء المسح الضوئي'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
