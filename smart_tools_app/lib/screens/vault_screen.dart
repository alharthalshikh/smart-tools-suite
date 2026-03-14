import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isAuthenticated = false;
  bool _useBiometrics = false;
  String? _savedPin;
  List<Map<String, dynamic>> _lockedFiles = [];
  Database? _db;

  @override
  void initState() {
    super.initState();
    _initVault();
  }

  Future<void> _initVault() async {
    // 1. Load Settings
    final prefs = await SharedPreferences.getInstance();
    _savedPin = prefs.getString('vault_pin');
    _useBiometrics = prefs.getBool('use_biometrics') ?? false;

    // 2. Init Database
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'vault.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE files(id INTEGER PRIMARY KEY, name TEXT, path TEXT, date TEXT)',
        );
      },
      version: 1,
    );

    _loadFiles();

    if (_useBiometrics && !kIsWeb && _savedPin != null) {
      _authenticateWithBiometrics();
    }
    setState(() {});
  }

  Future<void> _loadFiles() async {
    final List<Map<String, dynamic>> maps = await _db!.query('files');
    setState(() {
      _lockedFiles = maps;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'فتح المجلد السري',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (didAuthenticate) {
        setState(() => _isAuthenticated = true);
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
    }
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final originalFile = File(result.files.single.path!);
    final fileName = result.files.single.name;

    // Show Copy/Move Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ملف'),
        content: const Text('هل تريد نسخ الملف أم نقله للمجلد السري؟ (النقل سيقوم بحذف الأصل)'),
        actions: [
          TextButton(
            onPressed: () => _processFile(originalFile, fileName, false),
            child: const Text('نسخ'),
          ),
          ElevatedButton(
            onPressed: () => _processFile(originalFile, fileName, true),
            child: const Text('نقل'),
          ),
        ],
      ),
    );
  }

  Future<void> _processFile(File original, String name, bool move) async {
    Navigator.pop(context); // Close dialog
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDir.path, 'vault_files'));
      if (!await vaultDir.exists()) await vaultDir.create();

      final newPath = p.join(vaultDir.path, '${DateTime.now().millisecondsSinceEpoch}_$name');
      
      // Copy the file to our permanent storage using Dart's robust read/write to avoid file system locks
      final bytes = await original.readAsBytes();
      final newFile = File(newPath);
      await newFile.writeAsBytes(bytes);
      
      if (move) {
        await original.delete(); // Delete original if move
      }

      // Save to DB
      await _db!.insert('files', {
        'name': name,
        'path': newPath,
        'date': DateTime.now().toString(),
      });

      _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(move ? 'تم نقل الملف بنجاح' : 'تم نسخ الملف بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء نقل الملف.')),
        );
      }
    }
  }

  Future<void> _deleteFile(int id, String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    await _db!.delete('files', where: 'id = ?', whereArgs: [id]);
    _loadFiles();
  }

  Future<void> _openFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      final uri = Uri.file(path);
      try {
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح هذا النوع من الملفات مباشرة')),
          );
        }
      }
    }
  }

  Future<void> _restoreFile(BuildContext context, int id, String name, String path) async {
    final sourceFile = File(path);
    if (!await sourceFile.exists()) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عفواً الملف غير موجود داخل الخزنة!')),
       );
       return;
    }

    try {
      // In Android 11+ (Scoped Storage), FilePicker.saveFile is the most reliable way to write outside
      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'استرجاع الملف وحفظه كـ',
        fileName: name,
      );

      if (savePath != null) {
        // Read from source, write to destination (more reliable than copy() across volumes)
        final bytes = await sourceFile.readAsBytes();
        final destFile = File(savePath);
        await destFile.writeAsBytes(bytes);
        
        await _deleteFile(id, path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استرجاع الملف بنجاح!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الاسترجاع (قد يكون بسبب الصلاحيات)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [UI remains similar but with updated logic for listing files and PIN/Settings]
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('دخول آمن')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.lock_person_rounded, size: 80, color: AppTheme.primary),
                const SizedBox(height: 20),
                Text(_savedPin == null ? 'إنشاء رمز قفل للمجلد' : 'أدخل رمز القفل'),
                const SizedBox(height: 30),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: '****', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_savedPin == null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vault_pin', _pinController.text);
                        setState(() { _savedPin = _pinController.text; _isAuthenticated = true; });
                      } else if (_pinController.text == _savedPin) {
                        setState(() => _isAuthenticated = true);
                      }
                      _pinController.clear();
                    },
                    child: Text(_savedPin == null ? 'تعيين الرمز' : 'دخول'),
                  ),
                ),
                if (_savedPin != null && _useBiometrics)
                  TextButton.icon(onPressed: _authenticateWithBiometrics, icon: const Icon(Icons.fingerprint), label: const Text('استخدام البصمة')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المجلد السري'), actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => setState(() => _isAuthenticated = false))]),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const GradientHeroSection(title: 'خزنة الملفات', subtitle: 'قاعدة بيانات محلية آمنة لحماية مستنداتك.'),
            _buildSettings(),
            if (_lockedFiles.isEmpty)
              const Padding(padding: EdgeInsets.all(50), child: Text('المجلد فارغ، أضف ملفاتك السرية', style: TextStyle(color: Colors.grey)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _lockedFiles.length,
                itemBuilder: (context, index) {
                  final file = _lockedFiles[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      onTap: () => _openFile(file['path']),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_rounded, color: AppTheme.primary),
                      ),
                      title: Text(
                        file['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        file['date'].toString().split(' ').first,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_page_rounded, color: Colors.green),
                            tooltip: 'استرجاع الملف خارج الخزنة',
                            onPressed: () => _restoreFile(context, file['id'], file['name'], file['path']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'حذف نهائي',
                            onPressed: () => _deleteFile(file['id'], file['path']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: _addFile, icon: const Icon(Icons.add_to_photos_rounded), label: const Text('إضافة ملف سري'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: const Text('تفعيل الدخول بالبصمة', style: TextStyle(fontWeight: FontWeight.bold)),
        value: _useBiometrics,
        onChanged: (val) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('use_biometrics', val);
          setState(() => _useBiometrics = val);
        },
      ),
    );
  }
}
