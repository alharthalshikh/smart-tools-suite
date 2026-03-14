import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        children: [
          GradientHeroSection(
            title: 'حول أدوات ذكية',
            subtitle: 'قصتنا بدأت من فكرة بسيطة: لماذا نحتاج لرفع ملفاتنا الحساسة لسيرفرات غريبة لكي نقوم بعمليات بسيطة؟',
          ),

          // Why Different Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('لماذا نحن مختلفون؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'معظم التطبيقات التي تقدم أدوات PDF أو معالجة الصور تقوم برفع ملفاتك إلى خوادمها. هذا لا يعني فقط بطء في العمل، بل يمثل خطراً على خصوصيتك.\n\nفي أدوات ذكية، قمنا ببناء كل شيء ليعمل مباشرة على جهازك.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Feature Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _featureCard('🔒', 'خصوصية 100%', 'ملفاتك لا تغادر جهازك أبداً. المعالجة تتم باستخدام قوة معالج جهازك أنت.', isDark),
                _featureCard('⚡', 'سرعة فائقة', 'لا داعي لانتظار رفع الملفات الكبيرة. العمليات فورية وتعتمد على سرعة جهازك.', isDark),
                _featureCard('💰', 'مجاني بالكامل', 'نؤمن بأن الأدوات الأساسية يجب أن تكون متاحة للجميع بدون قيود.', isDark),
                _featureCard('🌍', 'دعم عربي كامل', 'واجهة مصممة خصيصاً للمستخدم العربي، مع مراعاة تفاصيل اللغة.', isDark),
              ],
            ),
          ),

          // Developer Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    'هل أنت مطور؟',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هذا التطبيق مبني باستخدام Flutter وتقنيات معالجة البيانات المحلية.\nهدفنا هو إثبات أن تقنيات الجوال الحديثة قادرة على القيام بمهام معقدة دون الحاجة لتهديد خصوصية المستخدمين.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ).createShader(bounds),
                  child: const Text(
                    'أدوات ذكية | Smart Tools',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© ${2026} - جميع الحقوق محفوظة',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.black26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _featureCard(String emoji, String title, String desc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 11, height: 1.6, color: isDark ? Colors.white38 : Colors.black45),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
