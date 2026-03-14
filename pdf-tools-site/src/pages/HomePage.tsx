import { Link } from "react-router-dom";

const cards = [
  {
    title: "حذف الخلفية AI",
    desc: "إزالة خلفية الصور بالذكاء الاصطناعي بدقة عالية",
    to: "/bg-remover",
    icon: "👤",
  },
  {
    title: "اختبار السرعة",
    desc: "قياس سرعة التحميل والرفع لشبكتك الحالية",
    to: "/speedtest",
    icon: "⚡",
  },
  {
    title: "معلومات الجهاز",
    desc: "تفاصيل المعالج والذاكرة والنظام بالتفصيل",
    to: "/device-info",
    icon: "ℹ️",
  },
  {
    title: "QR + باركود",
    desc: "توليد QR قابل للتخصيص + باركود بأكثر من معيار",
    to: "/qr",
    icon: "⌁",
  },
  {
    title: "أدوات PDF",
    desc: "دمج/تقسيم/تدوير/حذف صفحات/علامة مائية",
    to: "/pdf",
    icon: "⧉",
  },
  {
    title: "تحويل الصور",
    desc: "تحويل JPG/PNG/WebP بجودة عالية مباشرة",
    to: "/images",
    icon: "🖼",
  },
  {
    title: "تحسين السوشيال",
    desc: "مقاسات جاهزة + ضغط ذكي للمنصات",
    to: "/optimize",
    icon: "✦",
  },
  {
    title: "أدوات الصوت",
    desc: "قص الملفات الصوتية وتسجيل الصوت محلياً",
    to: "/audio-tools",
    icon: "✂️",
  },
  {
    title: "مستخرج الألوان",
    desc: "استخراج لوحة الألوان من أي صورة فوراً",
    to: "/color-picker",
    icon: "🎨",
  },
  {
    title: "ماسح المستندات",
    desc: "تصوير الأوراق وتحويلها إلى PDF بجودة عالية",
    to: "/scanner",
    icon: "📄",
  },
];

export function HomePage() {
  return (
    <main>
      <section className="gradient-hero border-b">
        <div className="container py-14">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div className="animate-slide-up">
              <h1 className="text-3xl font-extrabold leading-tight sm:text-4xl">
                كل أدواتك
                <span className="text-gradient"> في مكان واحد</span>
              </h1>
              <p className="mt-4 text-sm leading-7 text-muted-foreground sm:text-base">
                QR + باركود، أدوات PDF، تحويل الصور، وتحسين الصور للسوشيال — وكلها تعمل داخل المتصفح للحفاظ على الخصوصية.
              </p>
              <div className="mt-6 flex flex-col gap-3 sm:flex-row">
                <Link
                  to="/pdf"
                  className="rounded-xl bg-primary px-5 py-3 text-sm font-extrabold text-primary-foreground shadow-md transition hover:opacity-95"
                >
                  جرّب أدوات PDF
                </Link>
                <Link
                  to="/qr"
                  className="rounded-xl border border-border bg-card/70 px-5 py-3 text-sm font-extrabold shadow-sm transition hover:bg-card"
                >
                  توليد QR + باركود
                </Link>
              </div>
            </div>

            <div className="animate-fade-in">
              <div className="gradient-card rounded-3xl border border-border p-6 shadow-lg">
                <div className="text-sm font-extrabold">أدوات سريعة</div>
                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                  {cards.map((c) => (
                    <Link
                      key={c.to}
                      to={c.to}
                      className="group rounded-2xl border border-border bg-card/80 p-4 text-right shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                          <span className="text-lg">{c.icon}</span>
                        </div>
                        <div>
                          <div className="text-sm font-extrabold">{c.title}</div>
                          <div className="mt-1 text-xs text-muted-foreground">{c.desc}</div>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="py-10">
        <div className="container">
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {cards.map((c) => (
              <Link
                key={c.to}
                to={c.to}
                className="rounded-3xl border border-border bg-card/80 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
              >
                <div className="text-xl">{c.icon}</div>
                <div className="mt-3 text-base font-extrabold">{c.title}</div>
                <div className="mt-2 text-sm text-muted-foreground">{c.desc}</div>
              </Link>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
