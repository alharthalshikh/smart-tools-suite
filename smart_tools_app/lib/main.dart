import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_tools_screen.dart';
import 'screens/qr_barcode_screen.dart';
import 'screens/image_converter_screen.dart';
import 'screens/optimizer_screen.dart';
import 'screens/video_converter_screen.dart';
import 'screens/audio_tools_screen.dart';
import 'screens/color_picker_screen.dart';
import 'screens/about_screen.dart';
import 'screens/splash_screen.dart';

import 'screens/device_info_screen.dart';
import 'screens/speed_test_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/bg_remover_screen.dart';
import 'screens/doc_scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartToolsApp(),
    ),
  );
}

class SmartToolsApp extends StatelessWidget {
  const SmartToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'أدواتي',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/pdf': (context) => const PdfToolsScreen(),
        '/qr': (context) => const QrBarcodeScreen(),
        '/images': (context) => const ImageConverterScreen(),
        '/optimize': (context) => const OptimizerScreen(),
        '/video-to-audio': (context) => const VideoConverterScreen(),
        '/audio-tools': (context) => const AudioToolsScreen(),
        '/color-picker': (context) => const ColorPickerScreen(),
        '/device-info': (context) => const DeviceInfoScreen(),
        '/speedtest': (context) => const SpeedTestScreen(),
        '/vault': (context) => const VaultScreen(),
        '/bg-remover': (context) => const BgRemoverScreen(),
        '/scanner': (context) => const DocScannerScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
