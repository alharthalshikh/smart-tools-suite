import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  Map<String, dynamic> _deviceData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
  }

  Future<void> _initDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceData = {
          'المتصفح': webInfo.browserName.name,
          'النظام الأساسي': webInfo.platform,
          'إصدار المتصفح': webInfo.appVersion,
          'اللغة': webInfo.language,
          'User Agent': webInfo.userAgent,
        };
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          deviceData = {
            'الموديل': androidInfo.model,
            'الشركة المصنعة': androidInfo.manufacturer,
            'إصدار أندرويد': androidInfo.version.release,
            'مستوى SDK': androidInfo.version.sdkInt.toString(),
            'المعالج (Hardware)': androidInfo.hardware,
            'العلامة التجارية': androidInfo.brand,
            'رقم الـ Build': androidInfo.display,
          };
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfoPlugin.iosInfo;
          deviceData = {
            'الاسم': iosInfo.name,
            'الموديل': iosInfo.model,
            'إصدار النظام': iosInfo.systemVersion,
            'الجهاز': iosInfo.utsname.machine,
            'إصدار الـ Kernel': iosInfo.utsname.release,
          };
        }
      }
    } catch (e) {
      deviceData = {'خطأ': 'فشل الحصول على معلومات الجهاز'};
    }

    if (!mounted) return;
    setState(() {
      _deviceData = deviceData;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الجهاز')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                GradientHeroSection(
                  title: 'معلومات النظام',
                  subtitle: 'تفاصيل دقيقة عن العتاد والبرمجيات الخاصة بجهازك الحالية.',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _deviceData.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value.toString(),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'هذه المعلومات تُقرأ محلياً فقط ولا يتم مشاركتها أبداً.',
                            style: TextStyle(fontSize: 11, height: 1.5),
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
