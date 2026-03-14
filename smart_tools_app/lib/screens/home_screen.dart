import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _launchContactURL() async {
    final Uri url = Uri.parse('https://my-profile-ecru.vercel.app/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Just log for now if fails
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    const String shareText = 'جرّب تطبيق أدواتي 🛠️ — أدوات PDF، QR، تحويل صور وصوت وأكثر!\nكلها تعمل محلياً على جهازك.\n\nحمّل التطبيق الآن!';
    await Clipboard.setData(const ClipboardData(text: shareText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('تم نسخ رابط المشاركة! الصقه في أي محادثة')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static const List<Map<String, dynamic>> tools = [
    {
      'title': 'حذف الخلفية',
      'desc': 'إزالة خلفية الصور بالذكاء الاصطناعي بدقة عالية',
      'route': '/bg-remover',
      'icon': Icons.person_remove_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'ماسح المستندات',
      'desc': 'تصوير وقص الأوراق والمستندات باحترافية',
      'route': '/scanner',
      'icon': Icons.document_scanner_rounded,
      'color': Color(0xFF0EA5E9),
    },
    {
      'title': 'المجلد السري',
      'desc': 'تأمين ملفاتك برمز سري أو بصمة الإصبع',
      'route': '/vault',
      'icon': Icons.security_rounded,
      'color': Color(0xFFF43F5E),
    },
    {
      'title': 'اختبار السرعة',
      'desc': 'قياس سرعة التحميل والرفع لشبكتك الحالية',
      'route': '/speedtest',
      'icon': Icons.speed_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'أدوات PDF',
      'desc': 'دمج/تقسيم/تدوير/حذف صفحات/علامة مائية',
      'route': '/pdf',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'QR + باركود',
      'desc': 'توليد QR قابل للتخصيص + باركود بأكثر من معيار',
      'route': '/qr',
      'icon': Icons.qr_code_2_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'تحويل الصور',
      'desc': 'تحويل JPG/PNG/WebP بجودة عالية مباشرة',
      'route': '/images',
      'icon': Icons.image_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'أدوات الصوت',
      'desc': 'قص الملفات الصوتية وتسجيل الصوت محلياً',
      'route': '/audio-tools',
      'icon': Icons.mic_rounded,
      'color': Color(0xFF0F6D7A),
    },
    {
      'title': 'معلومات الجهاز',
      'desc': 'تفاصيل المعالج والذاكرة والنظام بالتفصيل',
      'route': '/device-info',
      'icon': Icons.info_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'مستخرج الألوان',
      'desc': 'استخراج لوحة الألوان من أي صورة فوراً',
      'route': '/color-picker',
      'icon': Icons.palette_rounded,
      'color': Color(0xFFDB2777),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, isDark, themeProvider),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            centerTitle: false,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0A1628), const Color(0xFF0A0F1A)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      children: const [
                        TextSpan(text: 'كل أدواتك '),
                        TextSpan(
                          text: 'في مكان واحد',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'أدوات PDF، QR + باركود، تحويل الصور، وأكثر — وكلها تعمل محلياً على جهازك للحفاظ على الخصوصية.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/pdf'),
                        child: const Text('جرّب أدوات PDF'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/qr'),
                        child: const Text('QR + باركود'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 
                  ? 4 // Wide screen (Web)
                  : MediaQuery.of(context).size.width > 600 ? 3 : 2, // Tablet or Phone
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = tools[index];
                  return _ToolCard(
                    title: tool['title'],
                    desc: tool['desc'],
                    icon: tool['icon'],
                    color: tool['color'],
                    onTap: () => Navigator.pushNamed(context, tool['route']),
                  );
                },
                childCount: tools.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, ThemeProvider themeProvider) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primaryLight.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/launcher_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'أدواتي',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أدوات ذكية بين يديك',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu Items
            _DrawerItem(
              icon: Icons.share_rounded,
              label: 'مشاركة التطبيق',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                _shareApp(context);
              },
            ),

            _DrawerItem(
              icon: Icons.person_rounded,
              label: 'تواصل معي',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.pop(context);
                _launchContactURL();
              },
            ),

            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'حول التطبيق',
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ثيم التطبيق',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('فاتح', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('داكن', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('تلقائي', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      themeProvider.setThemeMode(newSelection.first);
                    },
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.security_rounded, color: AppTheme.primary, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'جميع الأدوات تعمل محلياً\nبياناتك لا تغادر جهازك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
        hoverColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black45,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
